itcl_class orbit_einzel_class {
  constructor {config} {
    global max_exp

    for {set i 1} {$i <= $max_exp} {incr i} {
      set zeilen_max($i) 0

     # Tine: 09.02.06
     # Initialisierung, falls mal ein Eintrag geloescht wurde, und spaeter
     # nicht mehr aus der Datenbank gesetzt wird !!!
      for {set j 1} {$j <= $MaxZeilen} {incr j} {
        set timeval($i,$j) 1
        set amplval($i,$j) 0
      }
    }

  }


  destructor {}
  method config {config} {}


  ##
  ## insert a line before selected line
  ##
  method vinsert {} {
    global BITMAPDIR edit_exp ampl time summe TITLE

    if {$zeilen_max($edit_exp) == $MaxZeilen} {
     tk_dialog .dia "$TITLE" "FgenEditor $magnet: Es sind maximal $MaxZeilen\
               Zeilen moeglich!" @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_hold
    incr zeilen_max($edit_exp)
    set line $zeilenframe._$zeilen_max($edit_exp)
    makeline $zeilen_max($edit_exp)

    if {$current} {
      ##
      ## Einfuegen einer Zeile vor current, verschieben der Eintrage
      ##
      set temp $zeilen_max($edit_exp)

      while {$temp > $current} {
        set prev [expr $temp -1]
        set timeval($edit_exp,$temp) $timeval($edit_exp,$prev)
        set amplval($edit_exp,$temp) $amplval($edit_exp,$prev)
        set time($magnet,$temp) $time($magnet,$prev)
        set ampl($magnet,$temp) $ampl($magnet,$prev)
        database set_einzel_time_ampl $magnet $edit_exp $temp \
                 $timeval($edit_exp,$temp) $amplval($edit_exp,$temp)
        set temp $prev
      }

      set index $current
    } else {
      set index $zeilen_max($edit_exp)
    }

    set timeval($edit_exp,$index) 1
    set amplval($edit_exp,$index) 0
    set time($magnet,$index) 1
    set ampl($magnet,$index) 0
    database set_einzel_time_ampl $magnet $edit_exp $index 1 1
    rechne
    summe
    manage busy_release
  }


  ##
  ## delete selected line
  ##
  method vdelete {} {
    global edit_exp

    if {!$current} return
    if {$zeilen_max($edit_exp) == 1} return
    manage busy_hold
    _delete $current
    manage busy_release
  }


  method _delete {num} {
    global edit_exp time ampl

    if { $current == $num } {
      set_current $current
      set current 0
      set oc 0
    }

    if { $num != $zeilen_max($edit_exp) } {
      set temp $num

      while {$temp < $zeilen_max($edit_exp)} {
        set next [expr $temp + 1]
        set timeval($edit_exp,$temp) $timeval($edit_exp,$next)
        set amplval($edit_exp,$temp) $amplval($edit_exp,$next)
        set time($magnet,$temp) $time($magnet,$next)
        set ampl($magnet,$temp) $ampl($magnet,$next)
        database set_einzel_time_ampl $magnet $edit_exp $temp \
                 $timeval($edit_exp,$temp) $amplval($edit_exp,$temp)
        set temp $next
      }
    }

    database delete_einzel $magnet $edit_exp $zeilen_max($edit_exp)
    destroy $zeilenframe._$zeilen_max($edit_exp)
    unset time($magnet,$zeilen_max($edit_exp))
    unset ampl($magnet,$zeilen_max($edit_exp))
    incr zeilen_max($edit_exp) -1
    rechne
    summe
  }


  method init {b} {
    global fgenhome experiment summe edit_exp

    set box $b

    frame $box.fakt
    frame $box.fedit
    pack $box.fakt $box.fedit -side top -pady 2 -expand yes -fill both -padx 10

    label $box.laktexp -text "aktuelles Experiment:  "
    label $box.aktexp -textvariable akt_exp
    pack $box.laktexp $box.aktexp -in $box.fakt -side left

    label $box.leditexp -text "editiertes Experiment:  "
    label $box.editexp -textvariable edit_exp
    pack $box.leditexp $box.editexp -in $box.fedit -side left

    frame $box.buttons -relief ridge -borderwidth 1m
    pack $box.buttons -side top -expand yes -fill both

    button $box.insert -text Einfuegen -command "$this vinsert" \
           -relief raised -padx 4 -pady 2
    button $box.delete -text Loeschen -command "$this vdelete" \
           -relief raised -padx 4 -pady 2

    # Werte aus Gruppe uebernehmen
    button $box.gruppe -text "Werte aus Gruppe" -width 17 \
           -command "$this gruppen_werte"

    pack $box.insert $box.delete $box.gruppe -side left -in $box.buttons \
         -fill x -expand 1 -padx 10 -pady 10

    frame $box.frame
    pack $box.frame -fill both -expand 1

    frame $box.lbox -relief ridge -borderwidth 1m
    frame $box.rbox -relief ridge -borderwidth 1m
    pack $box.lbox $box.rbox -side left -fill both -expand 1 -in $box.frame

    frame $box.comment -relief flat -borderwidth 0
    pack $box.comment -in $box.lbox -fill both -expand 1

    frame $box.comment.title
    pack $box.comment.title -side top -anchor nw -in $box.comment
    set zeilenframe $box.comment

    label $box.comment.title.column -text "Nr." -width 6 -anchor w
    label $box.comment.title.time -text "Delta t (s)" -width 10 -anchor w
    label $box.comment.title.summe -text "Summe (s)" -width 11 -anchor w
    label $box.comment.title.ampl -text "Amplitude" -width 10 -anchor w
    pack $box.comment.title.column $box.comment.title.time \
         $box.comment.title.summe $box.comment.title.ampl -in \
         $box.comment.title -side left -expand 1

    blt_graph $box.graph -height 280 -borderwidth 2 -relief groove \
              -plotborderwidth 2 -plotrelief groove -plotbackground white \
              -background #c0c0c0
    $box.graph xaxis configure -title "Interval #"
    $box.graph yaxis configure -title "Amplitude \[%]"
    $box.graph legend configure -mapped no
    $box.graph element create line -foreground {#1653a1} -background black \
               -symbol circle -linewidth 3

    for {set i 1} {$i <= $zeilen_max($edit_exp)} {incr i} {
      makeline $i
    }

    summe

    if {$current} {
      set selected($current) 0
      set oc 0
      set_current $current
    }

    SetZoom $box.graph
    show_graph
    pack $box.graph -side left -fill both -expand yes -in $box.rbox
  }


  method summe {} {
    global summe edit_exp

    set sum 0

    for {set i 1} {$i <= $zeilen_max($edit_exp)} {incr i} {
      set sum [expr $sum + $timeval($edit_exp,$i)]
      set summe($magnet,$i) $sum
    }
  }


  method show_graph {} {
    global edit_exp

    if {$zeilen_max($edit_exp)} {
      for {set i 1} {$i <= $zeilen_max($edit_exp)} {incr i} {
        lappend data $i $amplval($edit_exp,$i)
      }

      $box.graph element configure line -data $data
    } else {
      $box.graph element configure line -data {}
    }
  }


  method set_current {num} {
    set current $num

    if {$oc != $current } {
      if {$oc} {toggle $oc}
      set oc $current
      if {$oc} {toggle $oc}
    } else {
      if {$current} {toggle $current}
      set current 0
      set oc 0
    }

    if {$current} {
      bltFlashPoint $box.graph line $current 10
    }
  }


  method rechne {} {
    global FGENDIR BITMAPDIR graph edit_exp TITLE

    if {!$do_rech} {return}
    if {!$zeilen_max($edit_exp)} {return}
    if {[eingabe_fehler]} {return}

    # Falls BW (300 A/s)
    if {[string first BW $magnet] != -1} {
      set script Fgenbw
    } else {
      # Falls Elektronenkuehler-Steerer => Fgensteer
      if {[lsearch {gun_x gun_y col_x col_y} $magnet] != -1} {
        set script Fgensteerec
      } else {
        # Falls SH11, SH13, SH39, SH41, SV32, SV34, SV38 => Fgensteerc \
        # (30 A/s), sonst Fgensteer (80 A/s)
        if {[lsearch {SH11 SH13 SH39 SH41 SV32 SV34 SV38} $magnet] != -1} {
          set script Fgensteerc
        } else {
          set script Fgensteer
        }
      }
    }

    # Anzeige, dass gerechnet wird
    manage make_nachricht $magnet "Closed Orbit Einzelview $magnet" \
           "$FGENDIR/$magnet.fgen$edit_exp wird berechnet"

    # Fgen-Typ merken
    $magnet set_rfgentyp $edit_exp e

    for {set i 1} {$i <= $zeilen_max($edit_exp)} {incr i} {
      append line \
             " [expr int($timeval($edit_exp,$i)*1000)]:$amplval($edit_exp,$i)"
    }

    set rc [catch {eval exec $script $FGENDIR/$magnet.fgen$edit_exp $line 2> \
             /tmp/error_code}]

    if {$rc} {
      if {[file exists /tmp/error_code]} {
        set fd [open /tmp/error_code r]
        set line [gets $fd]
        close $fd
        tk_dialog .dia "$TITLE" "FgenEditor $magnet: $line" \
                  @$BITMAPDIR/smily.xpm 0 Ok
        exec rm -f /tmp/error_code
      } else {
        tk_dialog .dia "$TITLE" "FgenEditor $magnet: Fehler beim Aufruf von \
                  $script" @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob file size > 0
      if {[file size $FGENDIR/$magnet.fgen$edit_exp] == 0} {
        tk_dialog .dia "$TITLE" "FgenEditor $magnet: Die Datei \
                  $FGENDIR/$magnet.fgen$edit_exp konnte nicht erzeugt werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    }

    $magnet set_aktpunkt $edit_exp 0
    $magnet set_tgesamt $edit_exp
    $magnet cmp_fgen $edit_exp
    manage destroy_nachricht $magnet

    # show_graph fuer $this, beule, wedel und orbit
    foreach elem [list $this beule wedel orbit] {
      $elem show_graph
    }
  }


  method eingabe_fehler {} {
    global BITMAPDIR edit_exp TITLE

    set akt 1

    for {set akt 1} {$akt <= $zeilen_max($edit_exp)} {incr akt} {
      if {![string length $timeval($edit_exp,$akt)]} {
        tk_dialog .dia "$TITLE" "FgenEditor $magnet: In Zeile $akt wurde kein \
                  Wert fuer die Zeit angegeben!" @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }

      if {![string length $amplval($edit_exp,$akt)]} {
        tk_dialog .dia "$TITLE" "FgenEditor $magnet: In Zeile $akt wurde kein \
                  Wert fuer die Zeit angegeben!" @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }
    return 0
  }


  method gruppen_werte {} {
    global edit_exp ampl time

    set do_rech 0

    if {!$zeilen_max($edit_exp)} {
      vinsert
    }

    if {$zeilen_max($edit_exp) > 5} {
      # Eintraege die > 5 loeschen
      while {$zeilen_max($edit_exp) > 5} {
        _delete $zeilen_max($edit_exp)
      }
    } else {
      # Falls Eintraege < 5
      if {$zeilen_max($edit_exp) < 5} {
        set_current 0

        while {$zeilen_max($edit_exp) < 5} {
          vinsert
        }
      }
    }

    set s [$magnet get_soll $edit_exp]
    set t [$magnet get_top $edit_exp]

    set z [orbit get_begin $edit_exp]
    set time($magnet,1) $z
    set timeval($edit_exp,1) $z
    set ampl($magnet,1) $s
    set amplval($edit_exp,1) $s
    database set_einzel_time_ampl $magnet $edit_exp 1 $z $s

    set z [orbit get_up $edit_exp]
    set time($magnet,2) $z
    set timeval($edit_exp,2) $z
    set ampl($magnet,2) $t
    set amplval($edit_exp,2) $t
    database set_einzel_time_ampl $magnet $edit_exp 2 $z $t

    set z [orbit get_top $edit_exp]
    set time($magnet,3) $z
    set timeval($edit_exp,3) $z
    set ampl($magnet,3) $t
    set amplval($edit_exp,3) $t
    database set_einzel_time_ampl $magnet $edit_exp 3 $z $t

    set z [orbit get_down $edit_exp]
    set time($magnet,4) $z
    set timeval($edit_exp,4) $z
    set ampl($magnet,4) $s
    set amplval($edit_exp,4) $s
    database set_einzel_time_ampl $magnet $edit_exp 4 $z $s

    set z [orbit get_end $edit_exp]
    set time($magnet,5) $z
    set timeval($edit_exp,5) $z
    set ampl($magnet,5) $s
    set amplval($edit_exp,5) $s
    database set_einzel_time_ampl $magnet $edit_exp 5 $z $s

    set do_rech 1
    summe
    rechne
  }


  method init_zeile {num zeile t a} {
    global edit_exp time ampl

    set timeval($num,$zeile) $t
    set amplval($num,$zeile) $a

    if {$num == $edit_exp} {
      set time($magnet,$zeile) $t
      set ampl($magnet,$zeile) $a
    }

    if {$zeile > $zeilen_max($num)} {
      set zeilen_max($num) $zeile
    }
  }


  public prev {} {            # Vorgaenger
    if [info exists .$this] {
      bind [.$this.time get_child entry] <Up> "focus [$prev.time get_child \
                                                     entry]"
      bind [.$this.ampl get_child entry] <Up> "focus $prev.ampl get_child \
                                                    entry]"
    }
  }


  public next {} {            # Nachfolger
    if [info exists .$this] {
      bind [.$this.time get_child entry] <Down> "focus $next.time get_child \
                                                     entry]"
      bind [.$this.ampl get_child entry] <Down> "focus $next.ampl.entry"
    }
  }


  method toggle {num} {
    if {$selected($num)} {
      $zeilenframe._$num.btn configure -relief raised
      _swap $num grey80 black
      set selected($num) 0
    } else {
      $zeilenframe._$num.btn configure -relief sunken
      _swap $num red grey80
      set selected($num) 1
    }
  }

  method _swap {num fg bg} {
    $zeilenframe._$num.btn config -foreground $bg
    $zeilenframe._$num.btn config -background $fg
  }


  method makeline {num} {
    global summe

    set line $zeilenframe._$num

    frame $line -relief ridge -borderwidth 1m
    pack $line -side top -anchor nw

    button $line.btn -text $num -width 5 -anchor w -command \
           "$this set_current $num" -height 1
    label $line.summe -relief raised -textvariable \
          summe($magnet,$num) -width 10 -anchor w

    Value $line.time -variable time($magnet,$num) -limit 1 -action \
          "$this newtime $num" -check "$this time_check $num"
    [$line.time get_child entry] config -width 10

    Value $line.ampl -variable ampl($magnet,$num) -limit 1 -action \
          "$this newampl $num" -check "$this ampl_check $num"
    [$line.ampl get_child entry] config -width 10

    pack $line.btn $line.time $line.summe $line.ampl -side left -anchor n

    set selected($num) 0
    set summe(magnet,$num) ""

    bind [$line.time get_child entry] <Home> "focus [$zeilenframe._1.time \
          get_child entry]"
    bind [$line.ampl get_child entry] <Home> "focus [$zeilenframe._1.ampl \
          get_child entry]"

    bind [$line.time get_child entry] <Right> "focus [$line.ampl get_child \
          entry]"
    bind [$line.ampl get_child entry] <Left> "focus [$line.time get_child \
          entry]"
  }


  method newtime {num value} {
    global edit_exp

    manage busy_hold
    set timeval($edit_exp,$num) $value
    database set_einzel_time $magnet $edit_exp $num $value
    rechne
    summe
    manage busy_release
  }


  method newampl {num value} {
    global edit_exp

    manage busy_hold
    set amplval($edit_exp,$num) $value
    database set_einzel_ampl $magnet $edit_exp $num $value
    rechne
    manage busy_release
  }

  method time_check {num args} {
    global BITMAPDIR time TITLE

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "FgenEditor $magnet: Der Wert fuer die Zeit ist \
                fehlerhaft!" @$BITMAPDIR/smily.xpm 0 Ok
      return 1
    }

    if {($val < 0) || ($val > 10000000)} {
      tk_dialog .dia "$TITLE" "FgenEditor $magnet: Der Wert fuer die Zeit muss \
                zwischen 0 und 10000000 liegen!" @$BITMAPDIR/smily.xpm 0 Ok
      return 2
    }

    set time($magnet,$num) $val
    return 0
  }


  method ampl_check {num args} {
    global BITMAPDIR ampl TITLE

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "FgenEditor $magnet: Der Wert fuer den Sollwert \
                ist fehlerhaft!" @$BITMAPDIR/smily.xpm 0 Ok
      return 1
    }

    if {($val < -100) || ($val > 100)} {
      tk_dialog .dia "$TITLE" "FgenEditor $magnet: Der Wert fuer den Sollwert \
                muss zwischen -100 und 100 liegen!" @$BITMAPDIR/smily.xpm 0 Ok
      return 2
    }

    set ampl($magnet,$num) $val
    return 0
  }


  method save_object {fout savelist} {
    global max_exp edit_exp time ampl

    for {set i 1} {$i <= $max_exp} {incr i} {
      # falls i in savelist
      if {[string first $i $savelist] != -1} {
        puts $fout "$this set_zeilenmax $i $zeilen_max($i)"

        for {set j 1} {$j <= $zeilen_max($i)} {incr j} {
          puts $fout "$this set_timeval $i $j $timeval($i,$j); \
                      $this set_amplval $i $j $amplval($i,$j)"
        }

        if {$i == $edit_exp} {
          for {set j 1} {$j <= $zeilen_max($i)} {incr j} {
            puts $fout "global time; set time($magnet,$j) $time($magnet,$j); \
                        global ampl; set ampl($magnet,$j) $ampl($magnet,$j)"
            puts $fout "$this set_selected $j 0"
          }
        }
      }
    }
  }


  method set_edit_exp {{num ""}} {
    global edit_exp time ampl

    if {[info exists zeilenframe] && [winfo exists $zeilenframe]} {
      if {$current} {
        set_current $current
      }
    }

    if {[string length $num]} {
      set old_index $edit_exp
      set neu_index $num

      for {set i 1} {$i <= $zeilen_max($neu_index)} {incr i} {
        set_timeval $edit_exp $i $timeval($num,$i)
        set_amplval $edit_exp $i $amplval($num,$i)
      }
    } else {
      set old_index [group get_old_editexp]
      set neu_index $edit_exp
    }

    for {set i 1} {$i <= $zeilen_max($neu_index)} {incr i} {
      set time($magnet,$i) $timeval($edit_exp,$i)
      set ampl($magnet,$i) $amplval($edit_exp,$i)
      set selected($i) 0
    }

    if {[info exists zeilenframe]} {
      for {set i $zeilen_max($old_index)} {$i > $zeilen_max($neu_index)} \
                                                               {incr i -1} {
        if {[winfo exists $zeilenframe._$i]} {
          destroy $zeilenframe._$i
        }
      }

      if {[winfo exists $zeilenframe]} {
        for {set i [expr $zeilen_max($old_index) + 1]} {$i <= \
                               $zeilen_max($neu_index)} {incr i} {
          makeline $i
        }

        if {[string length $num]} {
          set zeilen_max($edit_exp) $zeilen_max($num)
        }

        summe
        show_graph
      }
    }
  }


  method uebernehmen {to from} {
    global edit_exp time ampl

    # Falls to edit_exp
    if {($to == $edit_exp) && [info exists zeilenframe] && [winfo exists \
                                                            $zeilenframe]} {
      if {$current} {
        set_current $current
      }
    }

    for {set i 1} {$i <= $zeilen_max($from)} {incr i} {
      set_timeval $to $i $timeval($from,$i)
      set_amplval $to $i $amplval($from,$i)
    }

    # Falls to editiertes Experiment
    if {$to == $edit_exp} {
      for {set i 1} {$i <= $zeilen_max($from)} {incr i} {
        set time($magnet,$i) $timeval($from,$i)
        set ampl($magnet,$i) $amplval($from,$i)
        set selected($i) 0
      }

      if {[info exists zeilenframe] && [winfo exists $zeilenframe]} {
        for {set i $zeilen_max($to)} {$i > $zeilen_max($from)} {incr i -1} {
          destroy $zeilenframe._$i
        }

        for {set i [expr $zeilen_max($to) + 1]} {$i <= $zeilen_max($from)} \
                                                                    {incr i} {
          makeline $i
        }

        set zeilen_max($to) $zeilen_max($from)
        summe
        show_graph
      } else {
        set zeilen_max($to) $zeilen_max($from)
      }
    } else {
      set zeilen_max($to) $zeilen_max($from)
    }
  }


  method update_orbit_einzel {} {
    global edit_exp time ampl

    for {set i 1} {$i <= $zeilen_max($edit_exp)} {incr i} {
      set time($magnet,$i) $timeval($edit_exp,$i)
      set ampl($magnet,$i) $amplval($edit_exp,$i)
      set selected($i) 0
    }

    if {[info exists zeilenframe] && [winfo exists $zeilenframe]} {
      summe
      show_graph
    }
  }


  method set_begin {exp wert} {
    global edit_exp time ampl

    set current 0
    set timeval($exp,1) $wert
    set amplval($exp,1) [$magnet get_soll $exp]
    database set_einzel_time_ampl $magnet $exp 1 $timeval($exp,1) \
             $amplval($exp,1)

    if {$exp == $edit_exp} {
      set time($magnet,1) $timeval($exp,1)
      set ampl($magnet,1) $amplval($exp,1)
      set selected(1) 0
    }
  }


  method set_up {exp wert} {
    global edit_exp time ampl

    set timeval($exp,2) $wert
    set amplval($exp,2) [$magnet get_top $exp]
    database set_einzel_time_ampl $magnet $exp 2 $timeval($exp,2) \
             $amplval($exp,2)

    if {$exp == $edit_exp} {
      set time($magnet,2) $timeval($exp,2)
      set ampl($magnet,2) $amplval($exp,2)
      set selected(2) 0
    }
  }


  method set_top {exp wert} {
    global edit_exp time ampl

    set timeval($exp,3) $wert
    set amplval($exp,3) [$magnet get_top $exp]
    database set_einzel_time_ampl $magnet $exp 3 $timeval($exp,3) \
             $amplval($exp,3)

    if {$exp == $edit_exp} {
      set time($magnet,3) $timeval($exp,3)
      set ampl($magnet,3) $amplval($exp,3)
      set selected(3) 0
    }
  }


  method set_down {exp wert} {
    global edit_exp time ampl

    set timeval($exp,4) $wert
    set amplval($exp,4) [$magnet get_soll $exp]
    database set_einzel_time_ampl $magnet $exp 4 $timeval($exp,4) \
             $amplval($exp,4)

    if {$exp == $edit_exp} {
      set time($magnet,4) $timeval($exp,4)
      set ampl($magnet,4) $amplval($exp,4)
      set selected(4) 0
    }
  }


  method set_end {exp wert} {
    global edit_exp time ampl

    set timeval($exp,5) $wert
    set amplval($exp,5) [$magnet get_top $exp]
    database set_einzel_time_ampl $magnet $exp 5 $timeval($exp,5) \
             $amplval($exp,5)

    if {$exp == $edit_exp} {
      set time($magnet,5) $timeval($exp,5)
      set ampl($magnet,5) $amplval($exp,5)
      set selected(5) 0
    }
  }


  method set_timeval {exp zeile val} {
    set timeval($exp,$zeile) $val
    database set_einzel_time $magnet $exp $zeile $val
  }


  method set_amplval {exp zeile val} {
    set amplval($exp,$zeile) $val
    database set_einzel_ampl $magnet $exp $zeile $val
  }


  method get_box {} {return $box}
  method set_zeilenmax {num val} {set zeilen_max($num) $val}
  method set_selected {num val} {set selected($num) $val}
  method set_graphsel {args} {}
  method get_current {} {return $current}


  protected box
  protected do_rech 1
  public current 0
  public magnet ""
  protected amplval
  protected timeval
  protected zeilen_max
  protected zeilenframe ""
  protected oc 0
  protected selected

  # Maximale Anzahl moeglicher Zeilen
  protected MaxZeilen 25
}
