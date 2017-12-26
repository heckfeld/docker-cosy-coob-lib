# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/master.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class steerer_master {
  constructor {config} {
    global startup_count

    set pocos [lsort [itcl_info objects -isa dps_class]]
    set crates [lsort [itcl_info objects -isa crate_class]]
    set trx [lsort [itcl_info objects -isa trx_class]]

    foreach elem $crates {
      set startup_count($elem) 0
    }

    makemenu
    makepanel
  }


  destructor {}
  method config {config} {}


  method makemenu {} {
    frame .menu -relief raised -bd 2
    pack .menu -side top -fill x

    # Menu File
    menubutton .menu.file -text "File" -menu .menu.file.m
    menu .menu.file.m
    .menu.file.m add command -label Abspeichern -command "manage save"
    .menu.file.m add command -label "Abspeicherung laden/ansehen" -command \
                 "manage restore"
    .menu.file.m add separator
    .menu.file.m add command -label "Zwischenspeicher schreiben" \
                 -command "$this push_zwischen_schreiben"
    .menu.file.m add command -label "Zwischenspeicher lesen" \
                 -command "$this push_zwischen_lesen"
    .menu.file.m add separator
    .menu.file.m add command -label "Einzelsicherung loeschen" \
                 -command "manage del_bak"
    .menu.file.m add separator
    .menu.file.m add command -label "Quit" -command "$this quit"

    # TCP Menu
    menubutton .menu.tcp -text "TCP" -menu .menu.tcp.m
    menu .menu.tcp.m
    .menu.tcp.m add cascade -label Link -menu .menu.tcp.m.link
    .menu.tcp.m add cascade -label Release -menu .menu.tcp.m.release
    .menu.tcp.m add cascade -label "Reboot Target" -menu .menu.tcp.m.reboot
    menu .menu.tcp.m.link
    menu .menu.tcp.m.release
    menu .menu.tcp.m.reboot

    foreach elem $crates {
      set target [$elem get_target]
      set lab $elem
      append lab "                    "
      set index 15
      set liste [split $lab {}]

      for {set i 0} {$i < [string length $target]} {incr i} {
        set liste [lreplace $liste [expr $index + $i] [expr $index + $i] \
                  [string index $target $i]]
      }

      set liste [string trim [join $liste ""]]
      .menu.tcp.m.link add command -label $liste -command "$this link $target"
      .menu.tcp.m.release add command -label $liste -command "$this \
                              release $target"
      .menu.tcp.m.reboot add command -label $liste -command "$this reboot \
                             $target"
    }

    pack .menu.file .menu.tcp -side left -padx 10
  }


  method push_zwischen_schreiben {} {
    global BACKUPDIR

    manage busy_hold
    manage save_file $BACKUPDIR/tmp
    manage busy_release
  }


  method push_zwischen_lesen {} {
    global BACKUPDIR

    manage busy_hold
    manage restore_file $BACKUPDIR/tmp
    manage busy_release
  }


  method quit {} {
    global BITMAPDIR TITLE

    set answer [tk_dialog .dia "$TITLE" "Soll die Oberflaeche beendet werden?" \
                @$BITMAPDIR/smilyequal.xpm 1 Ja Nein]

    if {!$answer} {
      menu_quit
    }
  }


  method menu_quit {} {
    # ustate stoppen
    foreach elem [itcl_info objects -class usta_class] {
      $elem stop
    }

    # Targetverbindungen schliessen
    set targetlist [itcl_info objects -class target_ustate_class]

    foreach elem $targetlist {
      if {[$elem get_islinked]} {
        catch {set targetid [$elem get_targetid]}
        catch {close $targetid}
      }
    }
    exit
  }


  method link {targ} {
    $targ link
  }


  method release {targ} {
    $targ release
  }


  method reboot {targ} {
    global TITLE BITMAPDIR

    foreach elem [$targ get_magnetlist] {
      if {[lsearch $crates $elem] != -1} {
        set crate $elem
      }
    }

    # Damit nicht zweimal gebootet wird,
    # das erste mal, falls das Target nicht antwortet,
    # wenn der nachfolgende Befehl ausgefuehrt wird und
    # das zweite mal in dieser Methode weiter unten !!!
    $targ set_reboot_from_master 

    set rc [$crate sclc]

    if {$rc} {
      set answer [tk_dialog .dia "$TITLE" "Es konnte kein Sclc fuer $crate \
                  ausgefuehrt werden, die Rampe laeuft noch. Soll das Target \
                  $targ trotzdem gebooter werden?" @$BITMAPDIR/smily.xpm 0 Ja \
                  Nein]
    } else {
      set answer 0
    }

    if {!$answer} {
      $targ boot
    }
    $targ clear_reboot_from_master 
  }


  method makepanel {} {
    global mfont

    button .gruppe -text Gruppenbild -height 4 -font $mfont -command "$this \
           gruppe"
    menubutton .einzel -text Einzelbild -height 4 -menu .einzel.m \
               -font $mfont -relief raised -anchor c
    menu .einzel.m -font $mfont
    .einzel.m add command -label Steerer -command "$this poco_einzel"
    .einzel.m add command -label Timing-Receiver -command "$this trx_einzel"
    pack .gruppe .einzel -fill both
  }


  method gruppe {} {
    manage busy_hold
    group init
    tim init
    manage busy_release
  }


  method poco_einzel {} {
    global WORKSPACE

    if {[winfo exists .poco_magnetlist]} {
      raise.tk .poco_magnetlist
    } else {
      toplevel .poco_magnetlist
      wm title .poco_magnetlist "Einzelview"
      wm geometry .poco_magnetlist 180x240
      wm minsize .poco_magnetlist 1 1
      wm command .poco_magnetlist $WORKSPACE

      frame .poco_magnetlist.row2
      frame .poco_magnetlist.row1 -relief ridge -borderwidth 1m
      pack .poco_magnetlist.row2 -side bottom -in .poco_magnetlist \
           -fill both -expand 1
      pack .poco_magnetlist.row1 -side top -in .poco_magnetlist \
           -fill both -expand 1

      # Ok und cancel
      button .poco_magnetlist.einzelok -text Ok -command \
                                        "$this poco_einzelview_ok"
      button .poco_magnetlist.einzelcancel -text Cancel -command \
             "$this poco_einzelview_cancel"
      pack .poco_magnetlist.einzelok .poco_magnetlist.einzelcancel \
           -in .poco_magnetlist.row2 -side left -padx 10 -expand yes

      SelectBox_B1 .poco_magnetlist.select
      .poco_magnetlist.select config -width 18
      pack .poco_magnetlist.select -in .poco_magnetlist.row1 -expand yes

      # alle passenden Pocos in die Liste schreiben
      .poco_magnetlist.select config -list $pocos
    }
  }


  method poco_einzelview_ok {} {
    global BITMAPDIR TITLE

    manage busy_hold

    set magnete_sel [.poco_magnetlist.select get selected]

    if {[llength $magnete_sel] != 0} {
      foreach magnet $magnete_sel {
        if {[winfo exists .view$magnet]} {
          raise.tk .view$magnet
        } else {
          # Falls Klasse nicht geloescht wurde
          if {[lsearch [itcl_info objects -class dpsview_class] \
                                              view$magnet] != -1} {
              view$magnet delete
          }

          dpsview_class view$magnet -magnet $magnet
        }
      }
    } else {
      tk_dialog .dia "$TITLE" "Es wurden keine Steerer ausgewaehlt" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }

    destroy .poco_magnetlist
    manage busy_release
  }


  method poco_einzelview_cancel {} {
    destroy .poco_magnetlist
  }


  method trx_einzel {} {
    global BITMAPDIR WORKSPACE

    if {[winfo exists .timing_magnetlist]} {
      raise.tk .timing_magnetlist
    } else {
      toplevel .timing_magnetlist
      wm title .timing_magnetlist "Einzelview"
      wm geometry .timing_magnetlist 180x240
      wm minsize .timing_magnetlist 1 1
      wm command .timing_magnetlist $WORKSPACE

      frame .timing_magnetlist.row2
      frame .timing_magnetlist.row1 -relief ridge -borderwidth 1m
      pack .timing_magnetlist.row2 -side bottom -in .timing_magnetlist \
           -fill both -expand 1
      pack .timing_magnetlist.row1 -side top -in .timing_magnetlist \
           -fill both -expand 1

      # Ok und cancel
      button .timing_magnetlist.einzelok -text Ok -command \
                                         "$this timing_einzelview_ok"
      button .timing_magnetlist.einzelcancel -text Cancel -command \
             "$this timing_einzelview_cancel"
      pack .timing_magnetlist.einzelok .timing_magnetlist.einzelcancel \
           -in .timing_magnetlist.row2 -side left -padx 10 -expand yes

      SelectBox_B1 .timing_magnetlist.select
      .timing_magnetlist.select config -width 18
      pack .timing_magnetlist.select -in .timing_magnetlist.row1 -expand yes

      # alle im Master ausgewaehlten Timing-Receiver in die Liste schreiben
      .timing_magnetlist.select config -list $trx
    }
  }


  method timing_einzelview_ok {} {
    global BITMAPDIR TITLE

    manage busy_hold

    set timing_sel [.timing_magnetlist.select get selected]

    if {[llength $timing_sel] != 0} {
      foreach timing $timing_sel {

        if {[winfo exists .view$timing]} {
          raise.tk .view$timing
        } else {
          # Falls Klasse nicht geloescht wurde
          if {[lsearch [itcl_info objects -class trxview_class] \
                                              view$timing] != -1} {
              view$timing delete
          }
          trxview_class view$timing -timing $timing
        }
        view$timing init
      }
    } else {
      tk_dialog .dia "$TITLE" "Es wurden keine Timing-Receiver\
                ausgewaehlt" @$BITMAPDIR/smily.xpm 0 Ok
    }

    destroy .timing_magnetlist
    manage busy_release
  }


  method timing_einzelview_cancel {} {
    destroy .timing_magnetlist
  }


  method save_object {fileid savelist} {
    global akt_exp edit_exp explist

    puts $fileid "manage busy_hold"

    # aktuelle Experimentnummer
    puts $fileid "global akt_exp; set akt_exp $akt_exp"
    puts $fileid "global edit_exp; set edit_exp $edit_exp"
    puts $fileid "global explist; set explist $explist"

    foreach elem $pocos {
      $elem save_object $fileid $savelist
    }

    foreach elem $crates {
      $elem save_object $fileid $savelist
    }

    # Gruppenfenster
    if {[winfo exists .group]} {
      puts $fileid "group init"
    } else {
      puts $fileid "if {\[winfo exists .group\]} {destroy .group}"
    }

    group save_object $fileid $savelist

    # Einzelviews
    foreach elem [lsort [itcl_info objects -isa orbit_einzel_class]] {
      $elem save_object $fileid $savelist
    }

    # TimsRxList
    tim save_object $fileid

    foreach elem [lsort [itcl_info objects -class trxview_class]] {
      $elem save_object $fileid
    }

    # Einzelviews deleten
    puts $fileid "foreach elem \[itcl_info objects -class dpsview_class\] \
                  {destroy .\$elem}"

    foreach elem [itcl_info objects -class dpsview_class] {
      set magnet [$elem get_magnet]
      puts $fileid "dpsview_class $elem -magnet $magnet"
    }

    puts $fileid "foreach elem \[itcl_info objects -class trxview_class\] \
                  {destroy .\$elem}"

    foreach elem [itcl_info objects -class trxview_class] {
      set timing [$elem get_timing]
      puts $fileid "trxview_class $elem -timing $timing;$elem init"
    }

    puts $fileid "manage busy_release"
  }


  protected buttonwidth 18
  protected pocos {}
  protected crates {}
  protected trx {}
}
