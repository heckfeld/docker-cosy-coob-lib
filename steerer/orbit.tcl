itcl_class orbit_class {
  inherit graphic_class
  constructor {k} {
    graphic_class::constructor $k orbit
    set magnete [$k get_magnetlist]
  }


  method init {b} {
    global NAME

    set box $b

    # Falls nicht ecsteer
    if {[string first ecsteer $NAME] == -1} {
      frame $box.box2
      frame $box.box3
      pack $box.box2 $box.box3 -side left -expand yes -fill both \
           -in $box -padx 10
    } else {
      frame $box.box2 -relief ridge -borderwidth 1m
      frame $box.box3 -relief ridge -borderwidth 1m
      pack $box.box2 $box.box3 -expand yes -fill both -in $box -padx 10 \
           -side bottom
    }

    # Eingabefenster fuer Zeiten, Buttons fuer Rechnen und Graph
    makeentry

    # Graphik fuer Fgen-Files

############# Hier krachts mit der Meldung
#
# pgwish: bltGrAxis.c:1721: LayoutAxis: Assertion `labels <= axisPtr->numLabels' failed.
#
# Die beiden Statements auskommentiert von Kurt am 21.04.2004 19:35

# Am 3.5.04 den Kommentar wieder entfernt (Tine),
# da das Problem nun behoben sein sollte.

   makegraph $box.box3
   show_graph
  }

  destructor {}


  method makeentry {} {
    global gesamtzeit edit_exp beginval upval topval downval endval

    for {set i 1} {$i <= 3} {incr i} {
      frame $box.box2.row$i
      pack $box.box2.row$i -in $box.box2 -pady 2 -expand yes -fill both
    }

    foreach elem $time_list {
      Value $box.$elem -label "$elem time" -check "$this time_check $elem" \
            -action "$this time_return $elem" -limit 1 -unit s -variable \
            ${elem}val($this) -focus 0
      [$box.$elem get_child entry] config -width $entrywidth
      [$box.$elem get_child label] config -width 9 -anchor w
      set ${elem}val($this) [set ${elem}($edit_exp)]
      pack $box.$elem -in $box.box2.row1 -pady 2 -anchor w
    }

    button $box.brechne -text Rechne -width 7 -command "$this push_rechne" \
           -anchor w
    label $box.lgesamt -textvariable gesamtzeit($this) -width 9 -anchor c
    label $box.lgesamteinheit -text s
    button $box.bgraph -text "Graph " -command "$this graph" -width 7
    menubutton $box.blegend -text Legende -menu $box.blegend.m -relief raised \
               -width 7
    menu $box.blegend.m
    config_legend

    pack $box.brechne -in $box.box2.row2 -pady 2 -side left
    pack $box.lgesamt $box.lgesamteinheit -side left -in $box.box2.row2 \
         -anchor e -padx 3
    pack $box.bgraph -side left -in $box.box2.row3 -anchor w
    pack $box.blegend -side left -in $box.box2.row3 -padx 15

    set_gesamtzeit
  }


  method time_check {type args} {
    global BITMAPDIR beginval upval topval downval endval TITLE

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "Closed Orbit: Fehler im Wert fuer $type time!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {$val < 0} {
      tk_dialog .dia "$TITLE" "Closed Orbit: Fehler im Wert fuer $type time! \
                Es sind keine negativen Zeiten moeglich!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 2
     }

    if {[string compare $args $val]} {
      set ${type}val($this) $val
    }

    return 0
  }


  method time_return {type val} {
    global edit_exp

    manage busy_hold

    database set_orbit $type $edit_exp $val
    set ${type}($edit_exp) $val
    set_gesamtzeit
    beule set_$type $edit_exp $val
    wedel set_$type $edit_exp $val

    # Fgenfile neu rechnen
    foreach elem $magnete {
      $elem rech_fgen
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    set index [lsearch $time_list $type]
    set next [lindex $time_list [expr $index + 1]]

    if {[string length $next]} {
      focus [$box.$next get_child entry]
    } else {
      focus none
    }

    manage busy_release
  }


  method set_gesamtzeit {} {
    global gesamtzeit edit_exp

    set gesamtzeit($this) 0

    foreach elem $time_list {
      if {[set ${elem}($edit_exp)]!= ""} {
        set gesamtzeit($this) [expr $gesamtzeit($this) + [set \
                                            ${elem}($edit_exp)]]
      }
    }
  }


  method rechne {num args} {
    global FGENDIR BITMAPDIR graph TITLE

    # Wenn keine Argumente args uebergeben wurden: Berechnung fuer alle connec-
    # teten Netzgeraete, ansonsten werden das zu berechnende element und evtl.
    # das Directory und die Werte dafuer uebergeben
    if {[llength $args] <= 1} {
      # Untersuchung auf Eingabefehler
      if {[eingabe_fehler]} {return -1}

      # Falls keine Argumente
      if {![llength $args]} {
        set elem_list $magnete
      } else {
        set elem_list $args
      }

      foreach elem $elem_list {
        set sollstrom($elem) [$elem get_soll $num]
        set topstrom($elem) [$elem get_top $num]
      }
      set dir $FGENDIR
    } else {
      set elem_list [lindex $args 0]
      set dir [lindex $args 1]
      set liste [lindex $args 2]
      set sollstrom($elem_list) [lindex $liste 0]
      set topstrom($elem_list) [lindex $liste 1]
      set begin($num) [lindex $liste 2]
      set up($num) [lindex $liste 3]
      set top($num) [lindex $liste 4]
      set down($num) [lindex $liste 5]
      set end($num) [lindex $liste 6]
    }

    foreach elem $elem_list {
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
      manage make_nachricht $elem "Closed Orbit" "$dir/$elem.fgen$num wird\
             berechnet"

      # Falls das Directory nicht das FGENDIR ist, Werte nicht merken
      if {![string compare $dir $FGENDIR]} {
        $elem set_rfgentyp $num o
      }

      set rc [catch {exec $script $dir/$elem.fgen$num \
             [expr int($begin($num)*1000)]:$sollstrom($elem) \
             [expr int($up($num)*1000)]:$topstrom($elem) \
             [expr int($top($num)*1000)]:$topstrom($elem) \
             [expr int($down($num)*1000)]:$sollstrom($elem) \
             [expr int($end($num)*1000)]:$sollstrom($elem) \
             2> /tmp/error_code}]

      if {$rc} {
        if {[file exists /tmp/error_code]} {
          set fd [open /tmp/error_code r]
          set line [gets $fd]
          tk_dialog .dia "$TITLE" "$elem: $line" @$BITMAPDIR/smily.xpm 0 Ok
          exec rm -f /tmp/error_code
          close $fd
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

    foreach elem $time_list {
      if {[set ${elem}($edit_exp)] == ""} {
        set error 1
        if {$error_string == ""} {
          set error_string "$elem time"
        } else {
          append error_string ", $elem time"
        }
      }
    }

    if {$error == 1} {
      tk_dialog .dia "$TITLE" "Closed Orbit: Es sind keine Werte fuer \
                $error_string bekannt" @$BITMAPDIR/smily.xpm 0 Ok
      return -1
    } else {
      return 0
    }
  }


  method push_rechne {} {
    global edit_exp

    manage busy_hold
    rechne $edit_exp

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release
  }


  method set_edit_exp {{num ""}} {
    global edit_exp beginval upval topval downval endval

    if {[string length $num]} {
      foreach elem $time_list {
        if {[string compare [set ${elem}($edit_exp)] [set ${elem}($num)]]} {
          set ${elem}($edit_exp) [set ${elem}($num)]
          database set_orbit $elem $edit_exp [set ${elem}($num)]
        }
      }
    }

    set_graph_edit_exp

    if {[winfo exists $box]} {
      foreach elem $time_list {
        set ${elem}val($this) [set ${elem}($edit_exp)]
      }

      set_gesamtzeit
    }
  }


  method uebernehmen {to from} {
    global edit_exp beginval upval topval downval endval

    foreach elem $time_list {
      if {[string compare [set ${elem}($to)] [set ${elem}($from)]]} {
        set ${elem}($to) [set ${elem}($from)]
        database set_orbit $elem $to [set ${elem}($from)]
      }
    }

    # Falls to edit_exp
    if {$to == $edit_exp} {
      set_graph_edit_exp

      if {[winfo exists $box]} {
        foreach elem $time_list {
          set ${elem}val($this) [set ${elem}($to)]
        }

        set_gesamtzeit
      }
    }
  }


  method save_object {fileid savelist} {
    global gesamtzeit edit_exp max_exp

    for {set i 1} {$i <= $max_exp} {incr i} {
      # falls i in savelist
      if {[string first $i $savelist] != -1} {
        foreach elem $time_list {
          puts $fileid "$this set_$elem $i [set ${elem}($i)]"
        }
      }
    }

    # falls edit_exp in savelist
    if {[string first $edit_exp $savelist] != -1} {
      # falls Fenster existiert
      if {[winfo exists $box]} {
        foreach elem $time_list {
          set entry [$box.$elem get_child entry]
          puts $fileid "global ${elem}val; set ${elem}val($this) [set \
                        ${elem}($edit_exp)]"
        }

        puts $fileid "global gesamtzeit; set gesamtzeit($this) \
                      $gesamtzeit($this)"
        puts $fileid "$this set_graphsel $graph_sel; $this show_graph"
        puts $fileid "$this config_legend"
      } else {
        puts $fileid "$this set_graphsel $graph_sel"
      }
    }
  }


  method get_begin {num} {return $begin($num)}
  method get_up {num} {return $up($num)}
  method get_top {num} {return $top($num)}
  method get_down {num} {return $down($num)}
  method get_end {num} {return $end($num)}
  method get_legendmenu {} {return $box.blegend.m}


  protected box ""
  protected magnete {}
}
