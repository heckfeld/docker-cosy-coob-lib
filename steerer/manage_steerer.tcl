# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/manage_steerer.tcl,v 1.2 2012/01/25 10:04:52 tine Exp $
itcl_class manage_steerer_class {
  inherit manage_class

  constructor {} {
    global exp_fehl expok wait release_all drucker TMPDIR

    set drucker ljg
    set TMPDIR /tmp
    set exp_fehl 0
    set expok 1
    set wait($this) 0
    set pocolist [lsort [itcl_info objects -isa dps_class]]
    set cratelist [lsort [itcl_info objects -isa crate_class]]
    set release_all 1
  }

  destructor {}


  method busy_release {} {
    global release_all NAME

    if {$release_all} {
      set children [lsort [blt_busy hosts]]

      foreach elem $children {
        if {[string length $elem] && [winfo exists $elem]} {
          catch {blt_busy release $elem}
        }
      }

      set is_busy 0
    } else {
      if {[winfo exists .modellcorrector]} {
        blt_busy release .modellcorrector
      }

      if {[winfo exists .tim]} {
        blt_busy release .tim
      }

      foreach elem [itcl_info objects -isa trxview_class] {
        blt_busy release .$elem
      }

      if {[winfo exists .group]} {
        blt_busy release .group
        blt_busy hold .group.menu.file
        blt_busy hold .group.menu.group
        blt_busy hold .group.menu.inkrement
        blt_busy hold .group.menu.modell
        blt_busy hold .group.menu.spec_functions

        if {[string first steer $NAME] != -1} {
          blt_busy hold .group.menu.theorie
        }

        blt_busy hold .group.row0a
        blt_busy hold .group.row[group get_zeilen].graphbox

        # Alle Startup-Buttons freigeben
        foreach elem [lsort [itcl_info objects -isa member_class]] {
          set frame [$elem get_box]
          blt_busy release $frame
          blt_busy hold $frame.row1
          blt_busy hold $frame.row4a
          blt_busy hold $frame.row5
          blt_busy hold $frame.row7
        }
      }
    }
  }


  method nach_boot {target} {
    # alle Magnete die bisher connected waren neu connecten
    foreach elem $magnetlist {
      if {[$elem get_isconnected] == 1} {
        $elem set_isconnected 0
        $elem connect
      }
    }
  }


  method set_pos {view xval yval} {
    set x($view) $xval
    set y($view) $yval
  }

  method pos_exists {view} {
    if {[info exists x($view)] && [info exists y($view)]} {
      return 1
    } else {
      return 0
    }
  }

  method get_xpos {view} {
    return $x($view)
  }

  method get_ypos {view} {
    return $y($view)
  }


  method update_data {text} {
    set magnet [lindex $text 0]
    set index [string first \) $magnet]
    set magnet [string range $magnet [expr $index + 1] end]
    set info [lindex [split $text '] 1]

    ##### Tine: bw08 gibt es nicht !!!
    ##### 09.12.08
    $magnet set_dogetinfo 1
    $magnet eval_info $info
  }


  method save_file {{name ""} args} {
    global BACKUPNAME FGENDIR BITMAPDIR TITLE max_exp

    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Abspeichern $name $args"

    # falls in args keine Experimentliste uebergeben wurde, werden alle
    # Experimente abgespeichert
    if {![llength $args]} {
      set savelist ""

      for {set i 1} {$i <= $max_exp} {incr i} {
        append savelist $i
      }
    } else {
      set savelist [lindex $args 0]
    }

    if {[file exists "$name"] != 1 } {
       mkdir -path $name
    } elseif {[file isdirectory "$name"] != 1} {
       tk_dialog .dia "$TITLE" "Speichern: $name ist kein Verzeichnis" \
                 @$BITMAPDIR/smily.xpm 0 OK
    }

    # zuletzt geladene Fgenfiles kopieren
    set rc [catch {glob $FGENDIR/*.startup} files]

    if {!$rc} {
      foreach elem [lsort $files] {
        set neuname [file root [file tail $elem]]
        set poco [file root $neuname]

        # Falls poco zur Oberflaeche gehoert
        if {[lsearch $pocolist $poco] != -1} {
          set rc [catch {exec cp $elem $name/$neuname} ret_string]

          if {$rc} {
             tk_dialog .dia "$TITLE" "Speichern: $ret_string" \
                       @$BITMAPDIR/smily.xpm 0 OK
          }
        }
      }
    }

    set fout [open "$name/$BACKUPNAME" "w"]

    master save_object $fout $savelist

    close $fout
    return OK
  }


  method restore_file {{name ""}} {
    global BACKUPDIR BACKUPNAME BITMAPDIR FGENDIR TITLE max_exp edit_exp akt_exp

    if {![file exists "$name/$BACKUPNAME"]} {
       tk_dialog .dia "$TITLE" "Die Datei $name/$BACKUPNAME existiert nicht" \
                 @$BITMAPDIR/smily.xpm 0 OK
       return
    }

    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Abspeicherung laden: $name"

    # Bestimmen von savelist
    set savelist ""

    if {[catch {exec grep "orbit set_begin" "$name/$BACKUPNAME"} ret_string]} {
      for {set i 1} {$i <= $max_exp} {incr i} {
        append savelist $i
      }
    } else {
      foreach line [split $ret_string "\n"] {
        append savelist [lindex $line 2]
      }
    }

#    # Fgenfiles kopieren
#    set cpfiles {}
#    set rc [catch {glob $name/*.fgen?} files]
#
#    if {!$rc} {
#      foreach elem $files {
#        # Falls Fgenfile zur Oberflaeche gehoert
#        set magnet [file root [file tail $elem]]
#        if {[lsearch $pocolist $magnet] != -1} {
#          set rc [catch {exec cp $elem $FGENDIR} ret_string]
#          lappend cpfiles $elem
#        }
#      }
#    }
#
#    if {![llength $cpfiles]} {
#      tk_dialog .dia "$TITLE" "Keine Fgenfiles vorhanden! Bitte neu \
#                rechnen!" @$BITMAPDIR/smily.xpm 0 OK
#    }
#
#    # aktpunkt auf 0 setzen
#    foreach elem $pocolist {
#      for {set i 1} {$i <= $max_exp} {incr i} {
#        $elem set_aktpunkt $i 0
#        $elem set_tgesamt $i
#        $elem cmp_fgen $i
#      }
#    }

    set save_editexp $edit_exp

    # TimsRxList-Eintraege loeschen
    database remove_all

    # Orbit_Einzel-Zeilen loeschen
    foreach num [split $savelist {}] {
      foreach elem $pocolist {
        database clear_einzel_time $elem $num
      }
    }

    # Ueberpruefen, ob edit_exp im Bakfile gesetzt wird, andernfalls edit_exp
    # auf akt_exp aus Bakfile setzen
    if {[catch {exec grep edit_exp "$name/$BACKUPNAME"} ret_string]} {
      set line [exec grep "set akt_exp" "$name/$BACKUPNAME"]
      set val [lindex $line 4]
      set edit_exp $val
    }

    # current in Einzelviews zuruecksetzen
    foreach elem [itcl_info objects -isa orbit_einzel_class] {
      set cur [$elem get_current]

      if {$cur} {
        $elem set_current $cur
      }
    }

    # Einzelviews entfernen
    foreach elem [itcl_info objects -isa dpsview_class] {
      if {[winfo exists .$elem]} {
        destroy .$elem
      }
    }

    set fin [open "$name/$BACKUPNAME" "r"]
    gets $fin command

    while {![eof $fin]} {
      set rc [catch {eval $command} ret_string]

      if {$rc} {
        tk_dialog .dia "$TITLE" $ret_string @$BITMAPDIR/smily.xpm 0 OK
      }

      gets $fin command
    }

    close $fin

    manage busy_hold

    foreach elem [tim get_timerecords] {
      database set_record $elem [tim get_event_type $elem] [tim get_event_adr \
               $elem] [tim get_event_val $elem]
    }

    if {[winfo exists .tim]} {
      destroy .tim
      tim restore_init
    }

    database set_akt_exp $akt_exp
    group set_old_editexp $save_editexp
    group set_edit_exp 0

    # Fgenfiles neu rechnen
    for {set i 1} {$i <= $max_exp} {incr i} {
      # falls i in savelist
      if {[string first $i $savelist] != -1} {
        foreach elem $pocolist {
          $elem rech_fgen $i
        }
      }
    }

    # Falls edit_exp in savelist
    if {[string first $edit_exp $savelist] != -1} {
      # show_graph fuer alle Graphen
      foreach elem [itcl_info objects -isa graphic_class] {
        $elem show_graph
      }
    }

#    # aktpunkt auf 0 setzen
#    foreach elem $pocolist {
#      for {set i 1} {$i <= $max_exp} {incr i} {
#        $elem set_aktpunkt $i 0
#        $elem set_tgesamt $i
#        $elem cmp_fgen $i
#      }
#    }

    foreach elem $cratelist {
      set rlist [$elem get_rampmagnete]

      if {[llength $rlist]} {
        $elem startup123 $rlist
      }
    }

    # Falls sich alter edit_exp und neuer edit_exp unterscheiden
    if {[string compare $edit_exp $save_editexp]} {
      database set_edit_exp $edit_exp

      # Werte uebernehmen anpassen
      group uebernehmen_anpassen

      # Fgen-Editoren
      foreach elem [itcl_info objects -isa orbit_einzel_class] {
        $elem update_orbit_einzel
      }

      # Member
      foreach elem [itcl_info objects -isa member_class] {
        $elem update_startup
      }

      # Sollstroeme und Topstrome
      foreach elem [group get_magnetegroup] {
        $elem set_edit_exp
      }
    }

    group set_old_editexp $edit_exp
    manage busy_release
    return OK
  }


  method restore_exp {name from to} {
    global BACKUPDIR BACKUPNAME BITMAPDIR FGENDIR TITLE

    if {![file exists "$name/$BACKUPNAME"]} {
       tk_dialog .dia "$TITLE" "Die Datei $name/$BACKUPNAME existiert nicht" \
                 @$BITMAPDIR/smily.xpm 0 OK
    }

    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Abspeicherung laden: Experiment $from nach $to \
                 Verzeichnis: $name"

    # Fgenfiles kopieren
    set cpfiles {}
    set rc [catch {glob $name/*.fgen$from} files]

    if {!$rc} {
      foreach elem $files {
        # Falls Fgenfile zur Oberflaeche gehoert
        set magnet [file root [file tail $elem]]
        if {[lsearch $pocolist $magnet] != -1} {
          set rc [catch {exec cp $elem $FGENDIR/$magnet.fgen$to} ret_string]
          lappend cpfiles $elem
        }
      }
    }

    if {![llength $cpfiles]} {
      tk_dialog .dia "$TITLE" "Keine Fgenfiles vorhanden! Bitte neu \
                rechnen!" @$BITMAPDIR/smily.xpm 0 OK
    }

    # aktpunkt auf 0 setzen, tgesamt setzen
    foreach elem $pocolist {
      $elem set_aktpunkt $to 0
      $elem set_tgesamt $to
      $elem cmp_fgen $to
    }

    bak2exp $name/$BACKUPNAME $from $to
    return OK
  }


  method bak2exp {file from to} {
    global akt_exp edit_exp soll top BITMAPDIR TITLE

    manage busy_hold

    foreach elem $cratelist {
      $elem connect
      $elem get_info
    }

    set rc [catch {exec grep -e "set_rfgentyp $from" \
            -e "set_beulenscale $from" -e "set_wedelscale $from" \
            -e "graphwaehl $from" -e "set_sollval $from" -e "set_topval $from" \
            -e "set_begin $from" -e "set_up $from" -e "set_top $from" \
            -e "set_down $from" -e "set_end $from" -e "set_topstrom $from" \
            -e "set_exist $from" -e "beule set_bbegin $from" \
            -e "beule set_bup $from" -e "beule set_btop $from" \
            -e "beule set_bdown $from" -e "wedel set_wbegin $from" \
            -e "wedel set_wup1 $from" -e "wedel set_wtop $from" \
            -e "wedel set_wdown $from" -e "wedel set_wntop $from" \
            -e "wedel set_wup2 $from" -e "set_listsel $from" \
            -e "set_timeval $from" -e "set_zeilenmax $from" $file} ret_string]

    if {$rc} {
      ### grep: 0 ok, selected lines found, 1 otherwise, 2 error !!!
      ### Moeglicherweise ist Experiment $from gar nicht abgespeichert !!!
      tk_dialog .dia "$TITLE" "Experimentweises Laden:\
                $ret_string\nMoeglicherweise ist Experiment $from\
                gar nicht abgespeichert !!!" \
                @$BITMAPDIR/smily.xpm 0 OK
      manage busy_release
      return
    }

    foreach line [split $ret_string "\n"] {
      if {[string first set_sollval $line] != -1} {
        eval [lreplace $line 2 2 $to]
        set magnet [lindex $line 0]
        set val [lindex $line 3]

        # falls edit_exp und to uebereinstimmen globalen Sollwert setzen
        if {$edit_exp == $to} {
          set soll($magnet) $val
        }

        $magnet set_sollval $to $val

        # falls akt_exp und to uebereinstimmen und Geraet im DC-Mode, Sollwert \
        # setzen
        if {$akt_exp == $to} {
          set crate [$magnet get_crate]
          if {[string length $crate]} { 
            $crate send_soll $magnet $val
          }
        }
      } elseif {[string first set_topval $line] != -1} {
        eval [lreplace $line 2 2 $to]
        set magnet [lindex $line 0]
        set val [lindex $line 3]

        # falls edit_exp und to uebereinstimmen globalen Topwert setzen
        if {$edit_exp == $to} {
          set top($magnet) $val
        }

        $magnet set_topval $to $val
      } elseif {[string first set_exist $line] != -1} {
        eval [lreplace $line 2 2 $to]
        set exist([lindex $line 0]) [lindex $line 3]
      } elseif {[string first set_zeilenmax $line] != -1} {
        eval [lreplace $line 2 2 $to]
      } elseif {[string first set_timeval $line] != -1} {
        set line [lreplace $line 2 2 $to]
        set line [lreplace $line 7 7 $to]
        eval $line
      } else {
        if {([string first set_top $line] != -1) && \
              ([string first "global top" $line] != -1)} {
        } else {
          eval [lreplace $line 2 2 $to]
        }
      }
    }

    # graphsel fuer orbit, beule, falls edit_exp = to
    if {$edit_exp == $to} {
      foreach elem [itcl_info objects -isa graphic_class] {
        $elem set_graph_edit_exp $to
      }
    }

    if {[winfo exists .group]} {
      destroy .group
      group init
    }

    foreach elem [array names exist] {
      if {[winfo exists .$elem]} {
        destroy .$elem
      }

      if {$exist($elem)} {
        $elem init
      }
    }

    # einzelview
    set liste [itcl_info objects -isa dpsview_class]

    foreach elem $liste {
      set magnet [$elem get_magnet]
      $elem quit
      dpsview_class $elem -magnet $magnet
    }

    manage busy_release

  }; #bak2exp


  method del_bak {} {
    global BACKUPNAME BACKUPDIR

    if {![winfo exists .del_bak]} {
      delete_single_class dselect_del -filter "$BACKUPDIR/*/$BACKUPNAME"
      dselect_del make_dirselect .del_bak "Einzelsicherung loeschen" "virtual \
              $this del_bak_file"
    } else {
      raise.tk .del_bak
    }
  }


  method del_bak_file {args} {}


  method set_expstring {es} {
    global wait

    if {$wait($this)} {
      return BUSY
    }

    after 10 "$this do_setexpstring $es"
    return OK
  }


  method do_setexpstring {es} {
    global wait explist

    set wait($this) 1
    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Experimentstring setzen: $es"

    set explist $es
    database set_group_explist $es

    # Startup mit Experimentwechsel
    group go
    set wait($this) 0
  }


  method make_nachricht {key title text} {
    global BITMAPDIR WORKSPACE mfont

    if {[winfo exists .nachricht$key]} {
      destroy .nachricht$key
    }

    toplevel .nachricht$key
    wm title .nachricht$key $title
    wm command .nachricht$key WORKSPACE
    wm geometry .nachricht$key 700x100+400+450
    label .nachricht$key.lbit -bitmap @$BITMAPDIR/smilynice.xpm
    label .nachricht$key.ltext -text $text -font $mfont
    pack .nachricht$key.lbit .nachricht$key.ltext -side left -padx 10 -pady 10
    update
  }


  method destroy_nachricht {key} {
    if {[winfo exists .nachricht$key]} {
      destroy .nachricht$key
    }
  }


  method expok {} {
    global expok

    return $expok
  }


  method notstop {} {
    after 10 "group notstop"
    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Notstop"
    return OK
  }


  method experiment_reset {} {
    after 10 "group experiment_reset"
    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Experiment Reset"
    return OK
  }


  method is_no_expnum {val} {
    global max_exp

    if {![string length $val]} {
      return 1
    }

    set sub_string 1

    for {set i 2} {$i <= $max_exp} {incr i} {
      append sub_string |$i
    }

    regsub $sub_string $val "" out
    return [string length $out]
  }


  method is_no_expstring {val} {
    global max_exp

    if {![string length $val]} {
      return 1
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      regsub -all $i $val "" val
    }

    return [string length $val]
  }


  method is_no_boolean {val} {
    if {![string length $val]} {
      return 1
    }

    regsub {0|1} $val "" out
    return [string length $out]
  }


  method is_no_db_boolean {val} {
    if {![string length $val]} {
      return 1
    }

    regsub {t|f} $val "" out
    return [string length $out]
  }


  method is_no_fgentype {val} {
    if {![string length $val]} {
      return 1
    }

    regsub {o|b|w|e} $val "" out
    return [string length $out]
  }


  method is_no_posint {val} {
    # Zahl muss ganze positive Zahl sein
    if {[catch {expr int($val)} intval]} {
      return 1
    }

    if {$val != $intval} {
      return 1
    }

    if {$val < 1} {
      return 1
    }

    return 0
  }


  method get_bakfiles {} {
    global NAME max_exp

    set list $NAME.bak

    foreach elem $pocolist {
      for {set i 1} {$i <= $max_exp} {incr i} {
        lappend list $elem.fgen$i
      }
    }

   return $list
  }


  method aktexperiment_pruefen {} {
    global explist akt_exp edit_exp

    # Falls aktuelles Experiment nicht in explist vorkommt
    if {[string first $akt_exp $explist] == -1} {
      set exp [string index $explist 0]
      # editiertes Experiment umsetzen
      set edit_exp $exp
      group set_edit_exp

      # aktuelles Experiment umsetzen
      set akt_exp $exp
      group set_akt_exp
    }
  }


  method set_error {text} {
    global NAME BITMAPDIR TITLE

    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime $text"

    set rc [catch {server sendreceive cosy "$NAME set_error \"$text\""} \
            ret_string]

    if {!$rc} {
      # Falls kein Fehler dabei aufgetreten ist, id merken
      set error_id($text) $ret_string
    } else {
      tk_dialog .dia "$TITLE" $ret_string @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method reset_error {text} {
    global NAME BITMAPDIR TITLE

    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Fehler nicht mehr vorhanden: $text"

    if {[info exists error_id($text)]} {
      set id $error_id($text)

      set rc [catch {server sendreceive cosy "$NAME reset_error \"$id\""} \
              ret_string]

      if {$rc} {
        tk_dialog .dia "$TITLE" $ret_string @$BITMAPDIR/smily.xpm 0 OK
      }
    } else {
#        tk_dialog .dia "$TITLE" "Keine ID fuer den Fehler $text bekannt!" \
#                  @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method uebernehmen {to from} {
    after 10 "$this do_uebernehmen $to $from"
    return OK
  }


  method do_uebernehmen {to from} {
    set itime [getclock]
    set date [fmtclock $itime "%d %B %Y"]
    set ftime [fmtclock $itime %T]
    tlog insert "$date $ftime Werte uebernehmen von $from nach $to"
    group uebernehmen $to $from
  }


  method get_isbusy {} {return $is_busy}


  protected num 0
  protected is_busy 0
  protected x
  protected y
  protected pocolist
  protected cratelist
  protected error_id
}
