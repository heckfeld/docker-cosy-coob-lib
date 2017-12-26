itcl_class graphic_class {
  constructor {klasse t} {
    global fonts graph max_exp

    set magnete [$klasse get_magnetegroup]
    set typ $t
    set time_list [list begin up top down end]

    set colour [list dummy red blue green pink aquamarine blueviolet \
                #c0c0c0 brown cornflowerblue darkgoldenrod1 khaki darkorchid1 \
                darksalmon gray45 lightblue orange orchid seagreen4 \
                springgreen peru violet black antiquewhite1 cadetblue coral \
                cornflowerblue cyan darkgoldenrod darkgreen darkkhaki \
                darkorange darkorchid darksalmon darkseagreen darkturquoise \
                deeppink1 deepskyblue firebrick gold greenyellow hotpink \
                lightpink lightsalmon3 lightseagreen lightskyblue \
                lightsteelblue limegreen magenta mediumorchid mediumpurple1 \
                mediumseagreen mediumslateblue mediumturquoise mistyrose black \
                black black black black black black black black black black \
                black]

    for {set i 1} {$i <= $max_exp} {incr i} {
      foreach elem $time_list {
        set ${elem}($i) 1
      }
    }
  }


  destructor {}


  method makegraph {b} {
    global graph

    # Graphik zum Anzeigen von Fgenfiles
    set graph($this) $b.graph$this
    blt_graph $graph($this) -plotbackground white -background #c0c0c0
    $graph($this) legend configure -mapped 0
    $graph($this) xaxis configure -title s
    $graph($this) yaxis configure -title %
    $graph($this) configure -width 250 -height 200
    pack $graph($this) -in $b -side bottom -anchor s -fill x

    # Wenn bisher kein Element ausgewaehlt wurde, ist das erste Element
    # der Liste, der Default, die Liste hat den Aufbau "Experiment-Nr   PoCo"
    if {![llength $graph_sel]} {
      set name [lindex $magnete 0]
      set old_graph_sel $graph_sel
      set graph_sel $name
      update_database_graphsel
    }
  }


  method makeline {magnet col} {
    global graph edit_exp

    # Zeichnen einer Kurve
    $graph($this) element create line$magnet -xdata [$magnet get_x $edit_exp] \
                  -ydata [$magnet get_y $edit_exp] -linewidth 1 -foreground $col
  }


  method graph {} {
    global BITMAPDIR WORKSPACE NAME

    # Auswahl von Kurven
    if {[winfo exists .graphlist$this]} {
      raise.tk .graphlist$this
    } else {
      toplevel .graphlist$this
      wm title .graphlist$this "Graph"
      wm geometry .graphlist$this 180x240
      wm minsize .graphlist$this 1 1
      wm command .graphlist$this $WORKSPACE

      frame .graphlist$this.row2
      frame .graphlist$this.row1 -relief ridge -borderwidth 1m
      pack .graphlist$this.row2 -side bottom -in .graphlist$this -fill both \
           -expand 1
      pack .graphlist$this.row1 -side top -in .graphlist$this -fill both \
           -expand 1

      # ok und cancel
      button .graphlist$this.graphok -text Ok -command "$this graph_ok"
      button .graphlist$this.graphcancel -text Cancel -command \
             "$this graph_cancel"
      pack .graphlist$this.graphok .graphlist$this.graphcancel \
           -in .graphlist$this.row2 -side left -padx 10

      # Falls nicht ecsteer 
      if {[string first ecsteer $NAME] == -1} {
        SelectBox_B1 .graphlist$this.select -width 18 -sorted 1
      } else {
        SelectBox_B1 .graphlist$this.select -width 18 -sorted 0
      }

      pack .graphlist$this.select -in .graphlist$this.row1

      # alle passenden Magnete in die Liste schreiben
      .graphlist$this.select config -list $magnete

      # Selektierte Magnete
      foreach elem $graph_sel {
        .graphlist$this.select select entry $elem on
      }

      set old_graph_sel $graph_sel
    }
  }


  method graph_ok {} {
    global BITMAPDIR TITLE

    set neu_graphsel [lsort [.graphlist$this.select get selected]]

    if {![llength $neu_graphsel]} {
      tk_dialog .dia "$TITLE" "$this: Es wurden keine Magnete ausgewaehlt" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set old_graph_sel $graph_sel
    set graph_sel $neu_graphsel
    update_database_graphsel
    config_legend
    show_graph
    destroy .graphlist$this
  }


  method graph_cancel {} {
    destroy .graphlist$this
  }


  method show_graph {} {
    global graph BITMAPDIR edit_exp

    # Falls graph($this) nicht existiert, fertig
    if {![info exists graph($this)] || ![winfo exists $graph($this)]} {
      return
    }

    set elemlist [$graph($this) element names]

    foreach elem $elemlist {
      $graph($this) element delete $elem
    }

    set count 0
    set graph_exist 0
    set xmax 0

    foreach elem $graph_sel {
      incr count

      # Falls akt_punkt nicht mehr aktuell
      if {![$elem get_aktpunkt $edit_exp]} {
        $elem make_punkte $edit_exp
      }

      set xmax [max $xmax [$elem get_xmax $edit_exp]]
      makeline $elem [lindex $colour $count]
    }

    if {$xmax >= 4000} {
      set xpot [expr int(log10($xmax))]
      set step [expr int([string range $xmax 0 0]/2.)]
      set step [expr round($step*pow(10,$xpot))]

      set nextstep [expr int($step + 0.5*pow(10.,$xpot))]
      if {[expr 2*$nextstep] > $xmax} {
        $graph($this) xaxis configure -stepsize $step
      } else {
        $graph($this) xaxis configure -stepsize $nextstep
      }
    }
  }


  method config_legend {} {
    global legenval

    set lmenu [virtual get_legendmenu]
    set legendval($this) 1
    destroy $lmenu
    menu $lmenu
    set count 0

    foreach elem $graph_sel {
      set col [lindex $colour [incr count]]
      $lmenu add command -label $elem -background $col -activebackground $col
    }
  }


  method set_begin {num {val ""}} {
    set begin($num) $val

    # Falls orbit
    if {![string compare $this orbit]} {
      database set_orbit begin $num $val
    } else {
      # Falls Orbit_einzel
      if {[string first orbit $this] != -1} {
        regsub "orbit" $this "" magnet
        database set_orbit_einzel $magnet begin $num $val
      }
    }
  }


  method set_up {num {val ""}} {
    set up($num) $val

    # Falls orbit
    if {![string compare $this orbit]} {
      database set_orbit up $num $val
    } else {
      # Falls Orbit_einzel
      if {[string first orbit $this] != -1} {
        regsub "orbit" $this "" magnet
        database set_orbit_einzel $magnet up $num $val
      }
    }
  }


  method set_top {num {val ""}} {
    set top($num) $val

    # Falls orbit
    if {![string compare $this orbit]} {
      database set_orbit top $num $val
    } else {
      # Falls Orbit_einzel
      if {[string first orbit $this] != -1} {
        regsub "orbit" $this "" magnet
        database set_orbit_einzel $magnet top $num $val
      }
    }

    if {[winfo exists .$this]} {
      .$this.max config -text $top($num)
    }
  }


  method set_down {num {val ""}} {
    set down($num) $val

    # Falls orbit
    if {![string compare $this orbit]} {
      database set_orbit down $num $val
    } else {
      # Falls Orbit_einzel
      if {[string first orbit $this] != -1} {
        regsub "orbit" $this "" magnet
        database set_orbit_einzel $magnet down $num $val
      }
    }
  }


  method set_end {num {val ""}} {
    set end($num) $val

    # Falls orbit
    if {![string compare $this orbit]} {
      database set_orbit end $num $val
    } else {
      # Falls Orbit_einzel
      if {[string first orbit $this] != -1} {
        regsub "orbit" $this "" magnet
        database set_orbit_einzel $magnet end $num $val
      }
    }
  }


  method set_graph_ausgewaehlt {elem} {
    set old_graph_sel $graph_sel
    set graph_sel [concat $graph_sel $elem]

    # kein Update der angezeigten liste, da Methode nur fuer Initialisierung
    # aus der Datenbank
  }


  method update_database_graphsel {} {
    global edit_exp

    # alle Elemente, die in der neuen Graphliste aber nicht in der alten waren
    foreach elem $graph_sel {
      if {[lsearch $old_graph_sel $elem] == -1} {
        $elem set_[string index $typ 0]graphwaehl $edit_exp 1
      }
    }

    # alle Elemente, die in der alten Graphliste aber nicht mehr in der neuen
    # sind
    foreach elem $old_graph_sel {
      if {[lsearch $graph_sel $elem] == -1} {
        $elem set_[string index $typ 0]graphwaehl $edit_exp 0
      }
    }
  }


  method set_graph_edit_exp {{num ""}} {
    global edit_exp graph

    set old_graph_sel {}
    set graph_sel {}
    set initial [string index $typ 0]

    foreach elem $magnete {
      if {[$elem get_${initial}graphwaehl $edit_exp]} {
        set graph_sel [concat $graph_sel $elem]
      }
    }

    # Falls graph_sel leer, auf erstes ausgewaehltes Element setzen
    if {![llength $graph_sel]} {
      set old_graph_sel $graph_sel
      set graph_sel [lindex $magnete 0]
      update_database_graphsel
    }

    # Falls Fenster mit Liste existiert
    if {[winfo exists .graphlist$this]} {
      .graphlist$this.select select reset

      foreach elem $graph_sel {
        .graphlist$this.select select entry $elem on
      }
    }

    if {[info exists graph($this)] && [winfo exists $graph($this)]} {
      config_legend
      show_graph
    }
  }


  method set_graphsel {args} {
    set graph_sel {}

    foreach elem $args {
      # Falls elem in magnete
      if {[lsearch $magnete $elem] != -1} {
        lappend graph_sel $elem
      }
    }
  }

  method set_beginval {num {val ""}} {set begin($num) $val}
  method set_upval {num {val ""}} {set up($num) $val}
  method set_topval {num {val ""}} {set top($num) $val}
  method set_downval {num {val ""}} {set down($num) $val}
  method set_endval {num {val ""}} {set end($num) $val}


  protected entrywidth 8
  protected begin
  protected up
  protected top
  protected down
  protected end
  protected graph_sel {}
  protected old_graph_sel {}
  protected colour
  protected lmenu
  protected typ
  protected time_list {}
  protected magnete {}
}
