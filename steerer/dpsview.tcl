# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/dpsview.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class dpsview_class {

  constructor {config} {
    global WORKSPACE

    toplevel .$this
    bind .$this <Destroy> {[string range %W 1 end] delete}
    wm title .$this [string range $this 4 end]

    if {[manage pos_exists $this]} {
      wm geometry .$this 950x370+[expr [manage get_xpos $this] -9]+[expr \
                                             [manage get_ypos $this]-33]
    } else {
      wm geometry .$this 950x370
    }

    wm minsize .$this 1 1
    wm command .$this $WORKSPACE

    makemenu
    makepanel
    update
    manage busy_hold

    # Crate connecten
    [$magnet get_crate] connect
    push_state
  }


  destructor {}
  method config {config} {}


  method makemenu {} {
    global sollinkrement topinkrement

    set sollinkrement($this) 1
    set topinkrement($this) 1

    frame .$this.menu -relief raised -bd 2
    pack .$this.menu -fill x -in .$this

    # Menu File
    menubutton .$this.menu.file -text "File" -menu .$this.menu.file.m
    menu .$this.menu.file.m
    .$this.menu.file.m add command -label "Quit" -command "$this quit"

    # Menu Inkrement
    menubutton .$this.menu.inkrement -text "Inkrement" -menu \
               .$this.menu.inkrement.m
    menu .$this.menu.inkrement.m
    .$this.menu.inkrement.m add cascade -label "Soll" -menu \
                            .$this.menu.inkrement.m.soll
    .$this.menu.inkrement.m add cascade -label "Top" -menu \
                            .$this.menu.inkrement.m.top

    menu .$this.menu.inkrement.m.soll
    menu .$this.menu.inkrement.m.top
    set inklist [list 0.05 0.1 0.5 1 5 10]

    foreach elem $inklist {
      .$this.menu.inkrement.m.soll add radio -label $elem -value $elem \
                                   -variable sollinkrement($this)
      .$this.menu.inkrement.m.top add radio -label $elem -value $elem \
                                  -variable topinkrement($this)
    }

    pack .$this.menu.file .$this.menu.inkrement -side left -padx 10
  }


  method quit {} {
    manage set_pos $this [winfo x .$this] [winfo y .$this]
    destroy .$this
  }


  method makepanel {} {
    global aus dc samm_stoer lastfehler lokal fonts ist soll top NAME bfont

    label .$this.lname -text $magnet -font $bfont
    pack .$this.lname -anchor w -padx 10

    frame .$this.lbox -relief ridge -borderwidth 1m
    frame .$this.rbox -relief ridge -borderwidth 1m
    pack .$this.lbox .$this.rbox -expand yes -fill both -in .$this -side left

    frame .$this.box1
    frame .$this.box2 -relief ridge -borderwidth 1m
    pack .$this.box1 .$this.box2 -fill both -expand yes -in .$this.lbox \
         -padx 10 -pady 3

    # Bedienpanel
    frame .$this.lbox1
    frame .$this.rbox1
    pack .$this.lbox1 .$this.rbox1 -in .$this.box1 -side left -expand yes \
         -fill both

    # linke Spalte
    button .$this.on -text Ein -command "$this push_on" -width $buttonwidth
    button .$this.off -text Aus -command "$this push_off" -width $buttonwidth
    frame .$this.lbox1_row3
    frame .$this.lbox1_row4
    frame .$this.lbox1_row5
    pack .$this.on .$this.off .$this.lbox1_row3 .$this.lbox1_row4 \
         .$this.lbox1_row5 -in .$this.lbox1 -anchor w -pady 3

    # Soll
    Value .$this.soll -label Soll -incrbut 1 -incrvar sollinkrement($this) \
          -variable soll($magnet) -unit % -check "$magnet soll_check" \
          -action "$this soll_return" -limit 1
    [.$this.soll get_child label] config -width 4
    [.$this.soll get_child entry] config -width $sunkenwidth
    pack .$this.soll -in .$this.lbox1_row3

    # Ist
    button .$this.ist -text Reg -command "$this push_ist" -width 3
    button .$this.h1  -state disabled -relief flat -width 2
    label .$this.list -width 11 -relief sunken \
          -textvariable ist($magnet)
    label .$this.ia -text %
    pack .$this.ist -in .$this.lbox1_row4 -side left
    pack .$this.h1 -in .$this.lbox1_row4 -side left -padx 2
    pack .$this.list .$this.ia -in .$this.lbox1_row4 -side left \
          -padx 1

    # Top
    Value .$this.top -label Top -incrbut 1 -incrvar topinkrement($this) \
          -variable top($magnet) -unit % -check "$magnet top_check" \
          -action "$this top_return" -limit 1
    [.$this.top get_child label] config -width 4
    [.$this.top get_child entry] config -width $sunkenwidth
    pack .$this.top -in .$this.lbox1_row5

    # rechte Spalte
    button .$this.reset -text "Reset" -command "$this push_reset" \
           -width $buttonwidth
    button .$this.set_dc -text "DC-Mode" -command "$this push_dc" \
           -width $buttonwidth
    button .$this.startup -text Startup -command "$this push_startup" \
           -width $buttonwidth
    pack .$this.reset .$this.set_dc .$this.startup -in .$this.rbox1 -pady 3 \
         -anchor e

    # Statuspanel
    frame .$this.box2_1
    frame .$this.box2_2
    frame .$this.box2_3
    pack .$this.box2_1 .$this.box2_2 .$this.box2_3 -in .$this.box2 -expand \
         yes -fill both

    # Status Button
    button .$this.state -text Status -command "$this push_state" -width \
           $buttonwidth
    pack .$this.state -in .$this.box2_1

    frame .$this.lbox2
    frame .$this.rbox2
    pack .$this.lbox2 .$this.rbox2 -in .$this.box2_2 -side left -expand yes \
         -fill both

    checkbutton .$this.aus -text Aus -variable aus($magnet) -relief flat \
                -font $fonts
    checkbutton .$this.dc -text DC -variable dc($magnet) -relief flat \
                -font $fonts
    checkbutton .$this.lokal -text Lokal -variable lokal($magnet) \
                -relief  flat -font $fonts
    pack .$this.aus .$this.dc .$this.lokal -in .$this.lbox2  -anchor w

    checkbutton .$this.stoer -text Stoerung -variable stoer($magnet) -relief \
                flat -font $fonts
    # Falls nicht ecsteer
    if {[string first ecsteer $NAME] == -1} {
      checkbutton .$this.last -text Last -variable last($magnet) -relief flat \
                  -font $fonts
    } else {
      checkbutton .$this.last -text Positiv -variable last($magnet) -relief \
                  flat -font $fonts
    }
    pack .$this.stoer .$this.last -in .$this.rbox2  -anchor w

    label .$this.lfgenstat -text "FgenStatus" -font $fonts
    label .$this.fgenstat -textvariable fgenstat($magnet) -font $fonts
    pack .$this.lfgenstat .$this.fgenstat -in .$this.box2_3 -anchor w \
         -padx 3 -side left

    # Graphik
    orbit$magnet init .$this.rbox
  }


  method push_state {} {
    manage busy_hold
    [$magnet get_crate] get_info
    manage busy_release
  }


  method push_on {} {
    manage busy_hold
    [$magnet get_crate] set_set $magnet on
    [$magnet get_crate] get_info
    manage busy_release
  }


  method push_off {} {
    manage busy_hold
    [$magnet get_crate] set_set $magnet off
    [$magnet get_crate] get_info
    manage busy_release
  }


  method push_reset {} {
    manage busy_hold
    [$magnet get_crate] reset
    manage busy_release
  }


  method push_dc {} {
    manage busy_hold
    [$magnet get_crate] set_dc $magnet
    manage busy_release
  }


  method push_startup {} {
    global exp_fehl expok

    manage busy_hold

    set exp_fehl 0
    set expok -1

    if {[$magnet startwerte_pruefen]} {
      manage busy_release
      return
    }

    $magnet fgenlaenge_pruefen
    manage aktexperiment_pruefen
    $magnet single_go

    if {$exp_fehl} {
      set expok -1
    } else {
      incr expok
    }

    manage busy_release
  }


  method soll_return {val} {
    global TITLE BITMAPDIR

    manage busy_hold
    set soll_fehler [$magnet set_soll $val]

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Warnung!!! Die Rampe laeuft noch fuer $magnet! \
                Der Sollwert kann nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    $magnet rech_fgen

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release
  }


  method push_ist {} {
    manage busy_hold
    [$magnet get_crate] get_info
    manage busy_release
  }


  method top_return {val} {
    global edit_exp

    manage busy_hold
    $magnet set_topval $edit_exp $val
    $magnet rech_fgen

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release
  }


  method get_magnet {} {return $magnet}


  public magnet ""
  protected filename
  protected buttonwidth 20
  protected sunkenwidth 8
}
