#
# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/beule.tcl,v 1.3 2012/01/26 10:34:27 tine Exp $
#

itcl_class beule_class {
  inherit graphic_class

  constructor {k} {
    global max_exp

    graphic_class::constructor $k $this

    set klasse $k
    set magnete [$k get_magnetlist]
    set maxlen 5
    set entry_time_list [list begin up top down]
    set entry_list [list topstrom begin up top down]

    for {set i 1} {$i <= $max_exp} {incr i} {
      foreach elem $time_list {
        set $initial${elem}($i) 1
      }

      set ${initial}topstrom($i) 0
      set ${initial}end($i) 0
      set list_sel($i) {}
      set exist($i) 0
    }
  }

  method init {args} {
    global WORKSPACE edit_exp

    foreach elem $time_list {
      set ${elem}($edit_exp) [orbit get_$elem $edit_exp]
    }

    if {[winfo exists .$this]} {
      raise.tk .$this
    } else {
      toplevel .$this
      wm title .$this $title
      wm minsize .$this 1 1
      wm command .$this $WORKSPACE

      bind .$this <Destroy> "global edit_exp;$this set_exist \[set edit_exp\] 0"

      # Menu
      frame .$this.menu -relief raised -bd 2
      pack .$this.menu -fill x -in .$this -side top

      menubutton .$this.menu.file -text "File" -menu .$this.menu.file.m
      menu .$this.menu.file.m
      .$this.menu.file.m add command -label "Quit" -command "$this quit"

      # Menu aus Modellrechnung uebernehmen
      menubutton .$this.menu.modell -text Modell -menu .$this.menu.modell.m
      menu .$this.menu.modell.m
      .$this.menu.modell.m add command -label "Aus 3bump bzw. 4bump \
                               uebernehmen" -command "$klasse modell bump"

      pack .$this.menu.file .$this.menu.modell -side left -padx 10

      frame .$this.box1
      frame .$this.box2 -relief ridge -borderwidth 1m
      frame .$this.box3 -relief ridge -borderwidth 1m
      pack .$this.box1 .$this.box2 .$this.box3 -side left -expand yes -fill \
           both -in .$this -padx 10 -pady 5

      makeliste
      makeentry
      makegraph .$this.box3
    }

    show_graph
    set_gesamtzeit
    set_exist $edit_exp 1
  }

  destructor {}


  method makeliste  {} {
    SelectBox_B2 .$this.select "$this button2"
    .$this.select config -width 14 -action "$this select"
    update_list
    pack .$this.select -in .$this.box1 -fill y
  }


  method makeentry {} {
    global gesamtzeit edit_exp

    foreach elem $entry_list {
      global $initial${elem}val
    }

    for {set i 1} {$i <= 4} {incr i} {
      frame .$this.box2.row$i
      pack .$this.box2.row$i -side top -expand yes -fill both
    }

    label .$this.lmax -text Max -width 8
    label .$this.max -text $top($edit_exp) -width 8
    label .$this.maxeinheit -text s -width 2
    pack .$this.lmax -side left -in .$this.box2.row1 -padx 8
    pack .$this.max .$this.maxeinheit -side left -in \
         .$this.box2.row1

    set ${initial}topstromval($this) [set ${initial}topstrom($edit_exp)]
    Value .$this.topstrom -label "Top-Strom" -unit % -limit 1 -check "$this \
          strom_check" -action "$this strom_return" -variable \
          ${initial}topstromval($this) -focus 0
    [.$this.topstrom get_child entry] config -width $entrywidth
    [.$this.topstrom get_child label] config -width 9 -anchor w
    [.$this.topstrom get_child unit] config -width 2
    pack .$this.topstrom -in .$this.box2.row2 -pady 2 -padx 5

    foreach elem $entry_time_list {
      set $initial${elem}val($this) [set $initial${elem}($edit_exp)]
      Value .$this.$elem -label "$elem time" -unit s -limit 1 -check "$this \
            time_check $elem" -action "$this time_return $elem" -variable \
            $initial${elem}val($this) -focus 0
      [.$this.$elem get_child entry] config -width $entrywidth
      [.$this.$elem get_child label] config -width 9 -anchor w
      [.$this.$elem get_child unit] config -width 2
      pack .$this.$elem -in .$this.box2.row2 -pady 2 -padx 5
    }

    menubutton .$this.brechne -width 9 -state disabled
    label .$this.lgesamt -textvariable gesamtzeit($this) -width 8 -anchor w
    label .$this.lgesamteinheit -text s -width 2 -anchor w
    button .$this.bgraph -text "Graph " -command "$this graph" -width 7
    menubutton .$this.blegend -text Legende -menu .$this.blegend.m -relief \
               raised -width 7
    menu .$this.blegend.m
    config_legend

    pack .$this.brechne -side left -in .$this.box2.row3 -anchor e -padx 2
    pack .$this.lgesamt -side left -in .$this.box2.row3 -anchor e
    pack .$this.lgesamteinheit -side left -in .$this.box2.row3 \
         -anchor e -padx 2
    pack .$this.bgraph -side left -in .$this.box2.row4 -anchor e -padx 5
    pack .$this.blegend -side left -in .$this.box2.row4 -padx 15
  }


  method strom_check {args} {
    global BITMAPDIR ${initial}topstromval TITLE

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "$title: Fehler im Wert fuer den Topstrom!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[string compare $args $val]} {
      set ${initial}topstromval($this) $val
    }

    return 0
  }


  method strom_return {val} {
    global edit_exp

    manage busy_hold

    database set_$this ${initial}topstrom $edit_exp $val
    set ${initial}topstrom($edit_exp) $val

    # Fgenfile neu rechnen
    rechne $edit_exp

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    focus [.$this.begin get_child entry]
    manage busy_release
  }


  method time_check {type args} {
    global BITMAPDIR TITLE

    foreach elem $entry_time_list {
      global $initial${elem}val
    }

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "$title: Fehler im Wert fuer $type time!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {$val < 0} {
      tk_dialog .dia "$TITLE" "$title: Fehler im Wert fuer $type time! Es sind \
                keine negativen Zeiten moeglich!" @$BITMAPDIR/smily.xpm 0 OK
      return 2
    }

    if {[string compare $args $val]} {
      set $initial${type}val($this) $val
    }

    return 0
  }


  method time_return {type val} {
    global edit_exp

    manage busy_hold

    database set_$this $initial$type $edit_exp $val
    set $initial${type}($edit_exp) $val
    set_gesamtzeit

    # Fgenfile neu rechnen
    rechne $edit_exp

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    set index [lsearch $entry_list $type]
    set next [lindex $entry_list [expr $index + 1]]

    if {[string length $next]} {
      focus [.$this.$next get_child entry]
    } else {
      focus none
    }

    manage busy_release
  }


  method set_gesamtzeit {} {
    global gesamtzeit edit_exp

    set gesamtzeit($this) 0

    foreach elem $entry_time_list {
      if {[set $initial${elem}($edit_exp)]!= ""} {
        set gesamtzeit($this) [expr $gesamtzeit($this) + [set \
                               $initial${elem}($edit_exp)]]
      }
    }
  }


  method rechne {num args} {
    global FGENDIR BITMAPDIR TITLE

    # Wenn keine Argumente uebergeben wurden: Berechnung fuer alle connecteten
    # Netzgeraete, ansonsten werden das zu berechnende element und evtl.
    # das Directory und die Werte dafuer uebergeben
    if {[llength $args] <= 1} {
      # Untersuchung auf Eingabefehler
      if {[eingabe_fehler]} {return -1}

      # Falls keine Argumente
      if {![llength $args]} {
        # Falls keine Elemente ausgewaehlt wurden
        if {$list_sel($num) == {}} {
          tk_dialog .dia "$TITLE" "$title: Es wurden keine Elemente in der \
                    Liste ausgewaehlt" @$BITMAPDIR/smily.xpm 0 Ok
          return -1
        }

        set elem_list $list_sel($num)
      } else {
        set elem_list $args
      }

      foreach line $elem_list {
        set elem [lindex [split $line] 0]
        set sollstrom($elem) [$elem get_soll $num]
        set otopstrom($elem) [$elem get_top $num]
        set topstrom($elem) [expr [set ${initial}topstrom($num)] * [$elem \
                             get_$scale_proc $num] + $otopstrom($elem)]
      }

      set dir $FGENDIR
    } else {
      set elem_list [lindex $args 0]
      set dir [lindex $args 1]
      set liste [lindex $args 2]
      set sollstrom($elem_list) [lindex $liste 0]
      set otopstrom($elem_list) [lindex $liste 1]
      set ${initial}topstrom($num) [lindex $liste 2]
      set topstrom($elem_list) [expr [set ${initial}topstrom($num)] * \
                               [$elem_list get_$scale_proc $num] + \
                                $otopstrom($elem_list)]
      set begin($num) [lindex $liste 3]
      set up($num) [lindex $liste 4]
      set bbegin($num) [lindex $liste 5]
      set bup($num) [lindex $liste 6]
      set btop($num) [lindex $liste 7]
      set bdown($num) [lindex $liste 8]
      set bend($num) [lindex $liste 9]
      set down($num) [lindex $liste 10]
      set end($num) [lindex $liste 11]
    }

    foreach line $elem_list {
      set elem  [lindex [split $line] 0]

      # Falls BW (300 A/s)
      if {[string first BW $elem] != -1} {
        set script Fgenbw
      } else {
        # Falls Elektronenkuehler-Steerer => Fgensteer
        if {[lsearch {gun_x gun_y col_x col_y} $elem] != -1} {
          set script Fgensteerec
        } else {
          # Falls SH11, SH13, SH39, SH41, SV32, SV34, SV38 => Fgensteerc \
          # (30 A/s), sonst Fgensteer (80 A/s)
          if {[lsearch {SH11 SH13 SH39 SH41 SV32 SV34 SV38} $elem] != -1} {
            set script Fgensteerc
          } else {
            set script Fgensteer
          }
        }
      }

      # Anzeige, dass gerechnet wird
      manage make_nachricht $elem $title "$dir/$elem.fgen$num wird berechnet"

      # Falls das Directory nicht das FGENDIR ist, Werte nicht merken
      if {![string compare $dir $FGENDIR]} {
        $elem set_rfgentyp $num $initial
      }

      set rc [catch {exec $script $dir/$elem.fgen$num \
             [expr int($begin($num)*1000)]:$sollstrom($elem) \
             [expr int($up($num)*1000)]:$otopstrom($elem) \
             [expr int($bbegin($num)*1000)]:$otopstrom($elem) \
             [expr int($bup($num)*1000)]:$topstrom($elem) \
             [expr int($btop($num)*1000)]:$topstrom($elem) \
             [expr int($bdown($num)*1000)]:$otopstrom($elem) \
             [expr int($bend($num)*1000)]:$otopstrom($elem) \
             [expr int($down($num)*1000)]:$sollstrom($elem) \
             [expr int($end($num)*1000)]:$sollstrom($elem) \
             2> /tmp/error_code}]

      if {$rc} {
        if {[file exists /tmp/error_code]} {
          set fd [open /tmp/error_code r]
          set line [gets $fd]
          close $fd
          tk_dialog .dia "$TITLE" "$elem: $line" @$BITMAPDIR/smily.xpm 0 Ok
          exec rm -f /tmp/error_code
        } else {
          tk_dialog .dia "$TITLE" "$elem: Fehler beim Aufruf von $script" \
                    @$BITMAPDIR/smily.xpm 0 Ok
        }
      } else {
        # Ueberpruefen, ob file size > 0
        if {[file size $dir/$elem.fgen$num] == 0} {
          tk_dialog .dia "$TITLE" "$elem: Die Datei $dir/$elem.fgen$num konnte \
                    nicht erzeugt werden!" @$BITMAPDIR/smily.xpm 0 Ok
        }
      }

      $elem set_aktpunkt $num 0
      $elem set_tgesamt $num
      $elem cmp_fgen $num
      manage destroy_nachricht $elem
    }
  }


  method eingabe_fehler {} {
    global BITMAPDIR edit_exp TITLE

    set error 0
    set error_string ""

    foreach elem $entry_time_list {
      if {[set $initial${elem}($edit_exp)] == ""} {
        set error 1
        if {$error_string == ""} {
          set error_string "$elem time"
        } else {
          append error_string ", $elem time"
        }
      }
    }

    if {$error == 1} {
      tk_dialog .dia "$TITLE" "$title: Es sind keine Werte fuer $error_string \
                bekannt" @$BITMAPDIR/smily.xpm 0 Ok
      return -1
    } else {
      # Ueberpruefen, ob Maximallaenge nicht ueberschritten wird
      set sum [expr $bbegin($edit_exp) + $bup($edit_exp) + $btop($edit_exp) + \
               $bdown($edit_exp)]
      if {$sum <= $top($edit_exp)} {
        set ${initial}end($edit_exp) [expr $top($edit_exp) - $sum]
        return 0
      } else {
        tk_dialog .dia "$TITLE" "$title: Die Maximalzeit wurde \
                  ueberschritten!" @$BITMAPDIR/smily.xpm 0 Ok
        return -1
      }
    }
  }


  method button2 {xpixel ypixel {name {}}} {
    global WORKSPACE scale_faktor edit_exp

    if {[llength $name]} {
      if {[winfo exists .scale$this]} {
        destroy .scale$this
      }

      toplevel .scale$this
      wm title .scale$this "Skalierung $name"
      set xpos [expr $xpixel - 30]
      set ypos [expr $ypixel - 55]
      wm geometry .scale$this 320x50+$xpos+$ypos
      wm command .scale$this $WORKSPACE
    ### Tine: 20.01.2012: Das Fenster bleibt sonst nicht oben !!!
      wm transient .scale$this .$this

      set scale_faktor($this) [$name get_$scale_proc $edit_exp]

      Value .scale$this.scale -limit 1 -check "$this scale_check" \
            -action "$this scale_return $name" -variable scale_faktor($this)
      set entry [.scale$this.scale get_child entry]
      button .scale$this.abbruch -text Abbrechen -command "destroy .scale$this"
      $entry config -width 20
      focus $entry
      bind $entry <Escape> "destroy .scale$this"
      pack .scale$this.scale .scale$this.abbruch -padx 5 -pady 2 -side left
    }
  }


  method scale_check {args} {
    global BITMAPDIR scale_faktor TITLE

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "Skalierung $title: Fehler im Wert fuer den \
                Skalierungsfaktor!" @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[string compare $args $val]} {
      set scale_faktor($this) $val
    }

    return 0
  }


  method scale_return {name val} {
    global BITMAPDIR edit_exp

    $name set_$scale_proc $edit_exp $val

    # Liste mit neuem Faktor zuweisen, View wieder auf vorherigen
    # Zustand setzen
    set line [lindex [.$this.select.sbar get] 2]
    update_list
    .$this.select.list yview $line
    destroy .scale$this

    # Falls Sextupol ausgewaehlt
    if {[lsearch -regexp $list_sel($edit_exp) $name] != -1} {
      rechne $edit_exp $name

      # show_graph fuer alle Graphen
      foreach elem [itcl_info objects -isa graphic_class] {
        $elem show_graph
      }
    }
  }


  method select_off {num} {
    global edit_exp

    # Falls num mit edit_exp uebereinstimmt und Fenster existiert
    if {($num == $edit_exp) && [winfo exists .$this.select]} {
      if {[winfo exists .$this.select]} {
        .$this.select select reset
      }
    } else {
      foreach elem $list_sel($num) {
        database set_$sel_proc [lindex [lindex $elem 0] 0] $num 0
      }
      set list_sel($num) {}
    }
  }


  method select_on {elem num} {
    global edit_exp

    set eintrag [lindex [make_liste $elem] 0]

    # Falls num mit edit_exp uebereinstimmt und Fenster existiert
    if {($num == $edit_exp) && [winfo exists .$this.select]} {
      .$this.select select entry $eintrag on
    } else {
      lappend list_sel($num) $eintrag
      database set_$sel_proc $elem $num 1
    }
  }


  method update_beulenscale {magnet num} {
    global edit_exp

    # Falls num mit edit_exp uebereinstimmt
    if {$num == $edit_exp} {
      # Falls Fenster existiert
      if {[winfo exists .$this]} {
        # Liste mit neuem Faktor zuweisen, View wieder auf vorherigen
        # Zustand setzen
        set line [lindex [.$this.select.sbar get] 2]
        update_list
        .$this.select.list yview $line
      }
    }
  }


  method quit {} {
    destroy .$this
  }


  method make_liste {magnete {num ""}} {
    global edit_exp

    if {![string length $num]} {
      set num $edit_exp
    }

    set liste {}

    foreach elem $magnete {
      set blanks "  "

      # Wenn Laenge des Magnetnamens kuerzer als maxlen, entsprechend viele
      # Blanks hinzufugenen
      for {set l [string length $elem]} {$l < $maxlen} {incr l} {
        append blanks " "
      }

      lappend liste $elem$blanks[$elem get_$scale_proc $num]
    }
    return $liste
  }


  method set_edit_exp {{num ""}} {
    global edit_exp

    foreach elem $entry_list {
      global $initial${elem}val
    }

    update

    if {[string length $num]} {
      set exist($edit_exp) $exist($num)

      foreach elem $entry_list {
        if {[string compare [set $initial${elem}($edit_exp)] \
                                [set $initial${elem}($num)]]} {
          set $initial${elem}($edit_exp) [set $initial${elem}($num)]
          database set_$this $initial${elem} $edit_exp \
                   [set $initial${elem}($num)]
        }
      }

      foreach elem $time_list {
        set ${elem}($edit_exp) [set ${elem}($num)]
      }

      set save_listsel $list_sel($edit_exp)
      set list_sel($edit_exp) $list_sel($num)

      foreach elem $list_sel($edit_exp) {
         set magnet [lindex $elem 0]

         # Falls magnet in bisheriger nicht angewaehlt war
         if {[lsearch -regexp $save_listsel $magnet] == -1} {
           database set_$sel_proc $magnet $edit_exp 1
         }
      }

      foreach elem $save_listsel {
         set magnet [lindex $elem 0]

         # Falls magnet in list_sel($edit_exp) nicht mehr angewaehlt ist
         if {[lsearch -regexp $list_sel($edit_exp) $magnet] == -1} {
           database set_$sel_proc $magnet $edit_exp 0
         }
      }

      foreach elem $magnete {
        $elem set_$scale_proc $edit_exp [$elem get_$scale_proc $num]
      }
    }

    set_graph_edit_exp

    if {!$exist($edit_exp)} {
      if {[winfo exists .$this]} {
        quit
      }
    } else {
      if {[winfo exists .$this]} {
        foreach elem $entry_list {
          set $initial${elem}val($this) [set $initial${elem}($edit_exp)]
        }

        .$this.max config -text $top($edit_exp)
        update_list
        set_gesamtzeit
      } else {
        init
      }
    }
  }


  method uebernehmen {to from} {
    global edit_exp

    foreach elem $entry_list {
      global $initial${elem}val
    }

    update
    set exist($to) $exist($from)

    foreach elem $entry_list {
      if {[string compare [set $initial${elem}($to)] \
                        [set $initial${elem}($from)]]} {
        set $initial${elem}($to) [set $initial${elem}($from)]
        database set_$this $initial${elem} $to [set $initial${elem}($from)]
      }
    }

    foreach elem $time_list {
      set ${elem}($to) [set ${elem}($from)]
    }

    set save_listsel $list_sel($to)
    set list_sel($to) $list_sel($from)

    foreach elem $list_sel($to) {
       set magnet [lindex $elem 0]

       # Falls magnet in bisheriger nicht angewaehlt war
       if {[lsearch -regexp $save_listsel $magnet] == -1} {
         database set_$sel_proc $magnet $to 1
       }
    }

    foreach elem $save_listsel {
       set magnet [lindex $elem 0]

       # Falls magnet in list_sel($to) nicht mehr angewaehlt ist
       if {[lsearch -regexp $list_sel($to) $magnet] == -1} {
         database set_$sel_proc $magnet $to 0
       }
    }

    foreach elem $magnete {
      $elem set_$scale_proc $to [$elem get_$scale_proc $from]
    }

    # falls to editiertes Experiment
    if {$to == $edit_exp} {
      set_graph_edit_exp

      if {!$exist($to)} {
        if {[winfo exists .$this]} {
          quit
        }
      } else {
        if {[winfo exists .$this]} {
          foreach elem $entry_list {
            set $initial${elem}val($this) [set $initial${elem}($to)]
          }

          .$this.max config -text $top($to)
          update_list
          set_gesamtzeit
        } else {
          init
        }
      }
    }
  }


  method select {args} {
    global edit_exp

    if {$do_select} {
      set list_sel($edit_exp) [.$this.select get selected]

      set mode [lindex $args [expr [llength $args] -1]]
      set elem [lindex [lindex $args 0] 0]

      # Falls angewaehlt
      if {![string compare $mode on]} {
        database set_$sel_proc $elem $edit_exp 1
      } else {
        database set_$sel_proc $elem $edit_exp 0
      }
    }
  }


  method update_list {args} {
    global edit_exp

    if {[winfo exists .$this.select]} {
      set do_select 0
      .$this.select config -list [make_liste $magnete]
      set magnete_sel {}

      if {[llength $list_sel($edit_exp)]} {
        foreach elem $list_sel($edit_exp) {
          set m [lindex $elem 0]
          lappend magnete_sel [lindex $m 0]
        }

        set list_sel($edit_exp) [make_liste $magnete_sel]

        foreach elem $list_sel($edit_exp) {
          .$this.select select entry $elem on
        }
      }

      set do_select 1
    }
  }


  method set_ausgewaehlt {elem num} {
    set list_sel($num) [concat $list_sel($num) [make_liste $elem $num]]

    # kein Update der angezeigten liste, da Methode nur fuer Initialisierung
    # aus der Datenbank
  }


  method save_object {fileid savelist} {
    global edit_exp max_exp

    foreach elem $entry_list {
      global $initial${elem}val
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      # Falls i in savelist
      if {[string first $i $savelist] != -1} {
        puts $fileid "$this set_topstrom $i [set ${initial}topstrom($i)]"

        foreach elem $time_list {
          puts $fileid "$this set_$elem $i [set ${elem}($i)]"
        }

        foreach elem $entry_time_list {
          puts $fileid "$this set_$initial$elem $i [set $initial${elem}($i)]"
        }

        puts $fileid "$this set_listsel $i $list_sel($i)"
        puts $fileid "$this set_exist $i $exist($i)"
      }
    }

    # falls edit_exp in savelist
    if {[string first $edit_exp $savelist] != -1} {
      puts $fileid "if {\[winfo exists .$this\]} {$this quit}"

      if {$exist($edit_exp)} {
        puts $fileid "if {!\[winfo exists .$this\]} {$this init}"
      }
    }
  }


  method update_topstrom {num val} {
    global edit_exp ${initial}topstromval

    set ${initial}topstrom($num) $val
    database set_$this ${initial}topstrom $num $val

    # Falls num mit edit_exp uebereinstimmt und Fenster existiert
    if {($num == $edit_exp) && [winfo exists .$this]} {
      set ${initial}topstromval($this) [set ${initial}topstrom($edit_exp)]
    }
  }


  method set_exist {num val} {
    set exist($num) $val
    database set_exist $this $num $val
  }


  ### Tine: 26.01.2012
  ### Kann aus einem alten Abspeicherfile heraus aufgerufen werden.
  ### Uebergebene Liste kann Element(e) enthalten, die aktuell nicht
  ### mehr in der GUI enthalten sind !!!
  ### num ist experimentnummer
  ### args enthaelt die Liste mit den Element-Wert-Listen
  method set_listsel {num args} {

    set list_sel($num) $args

    ### Tine: 26.01.2012
    # Elemente entfernen, die nicht mehr in der GUI enthalten sind !!!
    set obsolete_elem {}
    foreach elem $list_sel($num) {
      set elemname [lindex $elem 0]
      if {[lsearch $magnete $elemname] == -1} {
        lappend obsolete_elem $elem
      }
    }
    # Alle Elemente in $obsolete_elem aus $list_sel($num) entfernen !!!
    foreach elem $obsolete_elem {
      set index [lsearch $list_sel($num) $elem]
      set list_sel($num) [lreplace $list_sel($num) $index $index]
    }
    ###

    foreach elem $magnete {
      if {[lsearch -regexp $list_sel($num) $elem] != -1} {
        database set_$sel_proc $elem $num 1
      } else {
        database set_$sel_proc $elem $num 0
      }
    }
  }


  method set_topstrom {num {val ""}} {
    set btopstrom($num) $val
    database set_$this btopstrom $num $val
  }


  method set_bbegin {num {val ""}} {
    set bbegin($num) $val
    database set_$this bbegin $num $val
  }


  method set_bup {num {val ""}} {
    set bup($num) $val
    database set_$this bup $num $val
  }


  method set_btop {num {val ""}} {
    set btop($num) $val
    database set_$this btop $num $val
  }


  method set_bdown {num {val ""}} {
    set bdown($num) $val
    database set_$this bdown $num $val
  }


  method delete_listsel {num magnet} {
    global edit_exp

    set index [lsearch -regexp $list_sel($num) $magnet]

    if {$index != -1} {
      # Falls num = edit_exp und Fenster existert
      if {($num == $edit_exp) && [winfo exists .$this]} {
        set eintrag [lindex [make_liste $magnet] 0]
        .$this.select select entry $eintrag off
        select $magnet off
      } else {
        set list_sel($num) [lreplace $list_sel($num) $index $index]
        database set_$sel_proc $magnet $num 0
      }
    }
  }


  method insert_listsel {num magnet} {
    global edit_exp

    set eintrag [lindex [make_liste $magnet] 0]

    # Falls num = edit_exp und Fenster existert
    if {($num == $edit_exp) && [winfo exists .$this]} {
      .$this.select select entry $eintrag on
      select $magnet on
    } else {
      lappend list_sel($num) $eintrag
      database set_$sel_proc $magnet $num 1
    }
  }


  method set_topstromval {num {val ""}} {set btopstrom($num) $val}
  method set_bbeginval {num {val ""}} {set bbegin($num) $val}
  method set_bupval {num {val ""}} {set bup($num) $val}
  method set_btopval {num {val ""}} {set btop($num) $val}
  method set_bdownval {num {val ""}} {set bdown($num) $val}
  method get_topstrom {num} {return $btopstrom($num)}
  method set_bend {num {val ""}} {set bend($num) $val}
  method get_legendmenu {} {return .$this.blegend.m}
  method get_listsel {num} {return $list_sel($num)}
  method set_oldtopstrom {num} {set old_topstrom($num) $btopstrom($num)}
  method get_oldtopstrom {num} {return $old_topstrom($num)}
  method set_existval {num val} {set exist($num) $val}
  method get_exist {num} {return $exist($num)}
  method is_displayed {} {return [winfo exists .$this]}


  protected klasse
  protected bbegin
  protected bup
  protected btop
  protected bdown
  protected bend
  protected btopstrom
  protected list_sel
  protected do_select 1
  protected maxlen
  protected old_topstrom
  protected exist
  protected entry_list {}
  protected entry_time_list {}
  protected title Beule
  protected initial b
  protected sel_proc beulensel
  protected scale_proc beulenscale
  protected magnete {}
}
