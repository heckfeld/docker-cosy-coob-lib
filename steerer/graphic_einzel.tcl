itcl_class graphic_einzel_class {
  constructor {m} {
    global fonts graph max_exp

    set magnet $m
    set time_list [list begin up top down end]

    for {set i 1} {$i <= $max_exp} {incr i} {
      foreach elem $time_list {
        set ${elem}($i) 1
      }
    }
  }


  destructor {}


  method makegraph {b} {
    global graph edit_exp

    # Graphik zum Anzeigen von Fgenfiles
    set graph($this) $b.graph$this
    blt_graph $graph($this) -plotbackground white -background #c0c0c0
    $graph($this) legend configure -mapped 0
    $graph($this) xaxis configure -title s
    $graph($this) yaxis configure -title %
    $graph($this) configure -width 250 -height 200
    pack $graph($this) -in $b -side bottom -anchor s -fill x
  }


  method makeline {} {
    global graph edit_exp

    # Zeichnen einer Kurve
    $graph($this) element create line -xdata [$magnet get_x $edit_exp] \
                  -ydata [$magnet get_y $edit_exp] -linewidth 1 -foreground red
  }


  method show_graph {} {
    global graph FGENDIR BITMAPDIR edit_exp

    # Falls graph($this) nicht existiert, fertig
    if {![info exists graph($this)] || ![winfo exists $graph($this)]} {
      return
    }

    set elemlist [$graph($this) element names]

    foreach elem $elemlist {
      $graph($this) element delete $elem
    }

    set graph_exist 0
    set xmax 0

    # Falls akt_punkt nicht mehr aktuell
    if {![$magnet get_aktpunkt $edit_exp]} {
      $magnet make_punkte $edit_exp
    }

    set xmax [max $xmax [$magnet get_xmax $edit_exp]]
    makeline

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
  protected lmenu
  protected time_list {}
  protected magnet ""
}
