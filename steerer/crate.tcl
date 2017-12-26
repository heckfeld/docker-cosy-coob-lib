#
# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/crate.tcl,v 1.7 2012/04/25 14:56:17 tine Exp $
#

itcl_class crate_class {
  constructor {config} {
    set fehler_list {stoer last lokal}

    ### Tine: 26.01.2012
    # obsolete_magnets, braucht nicht abgespeichert zu werden !!!
    # wird aber fuer die Auswertung des Info_strings benoetigt !!!
    set obsolete_magnets {}
    set dps_class_liste [itcl_info objects -isa dps_class]
global testbetrieb
if {$testbetrieb} {
puts "crate_class $this: dps_class_liste=$dps_class_liste"
}
    foreach elem $magnetlist {
      if {[lsearch $dps_class_liste $elem] == -1} {
        lappend obsolete_magnets $elem
      }
    }
if {$testbetrieb} {
puts "crate_class $this: obsolete_magnets      =$obsolete_magnets"
puts "crate_class $this: magnetlist(uebergeben)=$magnetlist"
}

    # Uebergebene magnetlist in actual_magnetlist sichern.
    # Dann aus actual_magnetlist die obsolete_magnets entfernen !!!
    set actual_magnetlist $magnetlist
    foreach elem $obsolete_magnets {
      set index [lsearch $actual_magnetlist $elem]
      if {$index != -1} {
        set actual_magnetlist [lreplace $actual_magnetlist $index $index]
      }
    }
if {$testbetrieb} {
puts "crate_class $this: actual_magnetlist     =$actual_magnetlist"
puts "--"
}
    ###

    foreach elem $magnetlist {
      set old_rnr($elem) -1
      set old_info($elem) ""
      set neu_info($elem) " "
      set rampen_fehler($elem) 0

      foreach e $fehler_list {
        global $e

        set ${e}($this) 0
        set status_error($e,$elem) 0
      }
    }
  }


  destructor {}
  method config {config} {}


  method connect {} {
    global max_exp

    if {![$target get_islinked]} {
      $target link
    }

    set command "()$this getconnect"
    $target send_receive $command $command

    if {[$target get_islinked]} {
      set scsrtext [$target get_scsrtext $command]

      if {[string first "null" $scsrtext] != -1} {
        # Falls noch nicht connected
        set old_expstring ""

        foreach elem $magnetlist {
          for {set i 1} {$i <= $max_exp} {incr i} {
            $elem set_isloaded $i 0
          }
        }

        # Falls noch nicht connected
        set command "()$this connect '$conn_string' $type"
        $target send_receive $command $command

        # ueberpruefen ob connect ohne fehler abgelaufen ist
        set scsrtext [$target get_scsrtext $command]

        if {[string compare $scsrtext $command] == 0} {
          set is_connected 1
        } else {
          set is_connected 0
        }
      } else {
        set is_connected 1
      }
    }
  }


  method disconnect {} {
    $target send_receive "()$this disconnect"
    set is_connected 0
  }


  method set_on {{state 1}} {
    global aus

    if {[$target get_islinked]} {
      foreach elem $magnetlist {
        database set_aus_ein $elem 0
      }
    }

    $target send_receive "()$this on"

    if {$state} {
      get_info
    }
  }


  method set_off {{state 1}} {
    global aus

    if {[$target get_islinked]} {
      foreach elem $magnetlist {
        database set_aus_ein $elem 1
      }
    }

    $target send_receive "()$this off"

    if {$state} {
      get_info
    }
  }


  method eval_fgenstat {magnet s} {
   global rechok rampok fgenstat

   if {![string length $s]} {
     return
   }     

   set status [expr 0x$s]

    if {![catch {expr $status}]} {
      set fgenstat($magnet) 0x[format "%x" $status]

      # setzen der checkbuttons
      # IOPTO rechnet (Bits 13 und 19)
      if {[expr ($status & 0x1000) && ($status & 0x40000)]} {
         set rechok($magnet) 1
      } else {
        set rechok($magnet) 0
      }

      # Ausgabe laeuft (Bit 24)
      if {[expr $status & 0x800000]} {
        set rampok($magnet) 0
      } else {
        set rampok($magnet) 1
      }
    }
  }


  method reset {} {
    # Geraet muss im DC-Mode sein
    set_dc
    $target send_receive "()$this reset"
    get_info
  }


  method set_soll {magnet {s 0} {akt 1}} {
    send_soll $magnet $s $akt
  }


  method send_soll {magnet {s 0} {akt 1}} {
    global BITMAPDIR TITLE

    set soll_fehler 0
    set wsoll [$magnet convert2bit $s]
    set command "()$this :sdi[$magnet get_num]:$wsoll"
    $target send_receive $command $command

    # falls Sollwert gesetzt werden konnte (keine scsr)
    if {[$target get_islinked]} {
      if {[string first scsr [$target get_scsrtext $command]] != -1} {
        set soll_fehler 1
      }

      if {$akt} {
        aktuate_ist
      }
    }

    return $soll_fehler
  }


  method aktuate_ist {} {
    puts stderr "sleep 2"
    get_info
  }


  method eval_ist {magnet istwert} {
    global ist

    if {[string length $istwert]} {
      if {![catch {expr $istwert}]} {
        if {$istwert} {
          set istwert [expr [$magnet get_rmin]+double([$magnet get_rmax]- \
                      [$magnet get_rmin])/([$magnet get_scmax]-[$magnet \
                      get_scmin])*($istwert-[$magnet get_scmin])]
          set ist($magnet) [format "%.3f" $istwert]
        } else {
          # genaue Darstellung der 0
          set ist($magnet) 0.000
        }
      }
    }
  }


  method eval_state {magnet status} {
    global stoer last lokal aus fehler NAME

    ### Tine: 20.01.2012
    ### KEINE Fehlermeldung fuer SH03, SV04 !!!
    ### Es gibt Netzgeraete, die zwar noch im Crate eingetragen sind,
    ### sonst aber nicht weiter bedient werden sollen !!!
    ### Bei diesen Geraeten macht eine Fehlermeldung keinen Sinn !!!
    ### Betrifft z.Zt. SH03 bzw. SV04 !!!

    if {[string compare "$magnet" "SH03"] == 0 \
     || [string compare "$magnet" "SV04"] == 0} {
      return
    }

    if {![string length $status]} {
      return
    }

    set status [expr 0x$status]

    # setzen der checkbuttons
    # Sammelmeldung Stoerung
    if {[expr $status & 1]} {
      set stoer($magnet) 0

      if {$status_error(stoer,$magnet)} {
        set status_error(stoer,$magnet) 0
        manage reset_error "Fehler (Sammelmeldung Stoerung) bei $magnet"
      }
    } else {
      set stoer($magnet) 1

      if {!$status_error(stoer,$magnet)} {
        set status_error(stoer,$magnet) 1
        manage set_error "Fehler (Sammelmeldung Stoerung) bei $magnet"
      }
    }

    # Aus
    if {[expr $status & 4]} {
      set ausval 0
    } else {
      set ausval 1
    }
    if {$aus($magnet) != $ausval} {
      database set_poco_aus_ein $magnet $ausval
    }
    set aus($magnet) $ausval

    # Last
    if {[expr $status & 8]} {
      # falls nicht ecsteer
      if {"$NAME" != "ecsteer"} {
        set last($magnet) 0
      } else {
        set last($magnet) 1
      }

      # falls nicht ecsteer und Fehler vorhanden
      if {("$NAME" != "ecsteer") && $status_error(last,$magnet)} {
        set status_error(last,$magnet) 0
        manage reset_error "Fehler (Last) bei $magnet"
      }
    } else {
      if {"$NAME" != "ecsteer"} {
        set last($magnet) 1
      } else {
        set last($magnet) 0
      }

      # falls nicht ecsteer und Fehler nicht vorhanden
      if {("$NAME" != "ecsteer") && !$status_error(last,$magnet)} {
        set status_error(last,$magnet) 1
        manage set_error "Fehler (Last) bei $magnet"
      }
    }

    # Lokal
    if {[expr $status & 16]} {
      set lokal($magnet) 0

      if {$status_error(lokal,$magnet)} {
        set status_error(lokal,$magnet) 0
        manage reset_error "Fehler (Lokal) bei $magnet"
      }
    } else {
      set lokal($magnet) 1

      if {!$status_error(lokal,$magnet)} {
        set status_error(lokal,$magnet) 1
        manage set_error "Fehler (Lokal) bei $magnet"
      }
    }

    # Fehler
    # falls nicht ecsteer
    if {"$NAME" != "ecsteer"} {
      set fehler($magnet) [expr $stoer($magnet) || $lokal($magnet) || \
                           $last($magnet)]
    } else {
      set fehler($magnet) [expr $stoer($magnet) || $lokal($magnet)]
    }
  }


  method set_dc {{magnet ""}} {
    global dc akt_exp

    if {![string length $magnet]} {
      set rc [sclc 0]

      if {$rc} {
        return 1
      }

      foreach elem $magnetlist {
        database set_dc_sync $elem 1
      }

      get_info

      foreach elem $magnetlist {
        # Sollwert ans Netzgeraet schicken
        send_soll $elem [$elem get_soll $akt_exp] 0
      }

      # Status
      get_info
    } else {
      get_info

      if {!$dc($magnet)} {
        database set_dc_sync $magnet 1

        foreach elem $magnetlist {
          if {[string compare $elem $magnet]} {
            set add [expr !$dc($elem)]
          } else {
            set add 0
          }

          append mode :$add
        }

        set mode '[string range $mode 1 end]'
        $target send_receive "()$this :mode:$mode"

        # Status
        get_info
      }
    }

    return 0
  }


  method set_sync {} {
    global dc

    get_info
    set mode ""
    set dclist {}

    foreach elem $magnetlist {
      # falls noch nicht im im Sync-Mode
      if {$dc($elem)} {
        lappend dclist $elem
      }

      append mode :1
    }

    if {[llength $dclist]} {
      if {[$target get_islinked]} {
        foreach elem $dclist {
          database set_dc_sync $elem 0
        }
      }

      set mode '[string range $mode 1 end]'
      $target send_receive "()$this :mode:$mode"
      get_info
    }
  }


  method set_conn_num {} {
    set factor 1
    set val 0

    foreach elem $magnetlist {
      set val [expr $val + $factor]
      set factor [expr $factor * 2]
    }

    $target send_receive "()$this :sst2:$val"
  }


  method startup123 {{liste {}}} {
    global explist exp_fehl akt_exp BITMAPDIR TITLE

    set rc [sclc 0]

    if {$rc} {
      tk_dialog .dia "$TITLE" "$this: Die Rampe laeuft noch! Der Startup wird \
                abgebrochen!" @$BITMAPDIR/smily.xpm 0 Ok
    }

    if {[$target get_targetfail] || $rc} {
      set exp_fehl 1
      manage busy_release;return
    }

    foreach elem $magnetlist {
      # Sollwert ans Netzgeraet schicken
      send_soll $elem [$elem get_soll $akt_exp] 0
    }

    # Falls Argumente uebergeben werden, download nur fuer elemente in der
    # Liste
    if {[llength $liste]} {
      download123 $liste
    } else {
      download123
    }

    rlex
    set old_expstring $explist
  }


  method go123 {{liste {}}} {
    global explist exp_fehl akt_exp BITMAPDIR

    foreach elem $magnetlist {
      # Sollwert ans Netzgeraet schicken
      send_soll $elem [$elem get_soll $akt_exp] 0
    }

    # Falls Argumente uebergeben werden, download nur fuer elemente in der
    # Liste
    if {[llength $liste]} {
      download123 $liste
    } else {
      download123
    }

    rlex
    set old_expstring $explist
  }


  method download {{liste {}}} {
    download123 $liste
  }


  method download123 {{liste {}}} {
    global explist FGENDIR BITMAPDIR max_exp

    # Falls liste uebergeben wird, download nur fuer Element liste
    if {[llength $liste]} {
      set magnete $liste
    } else {
      set magnete $magnetlist
    }

    # falls old_expstring = explist braucht lexp nicht
    # geschickt zu werden
    if {[string compare $old_expstring $explist]} {
      # Experimentfolge an CPU schicken
      send_lexp $explist
    }

    set numlist {}

    # Bestimmen der Liste, fuer die Fgenfiles geschickt werden muessen
    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[string first $i $explist] != -1} {
        lappend numlist $i
      }
    }

    # Fgenfile muss nur geschickt werden, wenn das Fgenfile sich veraendert
    # hat oder das Fgenfile noch nicht in das Target geladen wurde
    foreach i $numlist {
      set download_magnete {}

      foreach elem $magnete {
        set diff [catch {exec cmp $FGENDIR/$elem.fgen$i \
                          $FGENDIR/$elem.fgen$i.startup}]

        if {$diff || ![$elem get_isloaded $i]} {
          lappend download_magnete $elem
        }
      }

      if {[llength $download_magnete]} {
        exp $i

        foreach elem $download_magnete {
          $elem set_download $i
        }
      }
    }
  }


  method fgeninit {} {
    set rc [sclc 0]
    return $rc
  }


  method rclc {} {
    rlex
  }


  method rlex {} {
    global exp_fehl

    $target send_receive "()$this rlex"

    if {[$target get_islinked]} {
      foreach elem $magnetlist {
        database set_dc_sync $elem 0
      }
    }

    if {[$target get_targetfail]} {
      set exp_fehl 1
      manage busy_release;return
    }

    puts stderr "sleep 1"
    get_info
  }


  method sclc {{mit_warnung 1}} {
    global BITMAPDIR TITLE

    set command "()$this sclc"
    $target send_receive $command $command

    # Ueberpruefen, ob kein Fehler aufgetreten ist
    if {[string first scsr [$target get_scsrtext $command]] != -1} {
      if {$mit_warnung} {
        tk_dialog .dia "$TITLE" "$this: Die Rampe laeuft noch! Die Ausfuehrung \
                  des Befehls wird abgebrochen!" @$BITMAPDIR/smily.xpm 0 Ok
      }

      return 1
    }

    if {[$target get_islinked]} {
      foreach elem $magnetlist {
        database set_dc_sync $elem 1
      }
    }

    get_info
    return 0
  }


  method start_ohne_timing {} {
    $target send_receive "()$this :sarm:0"
    $target send_receive "()$this mstr"
  }


  method mcnt {m} {
    $target send_receive "()$this :mcnt:$m"
  }


  method exp {num} {
    $target send_receive "()$this :exp:$num"
  }


  method pex {num} {
    $target send_receive "()$this :pex$num:"
  }


  method stop_ohne_timing {} {
    $target send_receive "()$this mstp"
  }


  method get_info {} {
    set command "()$this :info:"
    $target send_receive $command $command

    if {[$target get_islinked]} {
      set info [lindex [split [$target get_scsrtext $command] '] 1]
#
# aus steererh.log:
#(62,1)SH16/17/19/21 :info:\
# 'E6:P1:M1:1d:cc103f:0:0:M1:1d:cc103f:0:0:M1:1d:cc103f:20:0:\
# M1:1d:cc103f:0:0:IDLE:0'
#
global testbetrieb
if {$testbetrieb} {
set info "E6:P1:M1:1d:cc103f:0:0:M1:1d:cc103f:0:0:"
append info "M1:1d:cc103f:20:0:M1:1d:cc103f:0:0:IDLE:0"
puts "get_info ($this): info=\"$info\""
}
      eval_info $info
    }
  }


  method eval_info {info} {
    global enr dc rnr

    if {![string length $info]} {
      return
    }
set save_info $info

    set info [split $info :]

    # enr ist 1. Element der Liste (E1, E2 oder E3), ist fuer alle
    # Netzgeraete eines Crates gleich,
    foreach elem $magnetlist {
      regsub E [lindex $info 0] "" out
      set enr($elem) $out
    }

    set base_info [lrange $info 0 1]
    set info [lrange $info 2 end]

    foreach elem $magnetlist {
      set werte [lrange $info 0 4]
      set neuinfo($elem) [concat $base_info $werte]

      # Mode ist 1. Element von Liste
      regsub M [lindex $info 0] "" out

      if {[string length $out]} {
        set dcval [expr !$out]
        if {$dc($elem) != $dcval} {
          database set_poco_dc_sync $elem $dcval
        }
        set dc($elem) $dcval
      }

      # Status ist 2. Element der Liste als Hexzahl
      eval_state $elem [lindex $info 1]

      # Fgen-Status ist 3. Element der Liste als Hexzahl
      eval_fgenstat $elem [lindex $info 2]

      # Ausgangsstrom ist 4. Element
      eval_ist $elem [lindex $info 3]

      # Rampenzahl ist 5. Element
      set rnr($elem) [lindex $info 4]

      set info [lrange $info 5 end]
    }

    # falls info sich nicht veraendert hat, rot markieren
    if {$first_info || $poco_start} {
      foreach elem $magnetlist {
        set old_info($elem) $neu_info($elem)
        set neu_info($elem) $neuinfo($elem)

        if {[string compare $neu_info($elem) $old_info($elem)] == 0} {
          diff_rnr $elem 0
        } else {
          diff_rnr $elem 1
        }
      }

      set do_getinfo 0
    }

    set poco_start 0
    set first_info 0
  }


  method get_rnr {} {
    global rnr

    set command "()$this :rrs:"
    $target send_receive $command $command

    if {[$target get_islinked]} {
      # String zwischen den '
      set r [lindex [split [$target get_scsrtext $command] '] 1]

      # Nach Doppelpunkten aufsplitten
      set r [split $r :]

      foreach elem $magnetlist {
        set rwert [lindex $r [expr [$elem get_num] -1]]
        set old_rnr($elem) $rnr($elem)

        if {![catch {expr $rwert}]} {
          set rnr($elem) $rwert
        }

        # falls rnr sich nicht veraendert hat, rosa markieren
        if {[winfo exists .group]} {
          if {![string compare $old_rnr($elem) $rnr($elem)]} {
            member$elem diff_rnr 0
          } else {
            member$elem diff_rnr 1
          }
        }
      }
    }
  }


  method get_enr {} {
    global enr explist

    set command "()$this :lpos:"
    $target send_receive $command $command

    if {[$target get_islinked]} {
      # String zwischen den '"
      set e [lindex [split [$target get_scsrtext $command] '] 1]

      # Nach Doppelpunkten aufsplitten
      set e [split $e :]

      foreach elem $magnetlist {
        set ewert [lindex $e [expr [$elem get_num] -1]]

        if {![catch {expr $ewert}]} {
          set enr($elem) [string index $explist [expr $ewert -1]]
        }
      }
    }
  }


  method send_lexp {el} {
     set exp_list $el

     # Experimentfolge an CPU schicken
     $target send_receive "()$this :lexp:'$el'"
     get_lexp
  }


  method get_lexp {} {
    set command "()$this :lexp:"
    $target send_receive $command $command

    if {[$target get_islinked]} {
      set rc [$target get_scsrtext $command]
      set first [expr [string first "'" $rc] +1]
      set last [expr [string last "'" $rc] -1]
      set rc [string range $rc $first $last]
    } else {
      set status ""
    }
  }


  method set_set {elem type} {
    # falls elem nicht in magnetlist nichts tun
    if {[lsearch $magnetlist $elem] == -1} {
      return
    }

    switch $type {
      off   {database  set_aus_ein $elem 1; set val 0}
      on    {database  set_aus_ein $elem 0; set val 1}
      reset {set val 9}
    }

    $target send_receive "()$this :set[$elem get_num]:$val"
  }


  method data_init {} {
    global dc

    set dclist {}
    set dcstring ""
    set synclist {}
    set syncstring ""

    foreach elem $magnetlist {
      if {[$elem get_was_dc] && !$dc($elem)} {
        lappend dclist $elem

        if {[string length $dcstring]} {
          append dcstring ", $elem"
        } else {
          append dcstring $elem
        }
      } else {
        if {![$elem get_was_dc] && $dc($elem)} {
          lappend synclist $elem

          if {[string length $syncstring]} {
            append syncstring ", $elem"
          } else {
            append syncstring $elem
          }
        }
      }
    }

    set len [llength $dclist]

    if {$len} {
      foreach elem $dclist {
        database set_dc_sync $elem 0
      }
    }

    set len [llength $synclist]

    if {$len} {
      foreach elem $synclist {
        database set_dc_sync $elem 1
      }
    }
  }


  method save_object {fileid savelist} {
    global aus dc soll akt_exp edit_exp

    connect
    set_conn_num
    get_info

    puts $fileid "$this connect"
    puts $fileid "$this set_conn_num"

    # Ein oder Aus
    foreach elem $actual_magnetlist {
      if {$aus($elem)} {
        puts $fileid "$this set_set $elem off"
      } else {
        puts $fileid "$this set_set $elem on"
      }
    }

    # In DC-Mode setzen
    puts $fileid "$this set_dc"

    foreach elem $actual_magnetlist {
      puts $fileid "$elem set_dorech 0"
    }

    # Soll-Strom
    foreach elem $actual_magnetlist {
      # falls edit_exp in savelist
      if {[string first $edit_exp $savelist] != -1} {
        puts $fileid "global soll; set soll($elem) [$elem get_soll $edit_exp]"
        puts $fileid "global top; set top($elem) [$elem get_top $edit_exp]"
      }

      puts $fileid "$this send_soll $elem [$elem get_soll $akt_exp]"
    }

    foreach elem $actual_magnetlist {
      puts $fileid "$elem set_dorech 1"
    }

    # Startup nur fuer Netzgeraete, die nicht im DC-Mode waren
    set ramp_magnete {}

    foreach elem $actual_magnetlist {
      if {!$dc($elem)} {
        lappend ramp_magnete $elem
      }
    }

    puts $fileid "$this set_rampmagnete [list $ramp_magnete]"

  }; #save_object


  method srmp {} {
    global explist

    set string ""
    set count 0

    foreach elem $magnetlist {
      incr count

      set bitval [$elem convert2bit [$elem get_soll [string index $explist 0]]]

      if {$count == 1} {
        append string $bitval
      } else {
        append string :$bitval
      }
    }

    for {set i [llength $magnetlist]} {$i <= 4} {incr i} {
      append string :
    }

    set command "()$this :srmp:'$string'"
    $target send_receive $command $command
  }


  method set_pocostart {} {
    incr poco_start

    if {($poco_start > 1) && !$do_getinfo} {
      get_info
    }
  }


  method diff_rnr {elem {diff 1}} {
    global background BITMAPDIR stop dc

    ### Tine: 19.01.2012
    ### Es gibt Netzgeraete, die zwar noch im Crate eingetragen sind,
    ### sonst aber nicht weiter bedient werden sollen !!!
    ### Bei diesen Geraeten macht eine Fehlermeldung keinen Sinn !!!
    ### Betrifft z.Zt. SH03 bzw. SV04 !!!

    if {[string compare "$elem" "SH03"] == 0 \
     || [string compare "$elem" "SV04"] == 0} {
      return
    }

    if {($diff || ($stop($trx) == 1) || $dc($elem)) && $rampen_fehler($elem)} {
      set rampen_fehler($elem) 0
      manage reset_error "$elem rampt nicht mit!"
      catch {member$elem reset_rampenfehler}
    } elseif {!$diff && ($stop($trx) == 0) && !$dc($elem) && \
                                       !$rampen_fehler($elem)} {
      set rampen_fehler($elem) 1
      manage set_error "$elem rampt nicht mit!"
      catch {member$elem set_rampenfehler}
    }
  }


  method get_magnetlist {} {return $magnetlist}
  method get_trx {} {return $trx}
  method get_conn_string {} {return $conn_string}
  method set_explist {e} {set exp_list $e}
  method get_target {} {return $target}
  method get_isconnected {} {return $is_connected}
  method set_isconnected {isconn} {set is_connected $isconn}
  method set_magneteconn {args} {}
  method set_dogetinfo {val} {set do_getinfo $val}
  method get_rampenfehler {elem} {return $rampen_fehler($elem)}
  method set_rampmagnete {{r {}}} {set ramp_magnete $r}
  method get_rampmagnete {} {return $ramp_magnete}


  public conn_string
  public target
  public type
  protected is_connected -1
  public magnetlist
  public trx
  public group

  ### Tine: 25.04.2012
  # Geraet nicht in GUI, aber noch im Crate !!!
  protected obsolete_magnets {}

  # Tatsaechliche Magnet-Liste, entspricht magnetlist ohne obsolete_magnets!
  # Wird bei der Abspeicherung in save_object verwendet!
  protected actual_magnetlist {}
  ###

  protected exp_list ""
  protected old_expstring ""
  protected old_rnr
  protected old_info
  protected neu_info
  protected poco_start 0
  protected do_getinfo 0
  protected first_info 1
  protected status_error
  protected rampen_fehler
  protected ramp_magnete {}
}
