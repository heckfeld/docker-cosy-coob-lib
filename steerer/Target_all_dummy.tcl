puts "Dummy-Target-Klasse eingebunden !!!"
itcl_class target_class {
  constructor {config} {
    set scsrtext(normal) ""

    if {![string length $inet]} {
      set inet $this
    }
  }


  destructor {}
  method config {config} {}


  method link {} {
    global BITMAPDIR NAME TITLE ustate_port
puts "Dummy-Target-Klasse: in $this link"

    $log insert "dummy ... Link ($protocol) Target $inet"

    if {!$is_linked} {
      set targetid 1
      set is_linked 1

      if {$ustate} {
        set udpid 1
      }

      # Pruefen ob Verbindung moeglich
      send_receive "()scsr :stat:"
    }
  }


  method boot {} {
    manage busy_hold

    if {$is_linked} {
      set targetid 0
      set udpid 0
      set is_linked 0
    }

    $log insert "dummy ... Reboot Target $inet"
    link

    if {[string length $boot_proc]} {
      eval $boot_proc $this
    } else {
      # alle Magnete neu connecten
      foreach elem $devicelist {
        if {[$elem get_isconnected] == 1} {
          $elem set_isconnected 0
          $elem connect
        }
      }
    }

    manage busy_release
    return 0
  }


  method release {} {
    global BITMAPDIR TITLE

    if {$is_linked} {
      $log insert "dummy ... Release ($protocol) Target $inet"
      set targetid 0

      if {$ustate} {
        set udpid 0
      }

      set is_linked 0
    } else {
       tk_dialog .dia "$TITLE" "$inet: Es exisiert keine \
                 $protocol-Verbindung!" @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  method send_receive {comm {sc_ind normal}} {
    global scsr_rc file_error BITMAPDIR NAME TITLE

    while {$target_busy} {
      after 500
    }

    set target_busy 1

    # Wir ordnen dem Targetbefehl eine ID N zu und uebergeben dem Target
    # diese Nummer mit dem Befehl: "(1,N) Kommando"
    # Die Antwort hat dann die Form "(N,1) Kommando...". Anhand der Nummer N
    # koennen wir dann die Antwort dem Befehl zuordnen.
    # Der Rueckgabewert ist N, mit dem als Parameter 'index' die zugehoerige
    # Antwort mit 'get_scsrtext' abgerufen werden kann
    # Die ID-Nummer ist max. 127
    set request_id [expr (($request_id + 1) % 128)]
    if {$request_id == 0} {incr request_id}

    # Auf lokale Variable 'tmp_request_id uebertragen wegen mehrfachen
    # Einsprungs
    set tmp_request_id $request_id
    set target_busy 0

    # '()' wird zu '(1,N)'
    set save_comm $comm
    regsub {\(} $comm "(1,$tmp_request_id" comm
    set command $comm

    set scsr_rc($this,$tmp_request_id) 0
    set file_error($this) 0
    set scsr_index $sc_ind

    if {$do_log} {
      $log insert "dummy >$comm"
    }

    if {$is_linked} {
      set len [string length $command]
      set last_char [string index $command [expr $len -1]]

      set scsrtext($tmp_request_id) $comm
      set scsrtext($sc_ind) $comm

      if {[string first sclc $command] != -1} {
        append scsrtext($sc_ind) ":141"
      } else {
        # falls read command
        if {![string compare $last_char :]} {
          append scsrtext($tmp_request_id) 0
          append scsrtext($sc_ind) 0
        }
      }

      if {$do_log} {
        $log insert "dummy <$scsrtext($sc_ind)"
      }
    } else {
      set tmp_request_id 0
      set scsrtext($sc_ind) ""
      set scsrtext($tmp_request_id) ""
    }

    return $tmp_request_id
  }


  method get_scsrtext {{index normal}} {
    if {[info exists scsrtext($index)]} {
      return $scsrtext($index)
    } else {
      return ""
    }
  }


  method dummy {} {}
  method get_usttext {} {return $usttext}
  method get_islinked {} {return $is_linked}
  method get_targetid {} {return $targetid}
  method set_islinked {il} {set is_linked $il}
  method get_magnetlist {} {return $devicelist}
  method get_devicelist {} {return $devicelist}
  method get_targetfail {} {return $target_fail}


  public inet ""
  public protocol tcp
  public service 22375
  public devicelist {}
  public ustate 0
  public do_log 1
  public log tlog
  public do_boot 1
  public boot_proc ""
  public update_proc update
  public timeout 15
  public mit_server 1
  public do_auto_connect 1
  public auto_relink 0
  protected targetid
  protected udpid
  protected is_linked 0
  protected scsrtext
  protected usttext
  protected command
  protected scsr_index normal
  protected target_fail 0
  protected request_id 0
  protected address
  protected target_busy 0
}
