# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/group.tcl,v 1.9 2015/11/27 16:27:07 tine Exp $
itcl_class group_class {

  constructor {key config} {
    global sollinkrement topinkrement

    set name $key
    set sollinkrement($this) 1
    set topinkrement($this) 1

    # Toplevel-Widget fuer Orbitoptimierung
    set orbitopt_widget .orbitopt$this
    set parent_window .$this
  }

  destructor {}

  method config {config} {}


  method init {args} {
    global edit_exp

    # alle Netzgeraete connecten
    foreach elem $crates {
      $elem connect
    }

    # Falls Gruppenwidget noch nicht existiert
    if {![winfo exists .$this]} {
      makepanel
    } else {
      raise.tk .$this
    }

    update
    group_refresh
    manage busy_hold

    # Beulen- und Wedel-Fenster
    if {[beule get_exist $edit_exp] && ![beule is_displayed]} {
      beule init
    } else {
      if {![beule get_exist $edit_exp] && [beule is_displayed]} {
        beule quit
      }
    }

    if {[wedel get_exist $edit_exp] && ![wedel is_displayed]} {
      wedel init
    } else {
      if {![wedel get_exist $edit_exp] && [wedel is_displayed]} {
        wedel quit
      }
    }

    manage busy_release
  }


  method makepanel {} {
    global sollinkrement topinkrement explist NAME WORKSPACE edit_exp max_exp

    # Bestimmung der Aufteilung in Zeilen und Spalten
    set magnetenum [llength $magnete_group]

    # Falls nicht ecsteer
    if {[string first ecsteer $NAME] == -1} {
      # Bestimmung der Aufteilung in Zeilen und Spalten
      set framesnum [expr $magnetenum + 2]

      if {$framesnum > 4} {
        set spalten 6
        set zeilen [expr $framesnum/$spalten]

        if {[expr $spalten * $zeilen] < $framesnum} {
          incr zeilen
        }
      } else {
        set zeilen 1
        set spalten $framesnum
      }
    } else {
      set zeilen [expr $magnetenum/2]
      set spalten [expr $magnetenum/$zeilen]

      if {[expr $spalten * $zeilen] < $magnetenum} {
        incr spalten
      }
    }

    toplevel .$this

    bind .$this <Destroy> {
      set klasse [string range %W 1 end]

      # Member loeschen
      foreach elem [$klasse get_magnetegroup] {
        member$elem delete
      }
    }

    wm minsize .$this 1 1
    wm title .$this $name
    wm command .$this $WORKSPACE
    blt_busy .$this

    # Menu
    set mframe .$this.menu
    frame $mframe -relief raised -bd 2
    pack $mframe -side top -fill x
    blt_busy $mframe

    frame $mframe.file
    pack $mframe.file -side left -padx 10

    menubutton $mframe.file.button -menu $mframe.file.button.m -text File
    menu $mframe.file.button.m
    $mframe.file.button.m add command -label Quit -command "$this quit"
    pack $mframe.file.button

    frame $mframe.group
    pack $mframe.group -side left -padx 10

    menubutton $mframe.group.button -menu $mframe.group.button.m -text Gruppe
    menu $mframe.group.button.m
    $mframe.group.button.m add command -label Ein -command "$this group_on"
    $mframe.group.button.m add command -label Aus -command "$this group_off"
    $mframe.group.button.m add command -label DC-Mode -command "$this group_dc"
    $mframe.group.button.m add separator
    $mframe.group.button.m add command -label Status -command \
                           "$this group_refresh"
    $mframe.group.button.m add separator
    $mframe.group.button.m add command -label Reset -command \
                           "$this group_reset"
    $mframe.group.button.m add separator
    $mframe.group.button.m add command -label "Soll-Werte auf 0 setzen" \
                           -command "$this group_soll0"
    $mframe.group.button.m add command -label "Top-Werte auf 0 setzen" \
                           -command "$this group_top0"
    $mframe.group.button.m add separator
    $mframe.group.button.m add command -label \
                           "Top-Werte in Soll-Werte uebernehmen" \
                           -command "$this group_top2soll"
    $mframe.group.button.m add command -label \
                           "Soll-Werte in Top-Werte uebernehmen" \
                           -command "$this group_soll2top"
    pack $mframe.group.button

    # Menu Inkrement
    frame $mframe.inkrement
    pack $mframe.inkrement -side left -padx 10

    menubutton $mframe.inkrement.button -text Inkrement -menu \
               $mframe.inkrement.button.m
    menu $mframe.inkrement.button.m
    $mframe.inkrement.button.m add cascade -label Soll -menu \
                               $mframe.inkrement.button.m.soll
    $mframe.inkrement.button.m add cascade -label Top -menu \
                               $mframe.inkrement.button.m.top

    set inklist [list 0.05 0.1 0.5 1 5 10]
    menu $mframe.inkrement.button.m.soll
    menu $mframe.inkrement.button.m.top

    foreach elem $inklist {
      $mframe.inkrement.button.m.soll add radio -label $elem -variable \
                                      sollinkrement($this) -value $elem
      $mframe.inkrement.button.m.top add radio -label $elem -variable \
                                     topinkrement($this) -value $elem
    }

    pack $mframe.inkrement.button

    # Menu Startup
    frame $mframe.startup
    pack $mframe.startup -side left -padx 10

    button $mframe.startup.button -text Startup  -command "$this go" \
           -relief flat
    pack $mframe.startup.button -side left -padx 10

    # Menu Theorie (nur bei steererh und steererv)
    if {![string first steer $NAME]} {
      button $mframe.theorie -text Theorie -command "$this theorie" -relief flat
      pack $mframe.theorie -side left -padx 10
    }

    # Menu Special Funktions
    frame $mframe.spec_functions
    pack $mframe.spec_functions -side left -padx 10

    menubutton $mframe.spec_functions.button -text "Spezielle Funktionen" \
               -menu $mframe.spec_functions.button.m
    menu $mframe.spec_functions.button.m
    $mframe.spec_functions.button.m add command -label Wedeln -command \
                                    "$this call_wedel"
    $mframe.spec_functions.button.m add command -label Beule -command \
                                    "$this call_beule"
    pack $mframe.spec_functions.button

    # Menu aus Modellrechnung uebernehmen
    frame $mframe.modell
    pack $mframe.modell -side left -padx 10

    menubutton $mframe.modell.button -text Modell -menu $mframe.modell.button.m
    menu $mframe.modell.button.m
    $mframe.modell.button.m add command -label "Aus corrector uebernehmen" \
                            -command "$this modell corrector"
    pack $mframe.modell.button

    ###
    # Menu Orbitoptimierung
    frame $mframe.orbitopt
    pack $mframe.orbitopt -side left -padx 10
    button $mframe.orbitopt.button \
       -text Orbitoptimierung \
       -command "$this orbitoptimierung" \
       -relief flat
    pack $mframe.orbitopt.button -side left -padx 10
    # Ende
    ###

    # Menu inspect
    menubutton .$this.menu.inspect -text Inspect -menu .$this.menu.inspect.m
    menu .$this.menu.inspect.m
    .$this.menu.inspect.m add command -label FgenInit -command \
                              "$this fgeninit"
    .$this.menu.inspect.m add command -label "Sync-Mode" -command \
                              "$this sync"
    .$this.menu.inspect.m add command -label Download -command \
                              "$this download"
    .$this.menu.inspect.m add command -label RCLC -command \
                              "$this rclc"
    .$this.menu.inspect.m add command -label Download123 -command \
                              "$this download123"
    .$this.menu.inspect.m add command -label RLEXP -command \
                              "$this rlexp"
    .$this.menu.inspect.m add command -label "Start (ohne Timing)" -command \
                              "$this start_ohne_timing"
    .$this.menu.inspect.m add command -label "Stop (ohne Timing)" -command \
                              "$this stop_ohne_timing"
    .$this.menu.inspect.m add command -label "MCNT" -command \
                              "$this mcnt"
    .$this.menu.inspect.m add command -label Reset -command \
                              "$this reset"
    .$this.menu.inspect.m add command -label Disconnect -command \
                              "$this disconnect"
#    pack .$this.menu.inspect -side right -padx 10

    # 1. Zeile enthaelt Experimentfolge
    frame .$this.row0
    pack .$this.row0 -side top -expand yes -fill both -padx 10

    label .$this.row0.lexplist -text "Experimentfolge: "
    label .$this.row0.explist -textvariable explist
    pack .$this.row0.lexplist .$this.row0.explist -side left

    # 2. Zeile enhaelt experiment
    frame .$this.row0a
    frame .$this.row0b
    pack .$this.row0a .$this.row0b -side top -expand yes -fill both -padx 10

    label .$this.row0a.lakt_exp -text "aktuelles Experiment: " -width 18
    pack .$this.row0a.lakt_exp -side left

    for {set i 1} {$i <= $max_exp} {incr i} {
      radiobutton .$this.row0a.akt_exp$i -text $i -variable akt_exp -value $i \
                  -command "$this set_akt_exp" -width 3
      pack .$this.row0a.akt_exp$i -side left -padx 1
    }

    frame .$this.row0b.box1
    frame .$this.row0b.box2

    if {"$NAME" != "ecsteer"} {
      pack .$this.row0b.box1 -side left -expand yes -fill both
      pack .$this.row0b.box2 -side left -expand yes -fill both -padx 10
    } else {
      pack .$this.row0b.box1 .$this.row0b.box2 -side top -anchor w -expand yes \
           -fill both
    }

    label .$this.row0b.ledit_exp -text "editiertes Experiment: " -width 18
    pack .$this.row0b.ledit_exp -side left -in .$this.row0b.box1

    for {set i 1} {$i <= $max_exp} {incr i} {
      radiobutton .$this.row0b.edit_exp$i -text $i -variable edit_exp \
                  -value $i -command "$this set_edit_exp" -width 3
      pack .$this.row0b.edit_exp$i -side left -padx 1 -in .$this.row0b.box1
    }

    menubutton .$this.row0b.uebernehmen -text "Werte aus Experiment \
               uebernehmen" -menu .$this.row0b.uebernehmen.m -relief raised
    menu .$this.row0b.uebernehmen.m

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {$i != $edit_exp} {
        .$this.row0b.uebernehmen.m add command -label "Experiment $i" \
                                   -command "$this uebernehmen $edit_exp $i"
      }
    }

    pack .$this.row0b.uebernehmen -side left -in .$this.row0b.box2 \
         -anchor w

    # Falls ecsteer
    if {[string first ecsteer $NAME] != -1} {
      # Box fuer Magnete und Closed Orbit
      frame .$this.box
      pack .$this.box -side top -expand yes -fill both -padx 10

      # linke Box fuer Magnete und rechte Box fuer Closed Orbit
      frame .$this.lbox
      frame .$this.rbox
      pack .$this.lbox .$this.rbox -side left -expand yes -fill both

      for {set i 1} {$i <= $zeilen} {incr i} {
        frame .$this.row$i
        pack .$this.row$i -side top -expand yes -fill both -in .$this.lbox \
             -pady 10
      }
    } else {
      for {set i 1} {$i <= $zeilen} {incr i} {
        frame .$this.row$i
        pack .$this.row$i -side top -expand yes -fill both
      }
    }

    for {set i 1} {$i <= $zeilen} {incr i} {
      for {set j 1} {$j <=$spalten} {incr j} {
        set num [expr ($i-1)*$spalten +$j]
        if {$num <= $magnetenum} {
          frame .$this.row$i.box$j
          pack  .$this.row$i.box$j -side left
          blt_busy .$this.row$i.box$j

          set magnet [lindex $magnete_group [incr num -1]]
          member_class member$magnet $magnet [$magnet get_crate] \
                                    .$this.row$i.box$j

          ### Geaendert: 3.11.03 (-> Herbert, Norbert)
          ## Falls SV10 member disabled
          ##if {[string first SV10 $magnet] != -1} {
          ##  member$magnet set_state disabled
          ##}

        } else {
          if {$num == [expr $magnetenum +1]} {
            frame .$this.row$zeilen.graphbox
            pack .$this.row$zeilen.graphbox -side left
          }
        }
      }
    }

    # Graphik
    if {[string first ecsteer $NAME] == -1} {
      $orbit init .$this.row$zeilen.graphbox
    } else {
      $orbit init .$this.rbox
    }
  }


  method quit {} {
    destroy .$this
  }


  method group_on {} {
    global BITMAPDIR TITLE

    manage busy_hold

    foreach elem $crates {
      set rc [$elem set_dc]

      if {$rc} {
        tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer $elem! Das \
                  Einschalten wird abgebrochen!" @$BITMAPDIR/smily.xpm 0 Ok
        manage busy_release
      }
    }

    foreach elem $crates {
      $elem set_on
    }

    manage busy_release
  }


  method group_off {} {
    global BITMAPDIR NAME TITLE

    manage busy_hold

    set answer [tk_dialog .dia "$TITLE" "Warnung! Sollen wirklich alle \
                Netzgeraete dieses Abschnitts ausgeschaltet werden?" \
                @$BITMAPDIR/smilynice.xpm 0 Ja Nein]

    if {!$answer} {
      foreach elem $crates {
        set rc [$elem set_dc]

        if {$rc} {
          tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer $elem! Das \
                    Ausschalten wird abgebrochen!" @$BITMAPDIR/smily.xpm 0 Ok
          manage busy_release
        }
      }

      foreach elem $crates {
        $elem set_off
      }
    }

    manage busy_release
  }


  method group_refresh {} {
    manage busy_hold

    foreach elem $crates {
      $elem get_info
    }

    manage busy_release
  }


  method group_dc {} {
    global BITMAPDIR TITLE

    manage busy_hold

    foreach elem $crates {
      set rc [$elem set_dc]

      if {$rc} {
        tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer $elem! Die \
                  Ausfuehrung des Befehls wird abgebrochen!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
        manage busy_release
        return
      }
    }

    manage busy_release
  }


  method group_reset {} {
    manage busy_hold

    foreach elem $crates {
      $elem reset
      $elem get_info
    }

    manage busy_release
  }


  method group_soll0 {} {
    global soll edit_exp TITLE BITMAPDIR

    manage busy_hold
    set soll_fehler 0

    foreach elem $magnete_group {
      # Fall soll noch nicht 0 ist
      if {[expr double([$elem get_soll $edit_exp])] != 0.0} {
        set soll($elem) 0
        set rc [$elem set_soll 0]
        set soll_fehler [expr $soll_fehler || $rc]

        # Fgenfile neu rechnen
        $elem rech_fgen
      }
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer Netzgeraete! \
                Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release

  }; #group_soll0


  method group_top0 {} {
    global top edit_exp

    manage busy_hold

    foreach elem $magnete_group {
      # Fall top noch nicht 0 ist
      if {[expr double([$elem get_top $edit_exp])] != 0.0} {
        set top($elem) 0
        $elem set_top 0

        # Fgenfile neu rechnen
        $elem rech_fgen
      }
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    manage busy_release

  }; #group_top0


  method group_top2soll {} {
    global soll edit_exp TITLE BITMAPDIR

   ### Tine (27.11.15):                                       ###
   ### Warum ist das hier global ? Braucht eigentlich nicht ! ###
   # global topwert

    manage busy_hold
    set soll_fehler 0

    foreach elem $magnete_group {
      # Top-Wert lesen
      set topwert [$elem get_top $edit_exp]

      # Falls Soll-Wert noch nicht mit Top-Wert uebereinstimmt
      if {[expr double([$elem get_soll $edit_exp])] \
          != [expr double($topwert)]} {
        set soll($elem) $topwert
        set rc [$elem set_soll $topwert]
        set soll_fehler [expr $soll_fehler || $rc]

        # Fgenfile neu rechnen
        $elem rech_fgen
      }
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer Netzgeraete! \
                Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release

  }; #group_top2soll


  method group_soll2top {} {
    global top edit_exp TITLE BITMAPDIR

    manage busy_hold

    foreach elem $magnete_group {
      # Soll-Wert lesen
      set sollwert [$elem get_soll $edit_exp]

      # Falls Top-Wert noch nicht mit Soll-Wert uebereinstimmt
      if {[expr double([$elem get_top $edit_exp])] \
          != [expr double($sollwert)]} {
        set top($elem) $sollwert
        $elem set_top $top($elem)

global testbetrieb
if {$testbetrieb} {
puts "$elem set_top $top($elem)"
}
        # Fgenfile neu rechnen
        $elem rech_fgen
      }
    }

   ### Muss das hier auch gemacht werden wie in group_top2soll ??? ###
   # # show_graph fuer alle Graphen
   # foreach elem [itcl_info objects -isa graphic_class] {
   #   $elem show_graph
   # }
   ### ??? ###

    manage busy_release

  }; #group_soll2top


  method orbitopt2top {} {
    global orbitopt_file top newtop TITLE BITMAPDIR

    manage busy_hold
#global testbetrieb
#if {$testbetrieb} {
#puts "Orbitoptimierung: Daten aus $orbitopt_file($this) in Top-Werte schreiben"
#}

    # Liste der Magnete, fuer die ein neuer Top-Wert
    # in der Datei angegeben ist.
    set newtop_magnete {}

    # Datei zum Lesen oeffnen
    set fin [open "$orbitopt_file($this)" "r"]

    ### Tine: 27.11.2015                            ###
    ### Beliebige Kommentarzeilen (beginnend mit #) ###
    ### sollen ueberlesen werden koennen !!!        ###

    # Zeilen, die mit '#' beginnen, und Leerzeilen werden ignoriert
    gets $fin line
    while {![eof $fin]} {
     set line [string trim "$line"]
     if {[string length "$line"] > 0 && [string first "#" "$line"] != 0} {
      set split_list [split $line \;]

      set name [lindex $split_list 0]

      # Die Magnetnamen aus der Datei muessen an die Namen aus der GUI
      # angepasst werden !!!
      # !!! Vorsicht, die Namen in der Datei koennen auch variieren !!!

      # 9.11.2015: die neuen *.csv-Dateien enthalten
      # die Magnetnamen aus der GUI,
      # so dass eine Anpassung nicht mehr notwendig ist,
      # bzw. der Name falsch 'angepasst' wird (gun/col) !!!

      if {[string first "MSH" $name] != -1} {
#puts "MSH name=$name"
        set magnet "SH[string range $name 3 end]"

      } elseif {[string first "MSV" $name] != -1} {
#puts "MSV name=$name"
        set magnet "SV[string range $name 3 end]"

      } elseif {[string first "sh" $name] != -1} {
#puts "sh name=$name,  \"[string range $name 2 end]\""
        if {"[string range $name 2 2]" == "0"} {
          set magnet "SH[string range $name 2 end]"
        } else {
          set magnet "SH[format "%02d" [string range $name 2 end]]"
        }

      } elseif {[string first "sv" $name] != -1} {
#puts "sv name=$name,  \"[string range $name 2 end]\""
        if {"[string range $name 2 2]" == "0"} {
          set magnet "SV[string range $name 2 end]"
        } else {
          set magnet "SV[format "%02d" [string range $name 2 end]]"
        }

      } elseif {[string first "blwd" $name] != -1} {
        set magnet "BLW-D[string range $name 4 end]"

      } elseif {[string first "blw" $name] != -1} {
        set magnet "BLW[string range $name 3 end]"

      } elseif {[string first "colx" $name] != -1} {
        set magnet "col_x[string range $name 4 end]"

      } elseif {[string first "coly" $name] != -1} {
        set magnet "col_y[string range $name 4 end]"

      } elseif {[string first "gunx" $name] != -1} {
        set magnet "gun_x[string range $name 4 end]"

      } elseif {[string first "guny" $name] != -1} {
        set magnet "gun_y[string range $name 4 end]"

      } else {
        set magnet $name
      }

      # Gehoert der Magnet zu dieser GUI ???
      if {[lsearch $magnete_group $magnet] != -1} {

        # Der fuer die Orbitoptimierung verwendete Ausgangs-Top-Wert
        # wird zunaechst nicht benoetigt.
        #set old_value [lindex $split_list 1]
        #if {"$old_value" != ""} {
        #  # Das Komma in der Zahl MUSS durch einen Punkt ersetzt werden !!!
        #  set ind [string first "," $old_value]
        #  if {$ind != -1} {
        #    set old_val [string range $old_value 0 [expr $ind - 1]]
        #    append old_val "."
        #    append old_val [string range $old_value [expr $ind + 1] end]
        #    set old_value $old_val
        #  }
        #} else {
        #  set old_value 0.0
        #}

        # Der neue Top-Wert wird nur gesetzt, wenn er sich
        # vom aktuellen Top-Wert in der GUI unterscheidet !!!
        set new_value [lindex $split_list 2]

#global testbetrieb
#if {$testbetrieb} {
#puts "Name: $name ==> $magnet $new_value"
#}
        if {"$new_value" != ""} {
          # Das Komma in der Zahl MUSS durch einen Punkt ersetzt werden !!!
          set ind [string first "," $new_value]
          if {$ind != -1} {
            set new_val [string range $new_value 0 [expr $ind - 1]]
            append new_val "."
            append new_val [string range $new_value [expr $ind + 1] end]
            set new_value $new_val
          }
          lappend newtop_magnete $magnet
          set newtop($magnet) [expr $new_value]

#global testbetrieb
#if {$testbetrieb} {
#puts "             -- $magnet $newtop($magnet) (akt Top:$top($magnet)) !!!"
#}
        }
      }

     } ;# if keine Leerzeile und keine Kommentarzeile

     gets $fin line

    } ;# while
    close $fin

    if {[llength $newtop_magnete]} {
#global testbetrieb
#if {$testbetrieb} {
#puts "newtop_magnete: $newtop_magnete"
#}
      # Tabelle mit alten und neuen Topwerten
      set topwert_meldung "Neue Top-Werte aus \"$orbitopt_file($this)\":\n\n"
      append topwert_meldung [format "%-8s %8s %8s\n" Geraet Alt Neu]
      append topwert_meldung "----------------------------------\n"

      foreach elem $newtop_magnete {
        append topwert_meldung \
         [format "%-8s %8s %8s\n" $elem $top($elem) $newtop($elem)]
      }

      # Meldung, fuer welche Geraete ein neuer Top-Wert gesetzt wird !!!
      set answer [tk_dialog_max .dia 1600 $TITLE \
                              $topwert_meldung \
                              @$BITMAPDIR/smilynice.xpm \
                              1 Abbrechen Uebernehmen]

      if {$answer} {
        foreach elem $newtop_magnete {
          # Neuen Top-Wert nur setzen, wenn sich der
          # neue Wert vom aktuellen unterscheidet !!!
          if {[expr double($top($elem))] != [expr double($newtop($elem))]} {
            set top($elem) $newtop($elem)
            $elem set_top $top($elem)

#global testbetrieb
#if {$testbetrieb} {
#puts "$elem set_top $top($elem)"
#}
            # Fgenfile neu rechnen
            $elem rech_fgen
          }

        }; #foreach elem $newtop_magnete
      }; #if answer

    } else {

      # Meldung, wenn kein neuer Top-Wert fuer mindestens ein
      # Geraet dieser GUI !!!
      tk_dialog_max .dia 1600 $TITLE \
                              "\"$orbitopt_file($this)\"\nenthaelt\
                              keine passenden Top-Werte !!!" \
                              @$BITMAPDIR/smily.xpm 0 Ok

    }

    manage busy_release
    destroy $orbitopt_widget

  }; #orbitopt2top


  method delete_orbitopt_filesearch {} {
    if {[winfo exists .file$this]} {
      destroy .file$this
      fselect$this delete
    }
    grab $orbitopt_widget
  }; #delete_orbitopt_filesearch


  method orbitopt_filesearch {} {
    global TITLE

    if {![winfo exists .file$this]} {
      fileselect_class fselect$this -filter "$orbitopt_dir/*\.csv" \
                                    -parent_widget $orbitopt_widget
      fselect$this make_fileselect .file$this \
                                    "$TITLE: Orbitoptimierung (Browse)" \
                                    "$this orbitopt_fileok"
    } else {
      raise.tk .file$this
    }

  }; #orbitopt_filesearch


  # Diese Methode wird nur aus dem File-Browse-Fenster heraus aufgerufen !!!
  method orbitopt_fileok {name} {
    global orbitopt_file

    if {[orbitopt_file_check $name] == 0} {
      # Datei existiert

      # Globale Variable setzen, fuer die Anzeige im Fenster Orbitoptimierung
      set orbitopt_file($this) $name

      # hierin wird protected Variable gesetzt
      orbitopt_file_return $orbitopt_file($this)

      # Browse-Fenster fuer Auswahl schliessen
      delete_orbitopt_filesearch

    } else {
      # Fehler bei Datei (existiert nicht oder nicht lesbar) !!!
      # Eingabe sollte korrigiert werden,
      # deshalb das Browse-Fenster aktiv halten !!!

      grab .file$this
    }

  }; #orbitopt_fileok


  method startup {} {
    global exp_fehl expok

    manage busy_hold

    set exp_fehl 0
    set expok -1

    if {[startwerte_pruefen]} {
      manage busy_release
      return
    }

    fgenlaenge_pruefen
    manage aktexperiment_pruefen

    foreach elem $crates {
      $elem startup123
    }

    if {$exp_fehl} {
      set expok -1
    } else {
      incr expok
    }

    manage busy_release
  }


  method go {} {
    global stop abbruch

    manage busy_hold

    if {[startwerte_pruefen]} {
      manage busy_release
      return
    }

    fgenlaenge_pruefen
    manage aktexperiment_pruefen
    set trxlist {}

    # Timing-Receiver stoppen, falls nicht gestoppt
    foreach elem $crates {
      set trx [$elem get_trx]

      if {!$stop($trx)} {
        lappend trxlist $trx
      }
    }

    foreach elem $trxlist {
      $elem stop
    }

    set crate_ramp $crates
    set neu_crate_ramp {}

    foreach elem $crate_ramp {
      set rc [$elem sclc 0]

      if {$rc && ![[$elem get_target] get_targetfail]} {
        lappend neu_crate_ramp $elem
      }
    }

    manage busy_release
    blt_busy hold .$this.menu.startup
    set crate_ramp $neu_crate_ramp
    set startup_count [expr ($startup_count + 1) % 128]
    set abbruch($this,$startup_count) 0

    toplevel .startup_abbruch
    wm title .startup_abbruch "Warten auf Fgen OK"
    wm geometry .startup_abbruch 220x100
    button .startup_abbruch.abbruch -text Abbruch -relief groove \
           -borderwidth 3m -command "$this startup_abbruch $startup_count" \
           -height 2
    pack .startup_abbruch.abbruch -anchor c -padx 10 -pady 10

    # Falls noch Crates rampen, Zykluszeit und Zeit im Zyklus abfragen
    if {[llength $crate_ramp]} {
      set rc [catch {server sendreceive tx "timstx get_cycle_time"} ret_string]

      if {!$rc} {
        set erg [split $ret_string :]
        set akt_zeit [lindex $erg 0]
        set gesamt [lindex $erg 1]
        set diff [expr $gesamt - $akt_zeit]
        after $diff "$this go_finish $startup_count"
      }
    } else {
      go_finish $startup_count
    }
  }

   method go_finish {num} {
    global exp_fehl expok abbruch

    while {[llength $crate_ramp] && !$abbruch($this,$num)} {
      set neu_crate_ramp {}

      foreach elem $crate_ramp {
        set rc [$elem sclc 0]

        if {$rc && ![[$elem get_target] get_targetfail]} {
          lappend neu_crate_ramp $elem
        }
      }

      set crate_ramp $neu_crate_ramp
    }

    catch {destroy .startup_abbruch}

    if {$abbruch($this,$num)} {
      manage busy_release
      return
    }

    manage busy_hold
    set exp_fehl 0
    set expok -1

    foreach elem $crates {
      $elem go123
    }

    if {$exp_fehl} {
      set expok -1
    } else {
      incr expok
    }

    # falls trxlist leer
    if {![llength $trxlist]} {
      foreach elem $crates {
        lappend trxlist [$elem get_trx]
      }
    }

    # Timing-Receiver starten
    foreach elem $trxlist {
      $elem start
    }

    manage busy_release
  }


  method theorie {} {
    global TITLE BITMAPDIR

    set rc [catch {exec modell} ret_string]

    if {$rc} {
      tk_dialog .dia $TITLE $ret_string @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  ###
  method orbitoptimierung {} {
    global TITLE WORKSPACE orbitopt_file eqfont

    # Eieruhr setzen, MUSS auf jeden Fall zurueckgesetzt werden,
    # wenn das Fenster beendet wird (Abbruch oder Uebernehmen) !!!
    manage busy_hold

    if {![winfo exists $orbitopt_widget]} {
      toplevel $orbitopt_widget

      wm title $orbitopt_widget "$TITLE: Orbitoptimierung"
      wm protocol $orbitopt_widget WM_DELETE_WINDOW "$this orbitopt_abbruch"
      wm command $orbitopt_widget $WORKSPACE

      set orbitopt_file($this) $orbitopt_fileval

      # 2 Reihen
      frame $orbitopt_widget.r1
      frame $orbitopt_widget.r2
      pack $orbitopt_widget.r1 \
         -fill x -padx 10 -pady 10 -side top
      pack $orbitopt_widget.r2 \
         -padx 10 -pady 10 -side top

      # r1
      Value $orbitopt_widget.r1.val \
         -limit 1 \
         -label "aus Datei: " \
         -action "$this orbitopt_file_return" \
         -check "$this orbitopt_file_check" \
         -variable orbitopt_file($this)
      set entry [$orbitopt_widget.r1.val get_child entry]
      $entry config -width 60 -font $eqfont
      bind $entry <Escape> "destroy $orbitopt_widget"

      button $orbitopt_widget.r1.browse \
         -text Browse \
         -width 10 \
         -state disabled \
         -command "$this orbitopt_filesearch"
#global testbetrieb
#if ${testbetrieb} {
  $orbitopt_widget.r1.browse config -state normal
#}

      pack $orbitopt_widget.r1.val $orbitopt_widget.r1.browse \
         -padx 2 -pady 2 -side left

      #r2
      button $orbitopt_widget.r2.abbruch \
         -text Abbrechen \
         -width 28 \
         -command "$this orbitopt_abbruch"
      button $orbitopt_widget.r2.ok \
         -text "Uebernehmen (in Top-Werte)" \
         -width 28 \
         -command "$this orbitopt2top"

      pack $orbitopt_widget.r2.abbruch $orbitopt_widget.r2.ok \
         -side left -padx 10

      # Vorgehen aus dialog.tcl uebernommen !!
      wm withdraw $orbitopt_widget
      update idletasks

      # Patzierung des Fensters mittig im Gruppenfenster,
      # der obere Rand soll auf der Menuezeile liegen !!!
      set x [expr [winfo rootx $parent_window] \
                + [winfo width $parent_window] / 2 \
                - [winfo reqwidth $orbitopt_widget] / 2]
      if {$x < 0} {set x 0}

      set y [expr [winfo rooty $parent_window]]

      wm geometry $orbitopt_widget +$x+$y
      wm deiconify $orbitopt_widget

      grab $orbitopt_widget

    } else {

      raise.tk $orbitopt_widget
      set entry [$orbitopt_widget.r1.val get_child entry]
    }

    focus $entry

  }; #method orbitoptimierung


  method orbitopt_abbruch {} {

    # Browse Fenster fuer Orbitoptimierung
    if {[winfo exists .file$this]} {
      destroy .file$this
      fselect$this delete
    }

    # Orbitoptimierungs-Fenster
    if {[winfo exists $orbitopt_widget]} {
      destroy $orbitopt_widget
    }

    # Zuruecksetzen, was in orbitoptimierung gesetzt wurde,
    # damit die GUI wieder bedienbar wird !!!
    manage busy_release

  }; #orbitopt_abbruch


  method orbitopt_file_check {args} {
    global BITMAPDIR TITLE

    # Ueberpruefen, ob die Datei existiert und lesbar ist
    if {![file exists "$args"] || ![file readable "$args"]} {
      tk_dialog_max .dia 1600 "$TITLE" \
                              "Die Datei \"$args\" existiert nicht!" \
                              @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    return 0
  }


  method orbitopt_file_return {val} {
    set orbitopt_fileval $val
  }
  ###


  method download {} {
    manage busy_hold

    foreach elem $crates {
      $elem download
    }

    manage busy_release
  }


  method download123 {} {
    manage busy_hold

    foreach elem $crates {
      $elem download123
    }

    manage busy_release
  }


  method fgeninit {} {
    manage busy_hold

    foreach elem $crates {
      $elem fgeninit
    }

    manage busy_release
  }


  method sync {} {
    manage busy_hold

    foreach elem $crates {
      $elem set_sync
    }

    manage busy_release
  }


  method rclc {} {
    manage busy_hold

    foreach elem $crates {
      $elem rclc
    }

    manage busy_release
  }


  method rlexp {} {
    manage busy_hold

    foreach elem $crates {
      $elem rlex
    }

    manage busy_release
  }


  method start_ohne_timing {} {
    manage busy_hold

    foreach elem $crates {
      $elem start_ohne_timing
    }

    manage busy_release
  }


  method stop_ohne_timing {} {
    manage busy_hold

    foreach elem $crates {
      $elem stop_ohne_timing
    }

    manage busy_release
  }


  method mcnt {} {
    global WORKSPACE mcnt

    if {![winfo exists .mcnt$this]} {
      toplevel .mcnt$this
      wm title .mcnt$this "Anzahl der Rampen"
      wm geometry .mcnt$this 420x50
      wm command .mcnt$this $WORKSPACE

      set mcnt($this) $mcntval

      Value .mcnt$this.val -limit 1 -action "$this mcnt_return" \
            -check "$this mcnt_check" -variable mcnt($this)
      set entry [.mcnt$this.val get_child entry]
      $entry config -width 25
      bind $entry <Escape> "destroy .mcnt$this"
      pack .mcnt$this.val -padx 2 -pady 2 -side left

      button .mcnt$this.abbruch -text Abbrechen -command "destroy \
             .mcnt$this"
      pack .mcnt$this.abbruch -padx 2 -pady 2 -side left
    } else {
      raise.tk .mcnt$this
    }

    focus $entry
  }


  method mcnt_check {args} {
    global BITMAPDIR TITLE

    # Ueberpruefen ob Zahl
    if {[catch {expr $args}]} {
      tk_dialog .dia "$TITLE" "Es muss eine Zahl eingeben werden!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    return 0
  }


  method mcnt_return {val} {
    manage busy_hold

    set mcntval $val

    foreach elem $crates {
      $elem mcnt $val
    }

    destroy .mcnt$this
    manage busy_release
  }


  method call_beule {} {
    # Falls alle Parameter bekannt
    if {[$orbit eingabe_fehler] == 0} {
      $beule init
    }
  }


  method call_wedel {} {
    # Falls alle Parameter bekannt
    if {[$orbit eingabe_fehler] == 0} {
      $wedel init
    }
  }


  method disconnect {} {
    manage busy_hold

    foreach elem $crates {
      $elem disconnect
    }

    destroy .$this
    manage busy_release
  }


  method data_init {exp_string stop aktexp editexp} {
    global explist akt_exp edit_exp BITMAPDIR TITLE

    if {[manage is_no_expnum $aktexp]} {
      tk_dialog .dia "$TITLE" "Die aktuelle Experimentnummer in der \
                Oberflaeche ist fehlerhaft ($aktexp). Sie wird auf 1 \
                gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set aktexp 1
      database set_akt_exp 1
    }

    set akt_exp $aktexp
    set old_akt_exp $aktexp

    if {[manage is_no_expnum $editexp]} {
      tk_dialog .dia "$TITLE" "Die editierte Experimentnummer in der \
                Oberflaeche ist fehlerhaft ($editexp). Sie wird auf 1 \
                gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set editexp 1
      database set_edit_exp 1
    }

    set edit_exp $editexp
    set old_edit_exp $editexp

    if {[manage is_no_expstring $exp_string]} {
      tk_dialog .dia "$TITLE" "Die Experimentfolge ist fehlerhaft \
                ($exp_string)." @$BITMAPDIR/smily.xpm 0 Ok
      set exp_string ""
    }

    set old_explist $exp_string

    # Anzeige in TimsRxList
    tim data_init $stop
  }


  method data_num_init {num obegin oup otop odown oend btopstrom bbegin bup \
                        btop bdown wtopstrom wbegin wup1 wtop wdown wntop \
                        wup2 be we} {
    global BITMAPDIR TITLE

    # Zeiten fuer Orbit
    if {[catch {expr $obegin} val]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Begin-Zeit im Orbit \
                fuer Experiment $num ist fehlerhaft ($obegin). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set obegin 0
      database set_orbit begin $num 0
    }

    $orbit set_beginval $num $obegin

    if {[catch {expr $oup}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Up-Zeit im Orbit \
                fuer Experiment $num ist fehlerhaft ($oup). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set oup 0
      database set_orbit up $num 0
    }

    $orbit set_upval $num $oup

    if {[catch {expr $otop}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Top-Zeit im Orbit \
                fuer Experiment $num ist fehlerhaft ($otop). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set otop 0
      database set_orbit top $num 0
    }

    $orbit set_topval $num $otop

    if {[catch {expr $odown}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Down-Zeit im Orbit \
                fuer Experiment $num ist fehlerhaft ($odown). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set odown 0
      database set_orbit down $num 0
    }

    $orbit set_downval $num $odown

    if {[catch {expr $oend}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die End-Zeit im Orbit \
                fuer Experiment $num ist fehlerhaft ($oend). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set oend 0
      database set_orbit end $num 0
    }

    $orbit set_endval $num $oend

    $beule set_begin $num $obegin
    $beule set_up $num $oup
    $beule set_top $num $otop
    $beule set_down $num $odown
    $beule set_end $num $oend

    if {[catch {expr $btopstrom}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer den Topstrom in der Beule \
                fuer Experiment $num ist fehlerhaft ($btopstrom). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set btopstrom 0
      database set_beule btopstrom $num 0
    }

    $beule set_topstromval $num $btopstrom

    if {[catch {expr $bbegin}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Begin-Zeit in der Beule \
                fuer Experiment $num ist fehlerhaft ($bbegin). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set bbegin 0
      database set_beule bbegin $num 0
    }

    $beule set_bbeginval $num $bbegin

    if {[catch {expr $bup}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Up-Zeit in der Beule \
                fuer Experiment $num ist fehlerhaft ($bup). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set bup 0
      database set_beule bup $num 0
    }

    $beule set_bupval $num $bup

    if {[catch {expr $btop}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Top-Zeit in der Beule \
                fuer Experiment $num ist fehlerhaft ($btop). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set btop 0
      database set_beule btop $num 0
    }

    $beule set_btopval $num $btop

    if {[catch {expr $bdown}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Down-Zeit in der Beule \
                fuer Experiment $num ist fehlerhaft ($bbdown). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set bbdown 0
      database set_beule bdown $num 0
    }

    $beule set_bdownval $num $bdown

    if {[manage is_no_db_boolean $be]} {
      tk_dialog .dia "$TITLE" "Der Wert ob das Beulenfenster fuer Experiment \
                $num existiert, ist fehlerhaft ($be). Er wird auf false \
                gesetzt! (Das Fenster existiert nicht)" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set be f
      $beule set_exist beule $num 0
    }

    if {"$be" == "t"} {
      $beule set_existval $num 1
    } else {
      $beule set_existval $num 0
    }

    $wedel set_begin $num $obegin
    $wedel set_up $num $oup
    $wedel set_top $num $otop
    $wedel set_down $num $odown
    $wedel set_end $num $oend

    if {[catch {expr $wtopstrom}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer den Topstrom beim Wedeln \
               fuer Experiment $num ist fehlerhaft ($btopstrom). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wtopstrom 0
      database set_wedel wtopstrom $num 0
    }

    $wedel set_topstromval $num $wtopstrom

    if {[catch {expr $wbegin}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Begin-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wbegin). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wbegin 0
      database set_wedel wbegin $num 0
    }

    $wedel set_wbeginval $num $wbegin

    if {[catch {expr $wup1}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die erste Up-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wup1). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wup1 0
      database set_wedel wup1 $num 0
    }

    $wedel set_wup1val $num $wup1

    if {[catch {expr $wtop}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Top-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wtop). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wtop 0
      database set_wedel wtop $num 0
    }

    $wedel set_wtopval $num $wtop

    if {[catch {expr $wdown}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die Down-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wdown). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wdown 0
      database set_wedel wdown $num 0
    }

    $wedel set_wdownval $num $wdown

    if {[catch {expr $wntop}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die negative Top-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wntop). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wntop 0
      database set_wedel wntop $num 0
    }

    $wedel set_wntopval $num $wntop

    if {[catch {expr $wup2}]} {
      tk_dialog .dia "$TITLE" "Der Wert fuer die zweite Up-Zeit beim Wedeln \
                fuer Experiment $num ist fehlerhaft ($wup2). Er \
                wird auf 0 gesetzt!" @$BITMAPDIR/smily.xpm 0 Ok
      set wup2 0
      database set_wedel wup2 $num 0
    }

    $wedel set_wup2val $num $wup2

    if {[manage is_no_db_boolean $we]} {
      tk_dialog .dia "$TITLE" "Der Wert ob das Wedelfenster fuer Experiment \
                $num existiert, ist fehlerhaft ($we). Er wird auf false \
                gesetzt! (Das Fenster existiert nicht)" \
                @$BITMAPDIR/smily.xpm 0 Ok
      set we f
      $wedel set_exist wedel $num 0
    }

    if {"$we" == "t"} {
      $wedel set_existval $num 1
    } else {
      $wedel set_existval $num 0
    }
  }


  method tx_init {line} {
    global explist

    set line [lindex [split $line :] 5]
    regsub -all , $line "" explist

    if {[string length $explist] && [string compare $explist $old_explist]} {
      database set_group_explist $explist
      startup
    }
  }


  method save_object {fileid savelist} {
    global sollinkrement topinkrement

    # Inkrement
    if {[info exists sollinkrement($this)]} {
      puts $fileid "global sollinkrement; set sollinkrement($this) \
                    $sollinkrement($this)"
    }

    if {[info exists sollinkrement($this)]} {
      puts $fileid "global topinkrement; set topinkrement($this) \
                    $topinkrement($this)"
    }

    puts $fileid "$this set_old_aktexp $old_akt_exp"

    $orbit save_object $fileid $savelist
    $wedel save_object $fileid $savelist
    $beule save_object $fileid $savelist
  }


  method set_edit_exp {{do_pruefe 1}} {
    global edit_exp

    manage busy_hold

    # Falls sich alter edit_exp und neuer edit_exp unterscheiden
    if {!$do_pruefe || [string compare $edit_exp $old_edit_exp]} {
      database set_edit_exp $edit_exp

      # Werte uebernehmen anpassen
      if {[winfo exists .$this]} {
        uebernehmen_anpassen
      }

      # Orbit, Wedel und Beule
      orbit set_edit_exp
      beule set_edit_exp
      wedel set_edit_exp

      # Einzelviews
      foreach elem [itcl_info objects -isa orbit_einzel_class] {
        $elem set_edit_exp
      }

      # Member
      foreach elem [itcl_info objects -isa member_class] {
        $elem update_startup
      }

      # Sollstroeme und Topstrome
      foreach elem $magnete_group {
        $elem set_edit_exp
      }
    }

    set old_edit_exp $edit_exp
    manage busy_release
  }


  method uebernehmen_anpassen {} {
    global edit_exp max_exp

    for {set i 0} {$i < $max_exp} {incr i} {
      .$this.row0b.uebernehmen.m delete $i
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {$i != $edit_exp} {
        .$this.row0b.uebernehmen.m add command -label "Experiment $i" \
                                   -command "$this uebernehmen $edit_exp $i"
      }
    }
  }


  method set_akt_exp {} {
    global akt_exp dc BITMAPDIR TITLE

    manage busy_hold

    # Falls sich alter akt_exp und neuer akt_exp unterscheiden
    if {[string compare $akt_exp $old_akt_exp]} {
      set soll_fehler 0

      foreach elem $magnete_group {
        set neusoll [$elem get_soll $akt_exp]

        # Falls fuer elem sollval(old_akt_exp) != sollval(akt_exp)
        if {[expr double([$elem get_soll $old_akt_exp])] != [expr \
                                                 double($neusoll)]} {
          set rc 0

          if {!$dc($elem)} {
            set rc [[$elem get_crate] sclc 0]
          }

          if {$rc} {
            set soll_fehler 1
          } else {
            [$elem get_crate] send_soll $elem $neusoll
          }
        }
      }

      database set_akt_exp $akt_exp
      set old_akt_exp $akt_exp

      if {$soll_fehler} {
        tk_dialog .dia "$TITLE" "Warnung!!! Die Rampe laeuft noch fuer \
                  Netzgeraete, deren Sollwerte koennen nicht gesetzt werden!" \
                  @$BITMAPDIR/smily.xpm 0 OK
      }
    }

    manage busy_release
  }


  method uebernehmen {to from} {
    global FGENDIR soll top BITMAPDIR TITLE edit_exp

    manage busy_hold

    # editiertes Experiment auf to setzen
    set edit_exp $to
    group set_edit_exp  

    set soll_fehler 0

    # Fgenfiles kopieren
    foreach elem $magnete_group {
      if {[file exists $FGENDIR/$elem.fgen$from]} {
        set rc [catch {exec cp $FGENDIR/$elem.fgen$from \
                $FGENDIR/$elem.fgen$to} ret_string]

        if {$rc} {
           tk_dialog .dia "$TITLE" "Kopieren: $ret_string" \
                     @$BITMAPDIR/smily.xpm 0 OK
        }

        $elem set_aktpunkt $to 0
        $elem set_tgesamt $to
      }

      # Gerechnete Werte und Werte beim Download, Beulen- und Wedelscale
      $elem uebernehmen $to $from
    }

    # Orbit, Wedel und Beule
    orbit uebernehmen $to $from
    beule uebernehmen $to $from
    wedel uebernehmen $to $from

    # Einzelviews
    foreach elem [itcl_info objects -isa orbit_einzel_class] {
      $elem uebernehmen $to $from
    }

    # Sollstroeme und Topstrome
    foreach elem $magnete_group {
      # falls to editiertes Experiment
      if {$to == $edit_exp} {
        set soll($elem) [$elem get_soll $from]
        set top($elem) [$elem get_top $from]

        set rc [$elem set_soll $soll($elem)]
        set soll_fehler [expr $soll_fehler || $rc]
        $elem set_top $top($elem)
      } else {
        $elem set_sollval $to [$elem get_soll $from]
        $elem set_topval $to [$elem get_top $from]
      }
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Warnung!!! Die Rampe laeuft noch fuer \
                Netzgeraete! Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release
  }


  method modell {type} {
    global NAME MODELLDIR BITMAPDIR TITLE

    # Ueberpruefen, ob Modell-File existiert
    if {![file exists $MODELLDIR/$NAME.$type]} {
      tk_dialog_max .dia 1000 "$TITLE" "Modell: Die Datei \
                    $MODELLDIR/$NAME.$type existiert nicht!" \
                    @$BITMAPDIR/smily.xpm 0 OK
      return
    }

    # falls type = bump und neue Version (8 Zeilen)
    set neu_version 0

    if {"$type" == "bump"} {
      set rc [catch {exec cat $MODELLDIR/$NAME.$type | wc -l} lines]

      if {!$rc && $lines == 8} {
        set neu_version 9
      }
    }

    if {$neu_version} {
      make_4bump_neu
    } else {
      set fin [open $MODELLDIR/$NAME.$type r]
      gets $fin line
      set modell_list($type) {}
      set poco_list($type) {}

      while {![eof $fin]} {
        lappend modell_list($type) $line
        lappend poco_list($type) [lindex [split $line :] 0]
        gets $fin line
      }

      # Anzeige der Datei
      if {![winfo exists .modell$type]} {
        toplevel .modell$type
        wm title .modell$type "Modell $type"
   
        frame .modell$type.row1
        frame .modell$type.row2a
        frame .modell$type.row2
        frame .modell$type.row3
        pack .modell$type.row1 .modell$type.row2a .modell$type.row2 \
             .modell$type.row3 -expand 1 -fill both -pady 5

        if {[string first corrector $type] != -1} {
          button .modell$type.back -text "rueckgaengig machen" \
                 -command "$this correct_undo" -width 24 -stat disabled
          pack .modell$type.back -in .modell$type.row2a -side left -padx 10
        }

        button .modell$type.alle -text Alle -command ".modell$type.select \
               select all" -width 10
        button .modell$type.clear -text Clear -command ".modell$type.select \
                                  select reset" -width 10
        pack .modell$type.alle .modell$type.clear -side left \
                               -in .modell$type.row2 -padx 10
  
        button .modell$type.abbruch -text Beenden -command "$this \
               modell_beenden $type" -width 10
        button .modell$type.ok -text OK -command "$this modell_ok $type" \
               -width 10
        pack .modell$type.abbruch .modell$type.ok -side left \
             -in .modell$type.row3 -padx 10

        SelectBox .modell$type.select -height 10 -width 30 -sorted 0
        .modell$type.select.list config -font \
               -misc-fixed-medium-r-normal-*-14-*-*-*-*-*-*-*
        pack .modell$type.select -in .modell$type.row1 -padx 10
      } else {
        raise.tk .modell$type
      }

      .modell$type.select config -list $modell_list($type)
      .modell$type.select select all
    }
  }


  method make_4bump_neu {} {
    global MODELLDIR NAME 4bump_poco_amp 4bump_poco_winkel 4bump_amp \
           4bump_winkel bfont

    set fin [open $MODELLDIR/$NAME.bump r]
    gets $fin line
    set poco_list(bump) {}
    set count 1

    while {![eof $fin]} {
      # falls noch nicht in poco_list
      set line [split $line :]
      set poco [lindex $line 0]

      # Tine: 03/2015
      # Im Falle der ehem. BLW-Steerer ist der Name aus der Modellrechnung
      # verschieden von dem in der aktuellen GUI verwendeten !!!
      # D.h. poco muss ggfs. korrigiert werden !!!
      # z.B. steererh.bump enthaelt SHBLW2PX --> BLW02
      #                             SHBLW3PX --> BLW03
      # z.B. steererv.bump enthaelt SVBLW1PX --> BLW01
      #                             SVBLW4PX --> BLW04

      if {[string compare "SHBLW2PX" "$poco"] == 0} {
        set poco "BLW02"
      } elseif {[string compare "SHBLW3PX" "$poco"] == 0} {
        set poco "BLW03"
      } elseif {[string compare "SVBLW1PX" "$poco"] == 0} {
        set poco "BLW01"
      } elseif {[string compare "SVBLW4PX" "$poco"] == 0} {
        set poco "BLW04"
      }

      if {$count <= 4} {
        set 4bump_poco_amp($this,$poco) [string trim [lindex $line 2]]
        set 4bump_poco_ampval($poco) $4bump_poco_amp($this,$poco)
      } else {
        set 4bump_poco_winkel($this,$poco) [string trim [lindex $line 2]]
        set 4bump_poco_winkelval($poco) $4bump_poco_winkel($this,$poco)
      }    

      set 4bump_exp [lindex $line 3]

      if {[string first direkt $line] == -1} {
        set 4bump_direkt 0
      } else {
        set 4bump_direkt 1
      }

      if {[lsearch $poco_list(bump) $poco] == -1} {
        lappend poco_list(bump) $poco
      }

      incr count
      gets $fin line
    }                 

    if {[winfo exists .modellbump]} {
      destroy .modellbump
    }

    toplevel .modellbump
    wm title .modellbump "Modell bump"
    wm minsize .modellbump 1 1

    # max_width bestimmen
    set max_len 1

    foreach elem  $poco_list(bump) {
      set max_len [max $max_len [string length $elem]] 
    }

    set max_len [expr $max_len + 3]
    set count 0

    foreach elem $poco_list(bump) {
      frame .modellbump.row$count 
      pack .modellbump.row$count -fill both -expand 1 -padx 10

      label .modellbump.lname_$elem -text $elem -width $max_len -font $bfont
      Value .modellbump.amp_$elem -limit 1 -label "Skalierungsfaktor \
             Amplitude" -variable 4bump_poco_amp($this,$elem) -check \
             "$this 4bump_poco_check amp $elem" -action "$this \
             4bump_poco_return amp $elem"
      [.modellbump.amp_$elem get_child entry] config -width 10
      Value .modellbump.winkel_$elem -limit 1 -label "  Skalierungsfaktor \
            Winkel" -variable 4bump_poco_winkel($this,$elem) -check "$this \
            bump_poco_check winkel $elem" -action "$this bump_poco_return \
            winkel $elem"
      [.modellbump.winkel_$elem get_child entry] config -width 10
      pack .modellbump.lname_$elem .modellbump.amp_$elem \
           .modellbump.winkel_$elem -side left -in .modellbump.row$count    
      incr count
    }

    Value .modellbump.amp -limit 1 -label "Amplitude" -variable \
          4bump_amp($this) -check "$this 4bump_check amp" -action "$this \
          4bump_return amp" -unit mm
    [.modellbump.amp get_child entry] config -width 10
    [.modellbump.amp get_child label] config -width 9 -anchor w
    Value .modellbump.winkel -limit 1 -label "Winkel" -variable \
          4bump_winkel($this) -check "$this 4bump_check winkel" -action "$this \
          4bump_return winkel" -unit mrad
    [.modellbump.winkel get_child entry] config -width 10
    [.modellbump.winkel get_child label] config -width 9 -anchor w
    pack .modellbump.amp .modellbump.winkel -padx 10 -pady 5 -anchor w

    frame .modellbump.buttons
    pack .modellbump.buttons -fill both -expand 1

    button .modellbump.cancel -text Abbrechen -command "destroy .modellbump" \
           -width 15
    button .modellbump.do -text Ausfuehren -command "$this do_4bump_neu" \
           -width 15
    pack .modellbump.cancel .modellbump.do -side left -padx 10 -in \
         .modellbump.buttons 
  }


  method 4bump_poco_check {type poco args} {
    global TITLE BITMAPDIR

    if {[catch {expr $args} val]} {
      if {"$type" == "amp"} {
        set bezeich "die Amplitude"
      } else {
        set bezeich "den Winkel"
      }

      tk_dialog .dia "$TITLE" "Modell: Der Skalierungsfaktor fuer $bezeich ist \
                fehlerhaft!" @$BITMAPDIR/smily.xpm 0 OK 
      return 1
    }

    if {[string compare $args $val]} {
      set 4bump_poco_${type}($this,$poco) $val
    }

    return 0
  }


  method 4bump_poco_return {type poco val} {
    set 4bump_poco_${type}val($poco) $val
  }


  method 4bump_check {type args} {
    global TITLE BITMAPDIR

    if {[catch {expr $args} val]} {
      if {"$type" == "amp"} {
        set bezeich "die Amplitude"
      } else {
        set bezeich "den Winkel"
      }

      tk_dialog .dia "$TITLE" "Modell: Der Wert fuer $bezeich ist fehlerhaft!" \
                @$BITMAPDIR/smily.xpm 0 OK
      return 1
    }

    if {[string compare $args $val]} {
      set 4bump_${type}($this) $val
    }

    return 0
  }


  method 4bump_return {type val} {
    set 4bump_${type}val $val
  }                   


  method do_4bump_neu {} {
    # alten Topstrom merken
    beule set_oldtopstrom $4bump_exp

    # topval auf 1 setzen
    beule update_topstrom $4bump_exp 1

    # Falls direkt, fuer alle Netzgeraete, die nicht in poco_list sind,
    # Beulenscale auf 0 setzen
    if {$4bump_direkt} {
      set mode direkt

      foreach elem $magnete_group {
        if {[lsearch $poco_list(bump) $elem] == -1} {
          $elem set_beulenscale $4bump_exp 0
          beule update_beulenscale $elem $4bump_exp

          # Falls fgentyp beule ist, fgenfile neu rechnen
          if {![string compare [$elem get_rfgentyp $4bump_exp] b]} {
            beule rechne $4bump_exp $elem
          }
        }
      }
    } else {
      # additiv
      # Fuer alle Netzgeraete, die nicht in poco_list sind, Beulenscale
      # auf Topstrom 1 umrechnen
      set mode additiv

      foreach elem $magnete_group {
        if {[lsearch $poco_list(bump) $elem] == -1} {
          $elem set_beulenscale $4bump_exp [expr [beule get_oldtopstrom \
                $4bump_exp] * [$elem get_beulenscale $4bump_exp]]
          beule update_beulenscale $elem $4bump_exp
        }
      }
    }

    set soll_fehler 0

    foreach elem $poco_list(bump) {
      # Falls Element existiert
      if {[lsearch $magnete_group $elem] != -1} {
        set val [expr $4bump_poco_ampval($elem) * $4bump_ampval + \
                 $4bump_poco_winkelval($elem) * $4bump_winkelval]
        set rc [$elem modell beule $val $4bump_exp $mode]
        set soll_fehler [expr $soll_fehler || $rc]
      }
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Modell: Die Rampe laeuft noch fuer Netzgeraete! \
                Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }
  }


  method modell_beenden {type} {
    global release_all

    set release_all 1
    manage busy_release
    destroy .modell$type
  }


  method modell_ok {type} {
    global BITMAPDIR soll top FGENDIR release_all TITLE

    manage busy_hold

    set comm_fehl 0
    set soll_fehler 0
    set sel_list($type) [lsort [.modell$type.select get selected]]

    # Falls sel_list nicht leer
    if {[llength $sel_list($type)]} {
      set do_abwaehl 0
      set do_anwaehl 0
      set enum [lindex [split [lindex $modell_list($type) 0] :] 3]

      # Typ corrector
      if {![string compare $type corrector]} {
        # Zustand der Netzgeraete speichern, wegen undo
        foreach elem [lsort [itcl_info objects -isa dps_class]] {
          $elem save_werte
        }

        # Falls direkt
        if {[lsearch -regexp $modell_list($type) direkt] != -1} {
          # Netzgeraete, die nicht in poco_list vorkommen auf Null setzen
          # falls top
          if {[lsearch -regexp $modell_list($type) top] != -1} {
            foreach elem $magnete_group {
              if {[lsearch $poco_list($type) $elem] == -1} {
                $elem set_topnull $enum
              }
            }
          } else {
            foreach elem $magnete_group {
              if {[lsearch $poco_list($type) $elem] == -1} {
                set rc [$elem set_null $enum]
                set soll_fehler [expr $soll_fehler || $rc]
              }
            }
          }
        }
      } else {
        # Typ bump
        # alten Topstrom merken
        beule set_oldtopstrom $enum

        # topval auf 1 setzen
        beule update_topstrom $enum 1

        # Falls direkt, fuer alle Netzgeraete, die nicht in poco_list sind,
        # Beulenscale auf 0 setzen
        if {[lsearch -regexp $modell_list($type) direkt] != -1} {
          foreach elem $magnete_group {
            if {[lsearch $poco_list($type) $elem] == -1} {
              $elem set_beulenscale $enum 0
              beule update_beulenscale $elem $enum

              # Falls fgentyp beule ist, fgenfile neu rechnen
              if {![string compare [$elem get_rfgentyp $enum] b]} {
                beule rechne $enum $elem
              }
            }
          }
        } else {
          # additiv
          # Fuer alle Netzgeraete, die nicht in poco_list sind, Beulenscale
          # auf Topstrom 1 umrechnen
          foreach elem $magnete_group {
            if {[lsearch $poco_list($type) $elem] == -1} {
              $elem set_beulenscale $enum [expr [beule get_oldtopstrom $enum] \
                    * [$elem get_beulenscale $enum]]
              beule update_beulenscale $elem $enum
            }
          }
        }
      }
    }

    foreach l $sel_list($type) {
      set line [split $l :]
      set elem [string toupper [lindex $line 0]]
      set op [lindex $line 1]
      set val [lindex $line 2]
      set num [lindex $line 3]
      set mode [lindex $line 4]

      # Falls Element existiert
      if {[lsearch $magnete_group $elem] != -1} {
        set rc [$elem modell $op $val $num $mode]
        set soll_fehler [expr $soll_fehler || $rc]

        # Falls Ausfuehrung nicht erfolgreich
        if {![$elem get_commandok]} {
          set comm_fehl 1
        } else {
          # Zeile abwaehlen
          .modell$type.select select entry $l off
          update
        }
      } else {
        tk_dialog .dia "$TITLE" "Modell: Das Netzgeraet $elem existert nicht!" \
                  @$BITMAPDIR/smily.xpm 0 OK
      }
    }

    # Typ corrector
    if {![string compare $type corrector]} {
      .modell$type.back config -state normal
      set release_all 0
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Modell: Die Rampe laeuft noch fuer Netzgeraete! \
                Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 OK
    }

    manage busy_release
  }


  method correct_undo {} {
    global BITMAPDIR TITLE

    manage busy_hold
    set soll_fehler 0

    foreach elem [lsort [itcl_info objects -isa dps_class]] {
      set rc [$elem undo_werte]
      set soll_fehler [expr $soll_fehler || $rc]
    }

    # show_graph fuer alle Graphen
    foreach elem [itcl_info objects -isa graphic_class] {
      $elem show_graph
    }

    if {$soll_fehler} {
      tk_dialog .dia "$TITLE" "Die Rampe laeuft noch fuer Netzgeraete! \
                Deren Sollwerte koennen nicht gesetzt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release
  }


  method notstop {} {
    manage busy_hold

    foreach elem $crates {
      $elem srmp
    }

    manage busy_release
  }


  method experiment_reset {} {
    global TITLE BITMAPDIR

    manage busy_hold

    set sclc_fehler 0

    foreach elem $crates {
      set rc [$elem sclc 0]

      if {!$rc} {
        $elem rlex
      } else {
        set sclc_fehler 1
      }
    }

    if {$sclc_fehler} {
      tk_dialog .dia "$TITLE" "Die Rampe lief noch fuer einige Netzgeraete! \
                Das Zuruecksetzen konnte nicht korrekt durchgefuehrt werden!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    manage busy_release
  }


  method startup_abbruch {num} {
    global abbruch

    set abbruch($this,$num) 1
    catch {destroy .startup_abbruch}
    manage busy_release
  }


  method startwerte_pruefen {} {
    global BITMAPDIR max_exp explist TITLE

    # Ueberpruefen, ob Startwerte uebereinstimmen
    set l {}

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[string first $i $explist] != -1} {
        lappend elist $i
      }
    }

    foreach elem $magnete_group {
      if {[$elem diff_startwerte $elist]} {
        lappend l $elem
      }
    }

    if {[llength $l]} {
      tk_dialog .dia "$TITLE" "Fuer die folgenden Steerer stimmen die \
                Startwerte fuer die Experimente aus der Experimentfolge nicht \
                ueberein: $l! Der Startup wird abgebrochen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
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
        set l {}

        foreach elem $magnete_group {
          if {[$elem get_tgesamt $i] > $t_impuls($i)} {
            lappend l $elem
          }
        }

        if {[llength $l]} {
          tk_dialog .dia "$TITLE" "Experiment $i: Fuer die folgenden Steerer \
                    ist die Laenge des Fgenfiles zu lang im Vergleich zur \
                    Zykluszeit des Timing-Senders: $l" @$BITMAPDIR/smily.xpm \
                    0 Ok
        }
      }
    }
  }


  method set_3er_beule_steererliste {l} {
    set 3er_beule_steererliste $l
  }


  method set_4er_beule_steererliste {l} {
    set 4er_beule_steererliste $l
  }


  method get_magnetlist {} {return $magnete_group}
  method get_name {} {return $name}
  method get_magnetegroup {} {return $magnete_group}
  method set_old_aktexp {o} {set old_akt_exp $o}
  method get_old_aktexp {} {return $old_akt_exp}
  method set_old_editexp {o} {set old_edit_exp $o}
  method get_old_editexp {} {return $old_edit_exp}
  method set_scalealle {args} {}
  method get_zeilen {} {return $zeilen}


  protected name
  public magnete_group {}
  public crates {}
  public wedel
  public beule
  public orbit
  protected targetlist {}
  protected old_akt_exp -1
  protected old_edit_exp -1
  protected old_explist ""
  protected modell_list
  protected poco_list
  protected mcntval 1
  protected zeilen 1
  protected crate_ramp {}
  protected trxlist {}
  protected startup_count 0
  protected 3er_beule_steererliste {}
  protected 4er_beule_ampval 0.0
  protected 4er_beule_winkelval 0.0
  protected 4er_beule_ort_beliebigval ""
  protected 4er_beule_steererliste {}
  protected 4bump_poco_ampval
  protected 4bump_poco_winkelval
  protected 4bump_ampval 1.0
  protected 4bump_winkelval 1.0
  protected 4bump_exp 1
  protected 4bump_direkt 1

  # Name der Datei mit den Orbitoptimierungsdaten, die in die Top-Werte
  # uebernommen werden sollen
global testbetrieb
if {$testbetrieb} {
  protected orbitopt_dir "/mnt/cc-x3/coob/lib/steerer"
  protected orbitopt_fileval "/mnt/cc-x3/coob/lib/steerer/orm_steerer.csv"
} else {
  protected orbitopt_dir "/mnt/cc-x/smb/csv"
  protected orbitopt_fileval "/mnt/cc-x/smb/csv/orm_steerer.csv"
}
  protected orbitopt_widget
  protected parent_window

}
