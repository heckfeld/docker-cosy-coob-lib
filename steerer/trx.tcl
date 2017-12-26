# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/trx.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class trx_class {

  constructor {config} {}
  destructor {}
  method config {config} {}


  method connect {} {
    if {![$target get_islinked]} {
      $target link
    }

    $target send_receive "()$this getconnect"

    if {[$target get_islinked]} {
      if {[string first "null" [$target get_scsrtext]] != -1} {
        # Falls noch nicht connected
        set command "()$this connect '$conn_string' $type"
        $target send_receive $command

        # Setting downloaden
        set download_made 0

        # ueberpruefen ob connect ohne fehler abgelaufen ist
        set scsrtext [$target get_scsrtext]
        if {[string compare $scsrtext $command] == 0} {
          set is_connected 1
        } else {
          set is_connected 0
        }
      } else {
        set is_connected 1
      }
    }

    # Setting downloaden
    if {!$download_made} {
      download $time_records $setting
    }
  }


  method disconnect {} {
    $target send_receive "()$this disconnect"
    set is_connected 0
  }


  method start {} {
    global stop

    set stop($this) 0

    if {[$target get_islinked]} {
      database set_timing_start_stop $this 0
    }

    $target send_receive "()$this start"

    if {[winfo exists .tim]} {
      tim pruefe_start_stop
    }
  }


  method stop {} {
    global stop

    set stop($this) 1

    if {[$target get_islinked]} {
      database set_timing_start_stop $this 1
    }

    $target send_receive "()$this stop"

    if {[winfo exists .tim]} {
      tim pruefe_start_stop
    }
  }


  method status {} {
    $target send_receive "()$this :lstat:"
  }


  method reset {} {
    if {[$target get_islinked]} {
      database clear_time_records $this
    }

    $target send_receive "()$this reset"

    set download_made 0
  }


  method download {{tr_list {}} {set_list {}}} {
    reset
    set time_records $tr_list
    set setting $set_list

    if {[$target get_islinked]} {
     set count 0
     foreach elem $setting {
       database create_time_records $this [lindex $time_records $count] \
                [lindex $elem 0] [lindex $elem 1] [lindex $elem 2]
       incr count
      }
    }

    foreach elem $setting {
      $target send_receive "()$this \
              :set:'[lindex $elem 0],[lindex $elem 1],[lindex $elem 2]'"
    }

    set download_made 1
  }


  method get_magnete_num {} {
    # Bestimmen aller Steerer zum Timing_receiver
    set len [string length $this]
    set stliste {}
    for {set i 3} {$i < $len} {set i [expr $i + 3]} {
      lappend stliste [string range $this $i [expr $i + 1]]
    }
    return $stliste
  }


  method set_setting {{t {}} {s {}}} {
    unset setting
    unset time_records

    set time_records $t
    set setting $s
#    set time_records [list $t]
#    set setting [list $s]
  }


  method data_init {w st} {
    global stop

    # Anzeige, ob Timing-Receiver in Timsrxlist angewaehlt ist
    if {"$w" == "t"} {
      tim append_listsel $this
    }

    connect
    set time_records $time_records_save
    set setting $setting_save

    if {[string length $setting]} {
      stop
      download $time_records $setting
    } else {
      stop
      reset
    }

    # Falls nicht st, Timing-Receiver starten
    if {"$st" == "f"} {
      start
    }
  }


  method tr_init {tr typ adr val} {
    lappend time_records_save $tr
    lappend setting_save [list $typ $adr $val]
  }


  method save_object {fileid} {
    global stop

    puts $fileid "$this set_setting"
    puts $fileid "global stop; set stop($this) $stop($this)"

    # connecten
    puts $fileid "$this connect"
    puts $fileid "$this download [list $time_records] [list $setting]"

    # Falls gestartet
    if {[info exists stop($this)]} {
      if {!$stop($this)} {
        puts $fileid "$this start"
      }
    }
  }


  method get_setting {} {return $setting}
  method get_timerecords {} {return $time_records}
  method get_target {} {return $target}
  method get_isconnected {} {return $is_connected}
  method set_isconnected {isconn} {set is_connected $isconn}


  public conn_string
  public target
  public type
  protected is_connected -1
  protected setting {}
  protected time_records {}
  protected setting_save {}
  protected time_records_save {}
  protected download_made 0
}
