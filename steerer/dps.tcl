# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/dps.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class dps_class {
  constructor {config} {
    global soll top dc aus max_exp title

    for {set i 1} {$i <= $max_exp} {incr i} {
      set rfgentyp($i) o
      set beulenscale($i) 1
      set wedelscale($i) 1
      set sollval($i) 0
      set topval($i) 0
      set akt_punkt($i) 0
      set x($i) {}
      set y($i) {}
      set xmax($i) 0
      set t_gesamt($i) 0
      set is_loaded($i) 0

      set ograph_waehl($i) 0
      set wgraph_waehl($i) 0
      set bgraph_waehl($i) 0
    }

    set title($this) $this
    set sollval(-1) ?
    set soll($this) 0
    set top($this) 0
    set dc($this) 1
    set aus($this) 0
  }


  destructor {}
  method config {config} {}


  method soll_check {args} {
    global BITMAPDIR soll TITLE

    if {[catch {expr $args} s]} {
      tk_dialog .dia "$TITLE" "$this: Fehler im Sollwert!" \
                @$BITMAPDIR/smily.xpm 1 Ok
      return 1
    }

    if {$s < $rmin} {
      tk_dialog .dia "$TITLE" "$this: Der Sollwert muss >= $rmin sein!" \
                @$BITMAPDIR/smily.xpm 1 Ok
       return 2
    }

    if {$s > $rmax} {
      tk_dialog .dia "$TITLE" "$this: Der Sollwert muss <= $rmax sein!" \
                @$BITMAPDIR/smily.xpm 1 Ok
      return 3
    }

    set soll($this) $s
    return 0
  }


  method top_check {args} {
    global BITMAPDIR top TITLE

    if {[catch {expr $args} t]} {
      tk_dialog .dia "$TITLE" "$this: Fehler im Topwert!" \
                @$BITMAPDIR/smily.xpm 1 Ok
      return 1
    }

    if {$t < $rmin} {
      tk_dialog .dia "$TITLE" "$this: Der Topwert muss >= $rmin sein!" \
                @$BITMAPDIR/smily.xpm 1 Ok
       return 2
    }

    if {$t > $rmax} {
      tk_dialog .dia "$TITLE" "$this: Der Topwert muss <= $rmax sein!" \
                @$BITMAPDIR/smily.xpm 1 Ok
      return 3
    }

    set top($this) $t
    return 0
  }


  method set_top {{t 0}} {
    global edit_exp

    set_topval $edit_exp $t
  }


  method set_beulenscale {enum s} {
    database set_beulenscale $this $enum $s
    set beulenscale($enum) $s
  }


  method set_wedelscale {enum s} {
    database set_wedelscale $this $enum $s
    set wedelscale($enum) $s
  }


  method set_download {n} {
    global FGENDIR BITMAPDIR exp_fehl TITLE

    switch $num {
      1 {set port 22385}
      2 {set port 22395}
      3 {set port 22405}
      4 {set port 22415}
    }

puts stderr "$this: set_download [$target get_targetfail]"
    # Falls kein target_fail
    if {![$target get_targetfail]} {
      tlog insert "fgendattcl $target $port 0 $FGENDIR/$this.fgen$n"

      # Unix-Prozess
      if {[catch {exec fgendattcl $target $port 0 \
                       $FGENDIR/$this.fgen$n} ret_string]} {
        set exp_fehl 1
        tk_dialog .dia "$TITLE" "$this: $ret_string" @$BITMAPDIR/smily.xpm 0 Ok
        set is_loaded($n) 0
        return
      } else {
        set is_loaded($n) 1
      }

      # Fgenfile als .startupfile copieren
      set rc [catch {exec cp $FGENDIR/$this.fgen$n \
              $FGENDIR/$this.fgen$n.startup} ret_string]

      if {$rc} {
        tk_dialog .dia "$TITLE" "$this: $ret_string" @$BITMAPDIR/smily.xpm 0 Ok
      }

      cmp_fgen $n
    }
  }


  method rech_fgen {{enum ""}} {
    global edit_exp

    # Falls enum uebergeben wird, ist das die zu rechnende Experiment-
    # nummer, ansonsten wird edit_exp genommen
    if {![llength $enum]} {
      set enum $edit_exp
    }

    # Fgenfile fuer aktuelles Experiment neu rechnen, da sich soll oder
    # topstrom veraendert haben
    switch $rfgentyp($enum) {
      o {set typ orbit}
      b {set typ beule}
      w {set typ wedel}
      e {return}
    }

    # Fgenfile berechnen
    $typ rechne $enum $this
  }


  method data_init {off dcval} {
    global aus dc BITMAPDIR TITLE

    if {[manage is_no_db_boolean $off]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert fuer das an- bzw. ausschalten \
                ist fehlerhaft ($off). Er wird auf true gesetzt! (Das \
                Netzgeraet wird eingeschaltet)!" @$BITMAPDIR/smily.xpm 0 Ok
      set off t
      database set_aus_ein $this 0
    }

    if {("$off" == "t") && !$aus($this)} {
      database set_aus_ein $this 0
    } else {
      if {("$off" == "f") && $aus($this)} {
        database set_aus_ein $this 1
      }
    }

    # DC- oder Sync
    if {[manage is_no_db_boolean $dcval]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert fuer den DC-Sync-Mode ist \
                fehlerhaft ($dcval). Er wird auf true gesetzt! (Das Netzgeraet \
                wird in den DC-Mode gesetzt)" @$BITMAPDIR/smily.xpm 0 Ok
      set dcval t
      database set_dc_sync $this 1
    }

    if {"$dcval" == "t"} {
      set was_dc 1
    } else {
      set was_dc 0
    }
  }

  method data_num_init {num s t bs ws cb cw go gb gw rf} {
    global soll top edit_exp title BITMAPDIR TITLE

    # Typ des Fgenfiles
    if {[manage is_no_fgentype $rf]} {
      tk_dialog .dia "$TITLE" "$this: Der Rechentyp von Experiment $num ist \
                fehlerhaft ($rf). Er wird auf o gesetzt!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set rf o
      database set_rechne $this $num o
    }

    set rfgentyp($num) $rf

    if {$num == $edit_exp} {
      switch $rf {
        o {set title($this) $this}
        b {set title($this) "$this (beule)"}
        w {set title($this) "$this (wedeln)"}
        e {set title($this) "$this (einzel)"}
      }
    }

    # t_gesamt bestimmen
    set_tgesamt $num

    # Sollwerte fuer Experimente
    if {[catch {expr $s}]} {
      tk_dialog .dia "$TITLE" "$this: Der Sollwert fuer Experiment $num ist \
                fehlerhaft ($num). Er wird auf 0 gesetzt!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set s 0
      database set_soll $this $num 0
    }

    set sollval($num) $s

    # Topwerte fuer Experimente
    if {[catch {expr $t}]} {
      tk_dialog .dia "$TITLE" "$this: Der Topwert fuer Experiment $num ist \
                fehlerhaft ($t). Er wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm \
                0 Ok
      set t 0
      database set_top $this $num 0
    }

    set topval($num) $t

    # Beulenscale fuer Experimente
    if {[catch {expr $bs}]} {
      tk_dialog .dia "$TITLE" "$this: Die Beulenskalierung fuer Experiment \
                $num ist fehlerhaft ($bs). Sie wird auf 1 gesetzt!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set bs 1
      database set_beulenscale $this $num 1
    }

    set beulenscale($num) $bs

    # Wedelscale fuer Experimente
    if {[catch {expr $ws}]} {
      tk_dialog .dia "$TITLE" "$this: Die Wedelskalierung fuer Experiment $num \
                ist fehlerhaft ($ws). Sie wird auf 1 gesetzt!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set ws 1
      database set_wedelscale $this $num 1
    }

    set wedelscale($num) $ws

    # Anzeige, ob Netzgeraet in Beule angewaehlt ist
    if {[manage is_no_db_boolean $cb]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert, ob das Netzgeraet in der Beule \
                von Experiment $num ausgewaehlt ist, ist fehlerhaft ($cb). Er \
                wird auf false gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set cb f
      database set_beulensel $this $num 0
    }

    if {"$cb" == "t"} {
      beule set_ausgewaehlt $this $num
    }

    # Anzeige, ob Netzgeraet in Wedel angewaehlt ist
    if {[manage is_no_db_boolean $cw]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert, ob das Netzgeraet im Wedel von \
                Experiment $num ausgewaehlt ist, ist fehlerhaft ($cw). Er \
                wird auf false gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set cw f
      database set_wedelsel $this $num 0
    }

    if {"$cw" == "t"} {
      wedel set_ausgewaehlt $this $num
    }

    # Anzeige, ob Netzgeraet in Graph von Orbit angewaehlt ist
    if {[manage is_no_db_boolean $go]} {
      tk_dialog .dia "$TITLE" "$this: Die Anzeige, ob Fgenfile im Orbitfenster \
                von Experiment $num ausgewaehlt ist, ist fehlerhaft ($go). Er \
                wird auf false gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set go f
      database set_graphsel orbit $this $num 0
    }

    if {"$go" == "t"} {
      set ograph_waehl($num) 1
    } else {
      set ograph_waehl($num) 0
    }

    # Anzeige, ob Netzgeraet in Graph von Beule angewaehlt ist
    if {[manage is_no_db_boolean $gb]} {
      tk_dialog .dia "$TITLE" "$this: Die Anzeige, ob Fgenfile im \
                Beulenfenster von Experiment $num ausgewaehlt ist, ist \
                fehlerhaft ($gb). Er wird auf false gesetzt!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set gb f
      database set_graphsel beule $this $num 0
    }

    if {"$gb" == "t"} {
      set bgraph_waehl($num) 1
    } else {
      set bgraph_waehl($num) 0
    }

    # Anzeige, ob Netzgeraet in Graph von Wedel angewaehlt ist
    if {[manage is_no_db_boolean $gw]} {
      tk_dialog .dia "$TITLE" "$this: Die Anzeige, ob Fgenfile im Wedelfenster \
                von Experiment $num ausgewaehlt ist, ist fehlerhaft ($gw). Er \
                wird auf false gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set gw f
      database set_graphsel wedel $this $num 0
    }

    if {"$gw" == "t"} {
      set wgraph_waehl($num) 1
    } else {
      set wgraph_waehl($num) 0
    }

    if {$num == $edit_exp} {
      if {$ograph_waehl($num)} {
        orbit set_graph_ausgewaehlt $this
      }

      if {$bgraph_waehl($num)} {
        beule set_graph_ausgewaehlt $this
      }

      if {$wgraph_waehl($num)} {
        wedel set_graph_ausgewaehlt $this
      }

      # globaler Soll und Top-Wert
      if {$num == $edit_exp} {
        set soll($this) $sollval($num)
        set top($this) $topval($num)
      }
    }
  }


  method data_fgen_init {num zeile zeit wert} {
    global BITMAPDIR TITLE

    # Zeiten fuer Orbit_einzel
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert fuer die Experimentnummer im \
                Einzelview ist fehlerhaft ($num)!" @$BITMAPDIR/smily.xpm 0 Ok
    }

    if {[manage is_no_posint $zeile]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert fuer die Zeile bei \
                Experimentnummer $num im Einzelview ist fehlerhaft ($zeile)!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    if {[catch {expr $zeit}]} {
      tk_dialog .dia "$TITLE" "$this: Der Wert fuer die Zeit in Zeile $zeile \
                bei Experimentnummer $num im Einzelview ist fehlerhaft \
                ($zeit)!" @$BITMAPDIR/smily.xpm 0 Ok
    }

    if {[catch {expr $wert}]} {
      tk_dialog .dia "$TITLE" "$this: Der Amplitudenwert fuer die Zeile $zeile \
                bei Experimentnummer $num im Einzelview ist fehlerhaft \
                ($num)!" @$BITMAPDIR/smily.xpm 0 Ok
    }

    orbit$this init_zeile $num $zeile $zeit $wert
  }


  method save_object {fileid savelist} {
    global max_exp NAME last

    # Gerechnete Werte und Werte beim Download, Beulen- und Wedelscale
    # Soll und Topstroeme
    for {set i 1} {$i <= $max_exp} {incr i} {
      # falls i in savelist
      if {[string first $i $savelist] != -1} {
        puts $fileid "$this set_rfgentyp $i $rfgentyp($i)"
        puts $fileid "$this set_beulenscale $i $beulenscale($i)"
        puts $fileid "$this set_wedelscale $i $wedelscale($i)"
        puts $fileid "$this set_ographwaehl $i $ograph_waehl($i)"
        puts $fileid "$this set_wgraphwaehl $i $wgraph_waehl($i)"
        puts $fileid "$this set_bgraphwaehl $i $bgraph_waehl($i)"
        puts $fileid "$this set_sollval $i $sollval($i)"
        puts $fileid "$this set_topval $i $topval($i)"
      }
    }

    # falls ecsteer
    if {[string first ecsteer $NAME] != -1} {
      puts $fileid "$this set_positiv $last($this)"
    }
  }


  method uebernehmen {to from} {
    if {[string compare $rfgentyp($to) $rfgentyp($from)]} {
      set_rfgentyp $to $rfgentyp($from)
    }

    if {[string compare $beulenscale($to) $beulenscale($from)]} {
      set_beulenscale $to $beulenscale($from)
    }

    if {[string compare $wedelscale($to) $wedelscale($from)]} {
      set_wedelscale $to $wedelscale($from)
    }

    # Anzeige, ob Netzgeraet in Orbit, Beule oder Wedel angewaehlt ist
    if {[string compare $ograph_waehl($to) $ograph_waehl($from)]} {
      set_ographwaehl $to $ograph_waehl($from)
    }

    if {[string compare $bgraph_waehl($to) $bgraph_waehl($from)]} {
      set_bgraphwaehl $to $bgraph_waehl($from)
    }

    if {[string compare $wgraph_waehl($to) $wgraph_waehl($from)]} {
      set_wgraphwaehl $to $wgraph_waehl($from)
    }
  }


  method make_punkte {enum} {
    global FGENDIR BITMAPDIR TITLE NAME

    set x($enum) {}
    set y($enum) {}

    if {[file exists $FGENDIR/$this.fgen$enum]} {
      if {"$NAME" == "ecsteer"} {
        set script fgen2ecxypr
      } else {
        set script fgen2xypr
      }

      set rc [catch {exec $script <$FGENDIR/$this.fgen$enum} values]

      if {$rc} {
        tk_dialog .dia "$TITLE" "$this: Das Fgen-File $FGENDIR/$this.fgen$enum \
                  kann nicht dargestellt werden!" @$BITMAPDIR/smily.xpm 0 Ok
        return
      }

      set x($enum) {}
      set y($enum) {}

global testbetrieb
if {$testbetrieb} {
puts "----"
puts "File: $FGENDIR/$this.fgen$enum"
puts "script=$script"
puts "values=$values"
puts "----"
}
      # Tine: 16.09.2014 wegen Fehlermeldung
      #set xpunkt 0

      foreach line [split $values "\n"] {
        set punkt [split $line]

        set xpunkt [expr [lindex $punkt 0] * 0.001]
        set ypunkt [lindex $punkt 1]

        lappend x($enum) $xpunkt
        lappend y($enum) $ypunkt

        set akt_punkt($enum) 1
      }

      set xmax($enum) $xpunkt
    } else {
      tk_dialog .dia "$TITLE" "$this: Das Fgen-File $FGENDIR/$this.fgen$enum \
                existiert nicht!" @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  method modell {op val enum mode} {
    global edit_exp soll top BITMAPDIR TITLE

    set soll_fehler 0
    set command_ok 1

    # Falls val fehlerhaft
    if {[catch {expr $val}]} {
      set command_ok 0
      return
    }

    # Falls op soll
    if {[string first soll $op] != -1} {
      # Falls additiv
      if {[string first add $mode] != -1} {
        set val [expr $val + $sollval($enum)]
      }

      if {($val > $rmax) || ($val < $rmin)} {
        set command_ok 0
        return
      }

      # Falls enum mit edit_exp uebereinstimmt
      if {$enum == $edit_exp} {
        set soll($this) $val
        set soll_fehler [set_soll $val]
      } else {
        set_sollval $enum $val
      }

      # Fgen-File rechnen
      rech_fgen $enum
    } else {
      # Falls op top
      if {[string first top $op] != -1} {
        # Falls additiv
        if {[string first add $mode] != -1} {
          set val [expr $val + $topval($enum)]
        }

        if {($val > $rmax) || ($val < $rmin)} {
          set command_ok 0
          return
        }

        # Falls enum mit edit_exp uebereinstimmt
        if {$enum == $edit_exp} {
          set top($this) $val
        }

        set_topval $enum $val

        # Fgenfile rechnen
        rech_fgen $enum
      } else {
        # op ist Beule
        beule select_on $this $enum

        # Falls additiv
        if {[string first add $mode] != -1} {
          # Falls Fgentyp beule war
          if {![string compare $rfgentyp($enum) b]} {
            set_beulenscale $enum [expr [beule get_oldtopstrom $enum] * \
                                     $beulenscale($enum) + $val]
          } else {
            set_beulenscale $enum $val
          }
        } else {
          set_beulenscale $enum $val
        }

        beule update_beulenscale $this $enum
        beule rechne $enum $this
      }
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    return $soll_fehler
  }


  method set_sollval {enum {s ""}} {
    set sollval($enum) $s
    database set_soll $this $enum $s
  }


  method set_topval {enum {t 0}} {
    set topval($enum) $t
    database set_top $this $enum $t
  }


  method set_ographwaehl {enum val} {
    set save $ograph_waehl($enum)
    set ograph_waehl($enum) $val

    if {$save != $val} {
      database set_graphsel orbit $this $enum $val
    }
  }


  method set_bgraphwaehl {enum val} {
    set save $bgraph_waehl($enum)
    set bgraph_waehl($enum) $val

    if {$save != $val} {
      database set_graphsel beule $this $enum $val
    }
  }


  method set_wgraphwaehl {enum val} {
    set save $wgraph_waehl($enum)
    set wgraph_waehl($enum) $val

    if {$save != $val} {
      database set_graphsel wedel $this $enum $val
    }
  }


  method set_rfgentyp {enum typ} {
    global title edit_exp

    set rfgentyp($enum) $typ
    database set_rechne $this $enum $typ

    if {$enum == $edit_exp} {
      switch $typ {
        o {set title($this) $this}
        b {set title($this) "$this (beule)"}
        w {set title($this) "$this (wedeln)"}
        e {set title($this) "$this (einzel)"}
      }
    }
  }


  method set_tgesamt {num} {
    set t_gesamt($num) [sum_fgen $num]
  }


  method sum_fgen {num} {
    global FGENDIR

    set file $FGENDIR/$this.fgen$num

    if {![file exists $file]} {
      return 0
    }

    set rc [catch {exec grep : $file} ret_string]

    if {$rc} {
      return 0
    }

    set time 0

    foreach elem [split $ret_string "\n"] {
      set time [expr $time + [lindex [split $elem :] 0]]
    }

    # 200 ms Abstand wird benoetigt
    incr time 200

    return $time
  }


  method get_name_num {} {
    # Falls nicht Backlegwinding-Steerer Anke
    if {[string first BLW-D $this] == -1} {
      return [string range $this 2 3]
    } else {
      return [string range $this 5 6]
    }
  }


  method set_null {args} {
    global edit_exp soll top FGENDIR

    set soll_fehler 0

    # Falls args uebergeben wird, ist enum args, ansonsten ist enum edit_exp
    if {[llength $args]} {
      set enum $args
    } else {
      set enum $edit_exp
    }

    # Falls enum = edit_exp
    if {$enum == $edit_exp} {
      if {[expr double($sollval($enum))] != 0.0} {
        set soll($this) 0
        set soll_fehler [set_soll 0]
      }

      set top($this) 0
    } else {
      set_sollval $enum 0
    }

    set_topval $enum 0

    # Null-Fgenfile rechnen, falls kein Nullfgenfile
    if {[string compare $rfgentyp($enum) o] || ![is0fgenfile \
                                    $FGENDIR/$this.fgen$enum]} {
      orbit rechne $enum $this
    }

    # Aus Beule und Wedel entfernen
    beule delete_listsel $enum $this
    wedel delete_listsel $enum $this

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    return $soll_fehler
  }


  method set_topnull {enum} {
    global edit_exp top FGENDIR

    if {$topval($enum) != 0.0} {
      # Falls enum = edit_exp
      if {$enum == $edit_exp} {
        set top($this) 0
      }

      set_topval $enum 0
      orbit rechne $enum $this

      # Aus Beule und Wedel entfernen
      beule delete_listsel $enum $this
      wedel delete_listsel $enum $this

      # show_graph fuer alle Graphen
      foreach elem [itcl_info objects -isa graphic_class] {
        $elem show_graph
      }
    }
  }


  method is0fgenfile {file} {
    if {![file exists $file]} {
      return 0
    }

    set rc [catch {exec grep : $file} ret_string]

    if {$rc} {
      return 0
    }

    set null 1

    foreach elem [split $ret_string "\n"] {
      set val [expr [lindex [split $elem :] 1]]

      if {$val != 0} {
        set null 0
      }
    }

    return $null
  }


  method cmp_fgen {num} {
    global FGENDIR fgen_alt

    set rc [catch {exec cmp $FGENDIR/$this.fgen$num \
            $FGENDIR/$this.fgen$num.startup} ret_string]

    if {$rc} {
      set fgen_alt($this,$num) 1
    } else {
      set fgen_alt($this,$num) 0
    }
  }


  method go123 {} {
    global explist stop BITMAPDIR max_exp

    # Timing-Receiver stoppen, falls nicht gestoppt
    set trx [$crate get_trx]

    if {!$stop($trx)} {
      $trx stop
    }

    set stop(trx) 1
    set do_ramp 1

    while {$do_ramp} {
      set rc [$crate sclc 0]
      set do_ramp [expr $rc && ![$target get_targetfail]]
    }

    $crate download123 $this
    $crate rlex
    set old_expstring $explist

    $trx start
    set stop($trx) 0
  }


  method single_go {} {
    global stop abbruch edit_exp

    # Timing-Receiver stoppen, falls nicht gestoppt
    set trx [$crate get_trx]

    if {!$stop($trx)} {
       $trx stop
     }

     set stop(trx) 1
     set abbruch($this) 0

     if {![winfo exists .startup_abbruch$this]} {
       toplevel .startup_abbruch$this
       wm title .startup_abbruch$this "Warten auf Fgen OK fuer $this"
       wm geometry .startup_abbruch$this 300x100
       button .startup_abbruch$this.abbruch -text Abbruch -relief groove \
              -borderwidth 3m -command "$this startup_abbruch" -height 2
       pack .startup_abbruch$this.abbruch -anchor c -padx 10 -pady 10
     }

     single_startup
  }


  method single_startup {} {
    global explist startup_count max_exp stop abbruch akt_exp

    if {$abbruch($this)} {
      incr startup_count($crate) -1

      set ende 1

      foreach elem [itcl_info objects -isa crate_class] {
        if {$startup_count($elem)} {
          set ende 0
        }
      }

      if {$ende} {
        manage busy_release
      }

      return
    }

puts stderr "$this single_startup: [$target get_targetfail]"
    set rc [$crate sclc 0]
    set do_ramp [expr $rc && ![$target get_targetfail]]

    if {$do_ramp} {
      after 1000 "$this single_startup"
      return
    }

    catch {destroy .startup_abbruch$this}

    # Sollwert ans Netzgeraet schicken
    $crate send_soll $this $sollval($akt_exp)

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[lsearch $explist $i] != -1} {
        set is_loaded($i) 0
      }
    }

    $crate download123 $this
    set old_expstring $explist

    if {$startup_count($crate) <= 1} {
      incr startup_count($crate) -1
      $crate rlex
      set trx [$crate get_trx]

      if {$stop($trx)} {
        $trx start
        set stop($trx) 0
      }
    } else {
      incr startup_count($crate) -1
    }


    set ende 1

    foreach elem [itcl_info objects -isa crate_class] {
      if {$startup_count($elem)} {
        set ende 0
      }
    }

    if {$ende} {
      manage busy_release
    }
  }


  method save_werte {} {
    global max_exp

    for {set i 1} {$i <= $max_exp} {incr i} {
      set save_werte(soll,$i) $sollval($i)
      set save_werte(top,$i) $topval($i)
      set save_werte(rfgentyp,$i) $rfgentyp($i)
      set save_werte(beulensel,$i) [expr ([lsearch -regexp [beule \
                                    get_listsel $i] $this] != -1)]
      set save_werte(wedelsel,$i) [expr ([lsearch -regexp [wedel \
                                   get_listsel $i] $this] != -1)]
    }
  }


  method undo_werte {} {
    global edit_exp soll top max_exp title

    set soll_fehler 0

    for {set i 1} {$i <= $max_exp} {incr i} {
      set change($i) 0

      if {[string compare $save_werte(soll,$i) $sollval($i)]} {
        # Falls i mit edit_exp uebereinstimmt
        if {$i == $edit_exp} {
          set soll($this) $save_werte(soll,$i)
          set soll_fehler [set_soll $save_werte(soll,$i)]
        } else {
          set_sollval $i $save_werte(soll,$i)
        }

        set change($i) 1
      }

      if {[string compare $save_werte(top,$i) $topval($i)]} {
        # Falls i mit edit_exp uebereinstimmt
        if {$i == $edit_exp} {
          set top($this) $save_werte(top,$i)
        }

        set_topval $i $save_werte(top,$i)
        set change($i) 1
      }

      set rfgentyp($i) $save_werte(rfgentyp,$i)

      if {$i == $edit_exp} {
        switch $rfgentyp($i) {
          o {set title($this) $this}
          b {set title($this) "$this (beule)"}
          w {set title($this) "$this (wedeln)"}
          e {set title($this) "$this (einzel)"}
        }
      }

      if {$change($i)} {
        rech_fgen $i
      }

      # Beulensel und Wedelsel
      set waehl [expr ([lsearch -regexp [beule get_listsel $i] $this] != -1)]

      if {[string compare $save_werte(beulensel,$i) $waehl]} {
        beule insert_listsel $i $this
      }

      set waehl [expr ([lsearch -regexp [wedel get_listsel $i] $this] != -1)]

      if {[string compare $save_werte(wedelsel,$i) $waehl]} {
        wedel insert_listsel $i $this
      }
    }

    return $soll_fehler
  }


  method startup_abbruch {} {
    global abbruch

    set abbruch($this) 1
    catch {destroy .startup_abbruch$this}
  }


  method startwerte_pruefen {} {
    global max_exp explist BITMAPDIR TITLE

    # Ueberpruefen, ob Startwerte uebereinstimmen
    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[string first $i $explist] != -1} {
        lappend elist $i
      }
    }

    if {[diff_startwerte $elist]} {
      tk_dialog .dia "$TITLE" "$this: Die Startwerte fuer die Experimente aus \
                der Experimentfolge stimmen nicht ueberein! Der Startup wird \
                abgebrochen!" @$BITMAPDIR/smily.xpm 0 Ok
      return 1
    }

    return 0
  }


  method fgenlaenge_pruefen {} {
    global max_exp explist BITMAPDIR TITLE

    # Ueberpruefen, ob Laenge des Fgenfiles zu lang
    for {set i 1} {$i <= $max_exp} {incr i} {
      set t_impuls($i) 0
    }

    set rc [catch {exec coob_tx -ntimstx} ret_string]
puts stderr "coob_tx ergab: $ret_string"

    if {!$rc} {
      set line [split [lindex [split $ret_string :] 1] ,]

      for {set i 1} {$i <= $max_exp} {incr i} {
        set val [lindex $line [expr $i -1]]

        if {![catch {expr $val} ret_string]} {
          set t_impuls($i) $val
        }
      }
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      # falls i in der Experimentfolge vorkommt
      if {[string first $i $explist] != -1} {
        if {[get_tgesamt $i] > $t_impuls($i)} {
          tk_dialog .dia "$TITLE" "$this: Fuer Experiment $i ist die Laenge \
                    des Fgenfiles zu lang im Vergleich zur Zykluszeit des \
                    Timing-Senders!" @$BITMAPDIR/smily.xpm 0 Ok
        }
      }
    }
  }


  method diff_startwerte {elist} {
    for {set i 0} {$i <= [expr [llength $elist] - 2]} {incr i} {
      if {[convert2bit $sollval([lindex $elist $i])] != [convert2bit \
                             $sollval([lindex $elist [expr $i + 1]])]} {
        return 1
      }
    }

    return 0
  }


  method convert2bit {s} {
    return [expr round($scmin +double($scmax-$scmin)/($rmax-$rmin)*($s-$rmin))]
  }


  method set_soll {s {akt 1}} {
    global akt_exp edit_exp dc

    set soll_fehler 0
    set rc 0
    set_sollval $edit_exp $s

    if {$akt_exp == $edit_exp} {
      # Falls nicht im DC-Mode, in den DC-Mode setzen
      if {!$dc($this)} {
        set soll_fehler [$crate set_dc]
      }

      if {!$soll_fehler} {
        set soll_fehler [$crate send_soll $this $s]

        if {$akt} {
          $crate aktuate_ist
        }
      }
    }

    return $soll_fehler
  }


  method set_edit_exp {} {
    global edit_exp soll top title

    set soll($this) $sollval($edit_exp)
    set top($this) $topval($edit_exp)

    switch $rfgentyp($edit_exp) {
      o {set title($this) $this}
      b {set title($this) "$this (beule)"}
      w {set title($this) "$this (wedeln)"}
      e {set title($this) "$this (einzel)"}
    }
  }


  method set_positiv {val} {}


  method get_top {enum} {return $topval($enum)}
  method get_soll {enum} {return $sollval($enum)}
  method get_crate {} {return $crate}
  method set_crate {c} {set crate $c}
  method get_connum {} {return $conn_num}
  method get_num {} {return $num}
  method get_rmin {} {return $rmin}
  method get_rmax {} {return $rmax}
  method get_scmin {} {return $scmin}
  method get_scmax {} {return $scmax}
  method get_beulenscale {enum} {return $beulenscale($enum)}
  method get_wedelscale {enum} {return $wedelscale($enum)}
  method set_lfgentyp {args} {}
  method get_rfgentyp {enum} {return $rfgentyp($enum)}
  method get_waehl {} {return $waehl}
  method get_was_dc {} {return $was_dc}
  method set_dorech {d} {set do_rech $d}
  method get_dorech {} {return $do_rech}
  method set_rwerte {args} {}
  method set_lwerte {args} {}
  method set_aktpunkt {enum a} {set akt_punkt($enum) $a}
  method get_aktpunkt {enum} {return $akt_punkt($enum)}
  method get_xmax {enum} {return $xmax($enum)}
  method get_x {enum} {return $x($enum)}
  method get_y {enum} {return $y($enum)}
  method get_ographwaehl {enum} {return $ograph_waehl($enum)}
  method get_bgraphwaehl {enum} {return $bgraph_waehl($enum)}
  method get_wgraphwaehl {enum} {return $wgraph_waehl($enum)}
  method get_magnetegroup {} {return $this}
  method get_tgesamt {enum} {return $t_gesamt($enum)}
  method set_isloaded {enum val} {set is_loaded($enum) $val}
  method get_isloaded {enum} {return $is_loaded($enum)}
  method set_egraphwaehl {args} {}
  method get_commandok {} {return $command_ok}


  public conn_num
  public num
  public rmin
  public rmax
  public scmin
  public scmax
  public group
  public target
  protected topval
  protected sollval
  protected crate
  protected beulenscale
  protected wedelscale
  protected rfgentyp
  protected waehl
  protected was_dc 1
  protected lexp 0
  protected do_rech 1
  protected akt_punkt
  protected x
  protected y
  protected xmax
  protected ograph_waehl
  protected wgraph_waehl
  protected bgraph_waehl
  protected t_gesamt
  protected old_expstring ""
  protected is_loaded
  protected save_werte
  protected command_ok 1
}
