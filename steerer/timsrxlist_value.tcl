# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/timsrxlist_value.tcl,v 1.3 2014/09/16 12:42:44 tine Exp $
itcl_class timsrxlist_class {

  constructor {g} {
    set gruppe $g

    set event_typ(1) 1
    unset event_typ(1)
    set trxlist [lsort [itcl_info objects -isa trx_class]]
  }

  destructor {}


  method init {} {
    manage busy_hold

    foreach elem $trxlist {
      $elem connect
    }

    # Falls timsrxlist noch nicht existiert
    if {![winfo exists .$this]} {
      makepanel
    } else {
      raise.tk .$this
    }

    pruefe_start_stop
    manage busy_release
  }


  method restore_init {} {
    init

    # Liste der Timing Records
    .$this.strecords config -list $time_records

    # Mittlere Liste
    .$this.slog config -list $loglist

    set save_sel $list_sel

    # Timing-Receiver Selektieren
    .$this.stimsrxlist select reset

    foreach elem $save_sel {
      .$this.stimsrxlist select entry $elem on
    }

    pruefe_start_stop
  }


  method makepanel {} {
    global stop akt_event_type akt_event_adr akt_event_val TITLE WORKSPACE

    toplevel .$this
    wm title .$this "TimsRxList $TITLE"
    wm geometry .$this 650x380
#    wm minsize .$this 1 1
    wm command .$this $WORKSPACE

    frame .$this.menu  -relief raised -bd 2
    pack .$this.menu -side top -fill x

    menubutton .$this.menu.file -menu .$this.menu.file.m -text File
    menu .$this.menu.file.m
    .$this.menu.file.m add command -label Quit -command "$this quit"
    pack .$this.menu.file -side left -padx 10

    frame .$this.row1 
    frame .$this.row2 
    frame .$this.row3
    frame .$this.row4
    pack .$this.row1 .$this.row2 .$this.row3 .$this.row4 -side top \
         -fill both -expand yes -in .$this -padx 10 -pady 5

    # Stop und Status
    radiobutton .$this.stop -text Stop -command "$this button_stop" -variable \
                stop($this) -value 1 -width $buttonwidth
    button .$this.state -text Status -command "$this button_status" -width \
           $buttonwidth
    pack .$this.stop .$this.state -in .$this.row1 -side left -padx 10 \
         -expand yes -anchor w

    # Start und Download
    radiobutton .$this.start -text Start -command "$this button_start" \
                -variable stop($this) -value 0 -width $buttonwidth 
    button .$this.download -text Download -command "$this button_download \
           \[.$this.stimsrxlist get selected\]" -width $buttonwidth
    pack .$this.start .$this.download -in .$this.row2 -side left -padx 10 \
         -expand yes -anchor w

    # Listen
    frame .$this.box1 
    frame .$this.box2 
    frame .$this.box3
    pack .$this.box1 .$this.box2 .$this.box3 -side left -in .$this.row3 \
         -fill both -expand 1 -padx 10

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
    .$this.strecords config  -mode single -width 11 -action \
                     "$this select_strecords" -list $time_records
    pack .$this.mtrecords .$this.strecords -in .$this.box1 -anchor w

    # Mittlere Liste
    menubutton .$this.dummy -state disabled
    ListBox .$this.slog -list $loglist -width 35
    pack .$this.dummy .$this.slog -in .$this.box2 -anchor w

    # TimS Rx List
    label .$this.mtimsrxlist -text "TimS Rx List" -width 15
    SelectBox_B1 .$this.stimsrxlist
    .$this.stimsrxlist config -width 15 -list $trxlist \
                       -action "$this select_timsrxlist"
    pack .$this.mtimsrxlist .$this.stimsrxlist -in .$this.box3 -anchor w

    foreach elem $list_sel {
      .$this.stimsrxlist select entry $elem on
    }

    # Event Type, Event Adr und Value
    frame .$this.row4.box1
    frame .$this.row4.box2
    frame .$this.row4.box3
    pack .$this.row4.box1 .$this.row4.box2 .$this.row4.box3 -side left \
         -in .$this.row4 -padx 10 -expand 1 -anchor w

    # Event Type
    frame .$this.row4.box1.row1
    frame .$this.row4.box1.row2
    pack .$this.row4.box1.row1 .$this.row4.box1.row2 -side top -fill both\
         -expand yes -in .$this.row4.box1

    radiobutton .$this.row4.box1.row1.t1 -text T1 -variable \
                akt_event_type($this) -value t1 -command "$this set_type"
    radiobutton .$this.row4.box1.row1.t2 -text T2 -variable \
                akt_event_type($this) -value t2 -command "$this set_type"
    radiobutton .$this.row4.box1.row1.st -text ST -variable \
                akt_event_type($this) -value st -command "$this set_type"
    pack .$this.row4.box1.row1.t1 .$this.row4.box1.row1.t2 \
         .$this.row4.box1.row1.st -expand yes -side left

    label .$this.row4.box1.row2.ltype -text "Event Type" 
    pack .$this.row4.box1.row2.ltype -expand yes 

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


  method select_strecords {elem mode} {
    global akt_event_type akt_event_adr akt_event_val

    set time_records [.$this.strecords get all]

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


  method select_timsrxlist {trx mode} {
    global stop

    # Netzgeraet in Datenbank an- bzw. abwaehlen
    if {![string compare $mode on]} {
      database set_timing_waehl $trx 1

      # Falls Element noch nicht in list_sel anhaengen
      if {[lsearch $list_sel $trx] == -1} {
        lappend list_sel $trx
      }
    } else {
      database set_timing_waehl $trx 0

      # Falls Element in list_sel entfernen
      set index [lsearch $list_sel $trx]
      if {$index != -1} {
        set list_sel [lreplace $list_sel $index $index]
      }
    }

    # Es muss ueberprueft werden, ob alle angewaehlten Timing-Receiver
    # den gleichen Status haben
    pruefe_start_stop
  }


  method pruefe_start_stop {} {
    global stop

    set tr [.$this.stimsrxlist get selected]

    if {[llength $tr]} {
      set all_start 1
      set all_stop 1

      foreach elem $tr {
        if {$stop($elem) != 0} {
          set all_start 0
        }

        if {$stop($elem) != 1} {
          set all_stop 0
        }
      }

      if {$all_start} {
        set stop($this) 0
      } else {
        if {$all_stop} {
          set stop($this) 1
        } else {
          set stop($this) 2
        }
      }
    } else {
      set stop($this) 2
    }
  }


  method set_type {} {
   global akt_event_type BITMAPDIR TITLE

    set elem [.$this.strecords get selected]

    if {$elem != ""} {
      database set_record $elem $akt_event_type($this) $event_adr($elem) \
               $event_val($elem)
      set event_type($elem) $akt_event_type($this)
      set_text $elem
    } else {
      set akt_event_type($this) -1
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method adr_check {args} {
    global BITMAPDIR akt_event_adr TITLE

    if {![llength [.$this.strecords get selected]]} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "TimsRxList: Fehler im Adresswert!" \
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
    database set_record $elem $event_type($elem) $val $event_val($elem)
    set event_adr($elem) $val
    set_text $elem
  }


  method val_check {args} {
    global BITMAPDIR akt_event_val TITLE

    if {![llength [.$this.strecords get selected]]} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[catch {expr $args} val]} {
      tk_dialog .dia "$TITLE" "TimsRxList: Fehler im Wert!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 2
    }

    if {[string compare $args $val]} {
      set akt_event_val($this) $val
    }

    return 0
  }


  method val_return {val} {
    set elem [.$this.strecords get selected]
    database set_record $elem $event_type($elem) $event_adr($elem) $val
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

    database set_record Tr$num -1 -1 0

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
      database remove_record $elem
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
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde kein Record ausgewaehlt!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method remove_all {} {
    global akt_event_type akt_event_adr akt_event_val

    database remove_all

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
      set loglist {}
    }

    set akt_event_type($this) ""
    set akt_event_adr($this) ""
    set akt_event_val($this) ""

    .$this.strecords config -list {}
  }


  method button_start {} {
    global BITMAPDIR TITLE

    manage busy_hold

    database set_tim_stop_start 0

    set sel [lsort [.$this.stimsrxlist get selected]]

    # Falls Liste Leer
    if {[llength $sel] == 0} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde kein Element aus der \
                TimsRxList ausgewaehlt!" @$BITMAPDIR/smily.xpm 0 Ok
    } else {
      foreach elem $sel {
        $elem start
      }
    }

    manage busy_release
  }


  method button_stop {} {
    global BITMAPDIR TITLE

    manage busy_hold

    database set_tim_stop_start 1

    set sel [lsort [.$this.stimsrxlist get selected]]

    # Falls Liste Leer
    if {[llength $sel] == 0} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde keine Elemente aus der \
                TimsRxList ausgewaehlt!" @$BITMAPDIR/smily.xpm 0 Ok
    } else {
      foreach elem $sel {
        $elem stop
      }
    }

    manage busy_release
  }


  method button_status {} {
    global BITMAPDIR TITLE

    manage busy_hold

    set sel [lsort [.$this.stimsrxlist get selected]]

    # Falls Liste Leer
    if {[llength $sel] == 0} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde keine Elemente aus der \
                TimsRxList ausgewaehlt!" @$BITMAPDIR/smily.xpm 0 Ok
    } else {
      foreach elem $sel {
        $elem status
      }
    }

    manage busy_release
  }


  method button_download {liste} {
    global stop BITMAPDIR TITLE

    manage busy_hold

    # Falls Liste Leer
    if {[llength $liste] == 0} {
      tk_dialog .dia "$TITLE" "TimsRxList: Es wurde keine Elemente aus der \
                TimsRxList ausgewaehlt!" @$BITMAPDIR/smily.xpm 0 Ok
    } else {
      set trlist [lsort [.$this.strecords get all]]
      set setlist {}

      foreach elem $trlist {
        lappend setlist "$event_type($elem) $event_adr($elem) $event_val($elem)"
      }

      set stop($this) 1
      set liste [lsort $liste]

      foreach elem $liste {
        $elem stop
        $elem download $trlist $setlist
      }

      foreach elem $liste {
        if {[winfo exists .view$elem]} {
          view$elem init
        }
      }
    }
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


  method remove_text {elem} {
    set l [lindex [.$this.slog config -list] 4]
    set index [lsearch -regexp $l $elem]
    set l [lreplace $l $index $index]
    .$this.slog config -list $l
    set loglist $l
  }



  method save_object {fileid} {
    global stop

    puts $fileid "$this set_timerecords [list $time_records]"
    puts $fileid "$this set_timerecordschanged $time_records_changed"
    puts $fileid "$this set_loglist [list $loglist]"
    puts $fileid "$this set_listsel [list $list_sel]"

    puts $fileid "$this unset_eventtype; $this unset_eventadr; \
                  $this unset_eventval"

    if {[info exists event_type]} {
      foreach elem [array names event_type] {
        puts $fileid "$this set_eventtype $elem $event_type($elem)"
        puts $fileid "$this set_eventadr $elem $event_adr($elem)"
        puts $fileid "$this set_eventval $elem $event_val($elem)"
      }
    }

    # Timing-Receiver in alten Zustand bringen
    foreach elem [lsort [itcl_info objects -class trx_class]] {
      $elem save_object $fileid
    }

    if {[info exists stop($this)]} {
      puts $fileid "global stop; set stop($this) $stop($this)"
    }

    if {[winfo exists .$this]} {
      puts $fileid "$this restore_init"
    } else {
      puts $fileid "if {\[winfo exists .$this\]} {destroy .$this}"
    }
  }


  method unset_eventtype {} {
    if {[info exists event_type]} {
      foreach elem [array names event_type] {
        unset event_type($elem)
      }
    }
  }


  method unset_eventadr {} {
    if {[info exists event_adr]} {
      foreach elem [array names event_adr] {
        unset event_adr($elem)
      }
    }
  }


  method unset_eventval {} {
    if {[info exists event_val]} {
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


  method timsrxlist_alle {} {
    .$this.stimsrxlist select all
  }

  method timsrxlist_clear {} {
    .$this.stimsrxlist select reset
  }


  method data_init {s} {
    global stop TITLE

    if {[manage is_no_db_boolean $s]} {
      tk_dialog .dia "$TITLE" "Der Wert ob in der TimsRxList die \
                Timing-Receiver gestartet oder gestopt sind, ist fehlerhaft \
                ($s). Er wird auf false gesetzt! (Die Timing-Receiver sind \
                gestopt)" @$BITMAPDIR/smily.xpm 0 Ok
      set s f
      database set_tim_stop_start 0
    }

    if {"$s" == "t"} {
      set stop($this) 1
    } else {
      set stop($this) 0
    }

    set time_records {}
    set loglist {}
    set n 0
  }


  method tr_init {tr typ adr val} {
    lappend time_records $tr
    set event_type($tr) $typ
    set event_adr($tr) $adr
    set event_val($tr) $val

    # Loglist
    switch -- $event_type($tr) {
      t1 {set event_string "Time 1"}
      t2 {set event_string "Time 2"}
      st {set event_string "State"}
      -1 {set event_string "nicht definiert"}
    }

    lappend loglist "$tr ... $event_string at $event_adr($tr) delay\
            $event_val($tr)"

    set n [expr [max $n [string range $tr 2 end]]]
  }


  method append_listsel {elem} {
    lappend list_sel $elem
  }


  method set_listsel {l} {
    set old_listsel $list_sel

    # Ueberpruefen, ob auch alle Timing-Receiver existieren
    set list_sel {}
    
    foreach elem $l {
      if {[lsearch $trxlist $elem] != -1} {
        lappend list_sel $elem
      } else {
        set neu_name [$elem get_neuname]
        if {[string length $neu_name]} {
          # 01.02.2013: Das hier sieht ganz nach einem Fehler aus !!!
          #lappend list_sel $neuname
          lappend list_sel $neu_name
        }
      }
    }
  }


  method set_tnum {t} {set tnum $t}
  method set_timerecords {{t {}}} {set time_records $t}
  method get_timerecords {} {return $time_records}
  method get_timerecordschanged {} {return $time_records_changed}
  method set_timerecordschanged {t} {set time_records_changed $t}
  method set_loglist {{l {}}} {set loglist $l}
  method get_trxlist {} {return $trxlist}
  method set_trxlist {args} {}
  method set_oldtrxlist {args} {}
  method get_event_type {elem} {return $event_type($elem)}
  method get_event_adr {elem} {return $event_adr($elem)}
  method get_event_val {elem} {return $event_val($elem)}
  

  protected buttonwidth 10
  protected entrywidth 10
  protected num "000"
  protected tnum 0
  protected trxlist {} 
  protected gruppe
  protected event_type
  protected event_adr
  protected event_val
  protected time_records {}
  protected loglist {} 
  protected time_records_changed 0
  protected list_sel {}
  protected n 0
}
