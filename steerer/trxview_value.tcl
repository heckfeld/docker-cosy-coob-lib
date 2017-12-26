# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/trxview_value.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class trxview_class {

  constructor {config} {
    makepanel
  }


  destructor {}

  method config {config} {}


  method makepanel {} {
    global stop akt_event_type akt_event_adr akt_event_val WORKSPACE bfont

    toplevel .$this
    bind .$this <Destroy> {[string range %W 1 end] delete}
    wm title .$this "Timing-Receiver [string range $this 4 end]"
    wm minsize .$this 1 1
    wm geometry .$this 480x370
    wm command .$this $WORKSPACE

    frame .$this.menu -relief raised -bd 2
    pack .$this.menu -side top -fill x

    menubutton .$this.menu.file -menu .$this.menu.file.m -text File
    menu .$this.menu.file.m
    .$this.menu.file.m add command -label Quit -command "$this quit"
    pack .$this.menu.file -side left -padx 10

    label .$this.lname -text "Timing-Receiver [string range $this 4 end]" \
          -font $bfont
    pack .$this.lname -anchor w -padx 10

    frame .$this.row1
    frame .$this.row2
    frame .$this.row3
    frame .$this.row4
    pack .$this.row1 .$this.row2 .$this.row3 .$this.row4 -side top \
         -fill both -expand 1 -in .$this -pady 5

    # Stop und Reset
    radiobutton .$this.stop -text Stop -command "$this button_stop" -variable \
                stop($timing) -value 1 -width $buttonwidth
    button .$this.state -text Status -command "$this button_status" -width \
           $buttonwidth
    pack .$this.stop .$this.state -in .$this.row1 -side left -padx 10 -expand \
         1 -anchor w

    # Start und Download
    radiobutton .$this.start -text Start -command "$this button_start" \
                -variable stop($timing) -value 0 -width $buttonwidth
    button .$this.download -text Download -command "$this button_download" \
           -width $buttonwidth
    pack .$this.start .$this.download -in .$this.row2 -side left -padx 10 \
         -expand 1 -anchor w

    # Listen
    frame .$this.box1
    frame .$this.box2
    pack .$this.box1 .$this.box2 -side left -in .$this.row3 -fill both \
         -expand 1 -padx 10

    # Time Records
    menubutton .$this.mtrecords -text "Time Records" -menu \
               .$this.mtrecords.m -relief raised
    menu .$this.mtrecords.m
    .$this.mtrecords.m add command -label "add Record" -command \
                       "$this add_record"
    .$this.mtrecords.m add command -label "remove Record" -command \
                       "$this remove_record"
    .$this.mtrecords.m add command -label "Remove all" -command \
                       "$this remove_all"

    # Liste fuer Time-Records
    SelectBox_B1 .$this.strecords
    .$this.strecords config -mode single -width 11 -action \
                     "$this select_strecords"
    pack .$this.mtrecords .$this.strecords -in .$this.box1 -anchor w

    # Mittlere Liste
    menubutton .$this.dummy -state disabled
    ListBox .$this.slog -width 35
    pack .$this.dummy .$this.slog -in .$this.box2 -anchor w

    # Event Type, Event Adr und Value
    frame .$this.row4.box1
    frame .$this.row4.box2
    frame .$this.row4.box3
    pack .$this.row4.box1 .$this.row4.box2 .$this.row4.box3 -side left \
         -in .$this.row4 -padx 10 -expand 1 -anchor w

    # Event Type
    frame .$this.row4.box1.row1
    frame .$this.row4.box1.row2
    pack .$this.row4.box1.row1 .$this.row4.box1.row2 -side top -fill both \
         -expand 1 -in .$this.row4.box1

    radiobutton .$this.row4.box1.row1.t1 -text T1 -variable \
                akt_event_type($this) -value t1 -command "$this set_type"
    radiobutton .$this.row4.box1.row1.t2 -text T2 -variable \
                akt_event_type($this) -value t2 -command "$this set_type"
    radiobutton .$this.row4.box1.row1.st -text ST -variable \
                akt_event_type($this) -value st -command "$this set_type"
    pack .$this.row4.box1.row1.t1 .$this.row4.box1.row1.t2 \
         .$this.row4.box1.row1.st -side left -expand 1 -side left -anchor w

    label .$this.row4.box1.row2.ltype -text "Event Type"
    pack .$this.row4.box1.row2.ltype  -expand 1

    # Event Adr
    Value .$this.adr -variable akt_event_adr($this) -check "$this adr_check" \
          -action "$this adr_return" -limit 1
    [.$this.adr get_child entry] config -width 10
    label .$this.ladr -text "Event Adr"
    pack .$this.adr .$this.ladr -in .$this.row4.box2 -expand 1

    # Value
    Value .$this.val -variable akt_event_val($this) -check "$this val_check" \
          -action "$this val_return" -limit 1
    [.$this.val get_child entry] config -width 10
    label .$this.lval -text "Value"
    pack .$this.val .$this.lval -in .$this.row4.box3 -expand 1
  }


  method init {} {
    .$this.strecords config -list [$timing get_timerecords]

    unset_text
    # Text in rechter Liste
    foreach elem [$timing get_timerecords] {
      # Typ, Adresse und Wert dem Timerecord zuweisen
      set index [lsearch [$timing get_timerecords] $elem]
      set event [lindex [$timing get_setting] $index]
      set_event $elem $event

      set_text $elem
    }
  }


  method set_event {tr event} {
    set event_type($tr) [string range $event 0 1]
    set event [string range $event 3 end]
    set blank [string last " " $event]
    set event_adr($tr) [string range $event 0 [expr $blank -1]]
    set event_val($tr) [string range $event [expr $blank +1] end]
  }


  method select_strecords {elem mode} {
    global akt_event_type akt_event_adr akt_event_val

    if {[string compare $mode "on"] == 0} {
      set akt_event_type($this) $event_type($elem)
      set akt_event_adr($this) $event_adr($elem)
      set akt_event_val($this) $event_val($elem)
    } else {
      set akt_event_type($this) ""
      set akt_event_adr($this) ""
      set akt_event_val($this) ""
    }
  }


  method set_type {} {
   global akt_event_type BITMAPDIR TITLE

    set elem [.$this.strecords get selected]

    if {$elem != ""} {
      set event_type($elem) $akt_event_type($this)
      set_text $elem
    } else {
      set akt_event_type($this) -1
      tk_dialog .dia "$TITLE" "$timing: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method adr_check {args} {
    global BITMAPDIR akt_event_adr TITLE

    if {![llength [.$this.strecords get selected]]} {
      tk_dialog .dia "$TITLE" "$timing: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "$timing: Fehler im Adresswert!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 2
    }

    if {[string compare $args $val]} {
      set akt_event_adr($this) $val
    }

    return 0
  }


  method adr_return {val} {
    set elem [.$this.strecords get selected]
    set event_adr($elem) $val
    set_text $elem
  }


  method val_check {args} {
    global BITMAPDIR akt_event_val TITLE

    if {![llength [.$this.strecords get selected]]} {
      tk_dialog .dia "$TITLE" "$timing: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "$timing: Fehler im Wert!" @$BITMAPDIR/smily.xpm \
                0 OK
      return 2
    }

    if {[string compare $args $val]} {
      set akt_event_val($this) $val
    }

    return 0
  }


  method val_return {val} {
    set elem [.$this.strecords get selected]
    set event_val($elem) $val
    set_text $elem
  }


  method add_record {{num ""}} {
    global akt_event_type akt_event_adr akt_event_val

    set recordlist [.$this.strecords get all]

    if {$num == ""} {
      # finden des ersten Freien Index
      set index 1
      set found 0

      while {!$found} {
        set num [format "%03d" $index]
        if {[lsearch $recordlist Tr$num] == -1} {
          set found 1
        } else {
          incr index
        }
      }
    }

    lappend recordlist Tr$num
    .$this.strecords config -list $recordlist

    if {![info exists event_type(Tr$num)]} {
      set event_type(Tr$num) -1
    }

    set akt_event_type($this) $event_type(Tr$num)

    if {![info exists event_adr(Tr$num)]} {
      set event_adr(Tr$num) -1
    }

    set akt_event_adr($this) $event_adr(Tr$num)

    if {![info exists event_val(Tr$num)]} {
      set event_val(Tr$num) 0
    }

    set akt_event_val($this) $event_val(Tr$num)

    .$this.strecords select entry Tr$num on
    set_text Tr$num
  }


  method remove_record {} {
    global akt_event_type akt_event_adr akt_event_val BITMAPDIR TITLE

    set elem [.$this.strecords get selected]

    if {$elem != ""} {
      set recordlist [.$this.strecords get all]
      set index [lsearch $recordlist $elem]
      set recordlist [lreplace $recordlist $index $index]

      .$this.strecords config -list $recordlist

      # Gesetzte Werte fuer den Timerecord loeschen
      if {[info exists event_type($elem)]} {
        unset event_type($elem)
      }

      if {[info exists event_adr($elem)]} {
        unset event_adr($elem)
      }

      if {[info exists event_val($elem)]} {
        unset event_val($elem)
      }

      set akt_event_type($this) ""
      set akt_event_adr($this) ""
      set akt_event_val($this) ""

      remove_text $elem
    } else {
      tk_dialog .dia "$TITLE" "$timing: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method remove_all {} {
    global akt_event_type akt_event_adr akt_event_val

    # Werte loeschen
    foreach elem [.$this.strecords get all] {
      if {[info exists event_type($elem)]} {
        unset event_type($elem)
      }

      if {[info exists event_adr($elem)]} {
        unset event_adr($elem)
      }

      if {[info exists event_val($elem)]} {
        unset event_val($elem)
      }

      .$this.slog config -list {}
      set oglist {}
    }

    set akt_event_type($this) ""
    set akt_event_adr($this) ""
    set akt_event_val($this) ""

    .$this.strecords config -list {}
  }


  method button_start {} {
    manage busy_hold
    $timing start
    manage busy_release
  }


  method button_stop {} {
    manage busy_hold
    $timing stop
    manage busy_release
  }


  method button_status {} {
    manage busy_hold
    $timing status
    manage busy_release
  }


  method button_download {} {
    global stop

    manage busy_hold

    set trlist [.$this.strecords get all]

    set setlist {}
    foreach elem $trlist {
      lappend setlist "$event_type($elem) $event_adr($elem) $event_val($elem)"
    }

    $timing stop
    $timing download $trlist $setlist
    manage busy_release
  }


  method quit {} {
    destroy .$this
  }



  method set_text {elem} {
    switch -- $event_type($elem) {
      t1 {set event_string "Time 1"}
      t2 {set event_string "Time 2"}
      st {set event_string "State"}
      -1 {set event_string "nicht definiert"}
    }

    set line "$elem ... $event_string at $event_adr($elem) delay\
              $event_val($elem)"

    set l [lindex [.$this.slog config -list] 4]

    # Falls Text fuer Time Record schon in der Liste enthalten
    set index [lsearch -regexp $l $elem]
    if {$index != -1} {
      set l [lreplace $l $index $index $line]
    } else {
      lappend l $line
    }

    .$this.slog config -list $l
    set loglist $l
  }


  method unset_text {} {
    .$this.slog config -list {}
  }


  method remove_text {elem} {
    set l [lindex [.$this.slog config -list] 4]
    set index [lsearch -regexp $l $elem]
    set l [lreplace $l $index $index]
    .$this.slog config -list $l
    set loglist $l
  }


  method save_object {fileid} {
    global stop

    # Falls Einzelview nicht existiert
    puts $fileid "if {\[lsearch \[itcl_info objects -class trxview_class\] \
                  $this\] == -1} {trxview_class $this -timing $timing}"

    puts $fileid "$this set_loglist [list $loglist]"

    if {[info exists event_type]} {
      foreach elem [array names event_type] {
        puts $fileid "$this unset_eventtype; $this unset_eventadr;\
                      $this unset_eventval"
        puts $fileid "$this set_eventtype $elem $event_type($elem)"
        puts $fileid "$this set_eventadr $elem $event_adr($elem)"
        puts $fileid "$this set_eventval $elem $event_val($elem)"
      }
    }

    if {[winfo exists .$this]} {
      puts $fileid "$this restore_init"
    } else {
      puts $fileid "if {\[winfo exists .$this\]} {destroy .$this}"
    }
  }


  method restore_init {} {
    .$this.strecords config -list [$timing get_timerecords]

    # Entry-Eintraege loeschen
    [.$this.adr get_child entry] delete 0 end
    [.$this.val get_child entry] delete 0 end
    .$this.slog config -list $loglist
  }


  method unset_eventtype {} {
    if {[winfo exists event_type]} {
      foreach elem [array names event_type] {
        unset event_type($elem)
      }
    }
  }


  method unset_eventadr {} {
    if {[winfo exists event_adr]} {
      foreach elem [array names event_adr] {
        unset event_adr($elem)
      }
    }
  }


  method unset_eventval {} {
    if {[winfo exists event_val]} {
      foreach elem [array names event_val] {
        unset event_val($elem)
      }
    }
  }


  method set_eventtype {elem val} {
    set event_type($elem) $val
  }


  method set_eventadr {elem val} {
    set event_adr($elem) $val
  }


  method set_eventval {elem val} {
    set event_val($elem) $val
  }


  method set_loglist {{l {}}} {set loglist $l}
  method set_tnum {t} {set tnum $t}
  method get_timing {} {return $timing}

  public timing
  protected buttonwidth 10
  protected entrywidth 10
  protected loglist {}
  protected tnum 0
  protected event_type
  protected event_adr
  protected event_val
}
