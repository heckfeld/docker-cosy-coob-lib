# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/member.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class member_class {

  constructor {magnetname crat bbox} {
    global dc aus fehler poco_nready DISABLEDFOREGROUND ist bfont neg soll \
           top rnr enr NAME fgen_alt edit_exp title

    set magnet $magnetname
    set crate $crat

    set box $bbox

    frame $box.row1
    frame $box.row2
    frame $box.row3
    frame $box.row4
    frame $box.row4a
    frame $box.row5
    frame $box.row6
    frame $box.row7
    pack $box.row1 $box.row2 $box.row3 $box.row4 $box.row4a $box.row5 \
         $box.row6 $box.row7 -fill both -expand yes -in $box -padx 10

    # buttonwidth
    set buttonwidth 11

    # Magnete
    # Bestimmen des zugehoerigen Magnetennamens
    menubutton $box.row1.lname -textvariable title($magnet) -font $bfont \
               -menu $box.row1.lname.m
    menu $box.row1.lname.m
    $box.row1.lname.m add command -label "Null setzen" -command \
                      "$this push_null"
    pack $box.row1.lname -side left

    # ein/aus-Anzeige und DC-Anzeige
    checkbutton $box.row2.caus -text "Aus" -variable aus($magnet) \
                -relief flat
    checkbutton $box.row2.cdc -text "DC" -variable dc($magnet) \
                -relief flat
    pack $box.row2.caus -side left
    pack $box.row2.cdc -side left -padx 32

    # Fehleranzeige
    # Falls nicht ecsteer
    if {[string first ecsteer $NAME] == -1} {
      set fframe $box.row3
    } else {
      frame $box.row3.obox
      frame $box.row3.ubox
      pack $box.row3.obox $box.row3.ubox -anchor w
      set fframe $box.row3.obox

      checkbutton $box.row3.ubox.cpositiv -text Positiv -variable last($magnet) \
                  -relief flat
      pack $box.row3.ubox.cpositiv -side left -anchor w
    }

    checkbutton $fframe.cfehler -text "Fehler" -variable fehler($magnet) \
                -relief flat
    label $fframe.ldummy
    checkbutton $fframe.cstartup -text "Startup!" -variable \
                fgen_alt($magnet,$edit_exp) -relief raised \
                -command "$this startup" -width 8
    bind $fframe.cstartup <Any-Enter> {tk_butEnter %W}
    bind $fframe.cstartup <Any-Leave> {tk_butLeave %W}
    bind $fframe.cstartup <1> {tk_butDown %W}
    bind $fframe.cstartup <ButtonRelease-1> {tk_butUp %W}
    pack $fframe.cfehler -side left
    pack $fframe.ldummy -side left -padx 7
    pack $fframe.cstartup -side left

    # Status Fgen
    checkbutton $box.row4.crechok -text "Rech. Ok" -variable rechok($magnet)\
                -relief flat
    checkbutton $box.row4.crampok -text "Rampe Ok" -variable rampok($magnet)\
                -relief flat
    pack $box.row4.crechok $box.row4.crampok -side left

    # Anzahl Rampen und Experimentnummer
    button $box.row4a.rnr -text "R-Nr" -command "$this push_rnr"
    label $box.row4a.lrnr -textvariable rnr($magnet) -anchor w -width 8
    button $box.row4a.enr -text "E-Nr" -command "$this push_enr"
    label $box.row4a.lenr -textvariable enr($magnet) -anchor w -width 1
    pack $box.row4a.rnr $box.row4a.lrnr $box.row4a.enr $box.row4a.lenr -side \
         left

    set einheit %

    # Sollstrom
    Value $box.row5.soll -label Soll -unit $einheit -incrbut 1 -incrvar \
                         sollinkrement(group) -check "$magnet soll_check" \
                         -action "$this soll_return" -variable soll($magnet) \
                         -limit 1
    [$box.row5.soll get_child entry] config -width $sunkenwidth
    [$box.row5.soll get_child label] config -width 4 -anchor w
    pack $box.row5.soll -anchor w

    # Ist
    button $box.row6.bist -text Reg -command "manage busy_hold; \
                           [$magnet get_crate] get_info; manage busy_release" \
                           -width 3
    button $box.row6.h1 -state disabled -relief flat -width 2
    label $box.row6.list -relief sunken -width 10 -textvariable \
                         ist($magnet)
    label $box.row6.ieinheit -text $einheit
    pack $box.row6.bist -side left
    pack $box.row6.h1 -side left -padx 2
    pack $box.row6.list $box.row6.ieinheit -side left

    # Top-Strom
    Value $box.row7.top -label Top -unit $einheit -incrbut 1 -incrvar \
                        topinkrement(group) -check "$magnet top_check" \
                        -action "$this top_return" -variable top($magnet) \
                        -limit 1
    [$box.row7.top get_child entry] config -width $sunkenwidth
    [$box.row7.top get_child label] config -width 4 -anchor w
    pack $box.row7.top -anchor w

    if {[[$magnet get_crate] get_rampenfehler $magnet]} {
      set_rampenfehler
    }
  }


  destructor {}


  method soll_return {val} {
    global TITLE BITMAPDIR

    manage busy_hold
    set soll_fehler [$magnet set_soll $val]

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Warnung!!! Die Rampe laeuft noch fuer $magnet! \
                Der Sollwert kann nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    # Fgenfile neu rechnen
    $magnet rech_fgen

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release
  }


  method top_return {val} {
    manage busy_hold

    # Top-Wert fuer den Magneten setzen
    $magnet set_top $val

    # Fgenfile neu rechnen
    $magnet rech_fgen

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release
  }


  method push_einaus {} {
    global aus

    manage busy_hold
    $crate get_info

    if {$aus($magnet)} {
      $magnet set_on
    } else {
      $magnet set_off
    }

    $crate get_info
    manage busy_release
  }


  method push_rnr {} {
    manage busy_hold
    $crate get_info
    manage busy_release
  }


  method push_enr {} {
    manage busy_hold
    $crate get_info
    manage busy_release
  }


  method set_rampenfehler {} {
    $box.row4a.lrnr config -bg red
  }


  method reset_rampenfehler {} {
    global background

    $box.row4a.lrnr config -bg $background
  }



  method update_startup {} {
    global edit_exp

    $fframe.cstartup config -variable fgen_alt($magnet,$edit_exp)
  }


  method startup {} {
    global startup_count edit_exp

    $magnet cmp_fgen $edit_exp

    if {[$magnet startwerte_pruefen]} {
      return
    }

    $magnet fgenlaenge_pruefen
    manage aktexperiment_pruefen

    set no_startup 1

    foreach elem [itcl_info objects -isa crate_class] {
      if {$startup_count($elem)} {
        set no_startup 0
      }
    }

    if {$no_startup} {
      manage busy_hold

      blt_busy release .group
      blt_busy hold .group.menu
      blt_busy hold .group.row0a

      # Alle Startup-Buttons freigeben
      foreach elem [lsort [itcl_info objects -isa member_class]] {
        set frame [$elem get_box]
        blt_busy release $frame
        blt_busy hold $frame.row1
        blt_busy hold $frame.row4a
        blt_busy hold $frame.row5
        blt_busy hold $frame.row6
        blt_busy hold $frame.row7
      }
    }

    incr startup_count($crate)
    $magnet single_go
  }


  method set_state {state} {
    global aus fehler poco_nready DISABLEDFOREGROUND neg

    if {[string first "nor" $state] != -1} {
      set foreground [option get . foreground Foreground]
    } else {
      set foreground $DISABLEDFOREGROUND
    }

    $box.row1.lname configure -foreground $foreground

    # Fallst State normal
    if {[string first "nor" $state] != -1} {
      $box.row2.caus configure -state $state -variable aus($magnet)
      $box.row2.cdc configure -state $state -variable dc($magnet)
      $fframe.cfehler configure -state $state -variable fehler($magnet)
      $fframe.cstartup configure -state $state -variable startup($magnet)
      $box.row4.crechok configure -state $state -variable rechok($magnet)
      $box.row4.crampok configure -state $state -variable rampok($magnet)
    } else {
      $box.row2.caus configure -state $state -variable 0
      $box.row2.cdc configure -state $state -variable 0
      $box.row3.cfehler configure -state $state -variable 0
      $fframe.cstartup configure -state $state -variable 0
      $box.row4.crechok configure -state $state -variable 0
      $box.row4.crampok configure -state $state -variable 0
    }

    $box.row4a.rnr config -foreground $foreground -state $state
    $box.row4a.lrnr config -foreground $foreground
    $box.row4a.enr config -foreground $foreground -state $state
    $box.row4a.lenr config -foreground $foreground
    [$box.row5.soll get_child label] configure -foreground $foreground
    [$box.row5.soll get_child incrmin] configure -foreground $foreground \
                                       -state $state
    [$box.row5.soll get_child entry] configure -foreground $foreground \
                                     -state $state
    [$box.row5.soll get_child incrmax] configure -foreground $foreground \
                                       -state $state
    [$box.row5.soll get_child unit] configure -foreground $foreground

    $box.row6.bist configure -state $state
    $box.row6.list configure -foreground $foreground
    $box.row6.ieinheit configure -foreground $foreground

    [$box.row7.top get_child label] configure -foreground $foreground
    [$box.row7.top get_child incrmin] configure -foreground $foreground -state \
                                      $state
    [$box.row7.top get_child entry] configure -foreground $foreground -state \
                                    $state
    [$box.row7.top get_child incrmax] configure -foreground $foreground -state \
                                      $state
    [$box.row7.top get_child unit] configure -foreground $foreground
  }


  method push_null {} {
    global TITLE BITMAPDIR

    manage busy_hold
    set rc [$magnet set_null]

    if {$rc} {
      tk_dialog .dia "$TITLE" "Warnung!!! Die Rampe laeuft noch fuer $magnet! \
                Der Sollwert kann nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release
  }


  method get_box {} {return $box}
  method get_crate {} {return $crate}

###### mike ######
  method set_soll { value } {
    global soll
    if [$magnet soll_check $value] { return 1 }
    set soll($magnet) $value
    soll_return $value
    return 0
  }
##################

  protected magnet
  protected crate
  protected box
  protected sunkenwidth 7
  protected fframe
}
