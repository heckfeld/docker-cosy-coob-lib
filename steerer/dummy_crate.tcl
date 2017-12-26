# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/dummy_crate.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class dummy_crate_class {
  constructor {config} { }
  destructor {}
  method config {config} {}


  method connect {} {
    $neu_name connect
  }


  method disconnect {} {
    $neu_name disconnect
  }


  method set_on {{state 1}} {
    $neu_name set_on $state
  }


  method set_off {{state 1}} {
    $neu_name set_off $state
  }


  method eval_fgenstat {magnet s} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      $neu_name evak_fgenstat $magnet $s
    }
  }


  method reset {} {
    $neu_name reset
  }


  method set_soll {magnet {s 0} {akt 1}} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      $neu_name set_soll $magnet $s $akt
    }
  }


  method send_soll {magnet {s 0} {akt 1}} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      return [$neu_name send_soll $magnet $s $akt]
    } else {
      return 0
    }
  }


  method aktuate_ist {} {
    $neu_name get_info
  }


  method eval_ist {magnet istwert} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      $neu_name eval_ist $magnet $istwert
    }
  }


  method eval_state {magnet status} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      $neu_name eval_state $magnet $status
    }
  }


  method set_dc {{magnet ""}} {
    # falls magnet existiert
    if {[lsearch [itcl_info objects -isa dps_class] $magnet] != -1} {
      return [$neu_name set_dc $magnet]
    } else { 
      return 0
    }
  }


  method set_sync {} {
    $neu_name set_sync
  }


  method set_conn_num {} {
    $neu_name set_conn_num
  }


  method startup123 {{liste {}}} {
    $neu_name startup123 $liste
  }


  method go123 {{liste {}}} {
    $neu_name go123 $liste
  }


  method download {{liste {}}} {
    $neu_name download $liste
  }


  method download123 {{liste {}}} {
    $neu_name download123 $liste
  }


  method fgeninit {} {
    return [$neu_name fgeninit]
  }


  method rclc {} {
    $neu_name rclc
  }


  method rlex {} {
    $neu_name rlex
  }


  method sclc {{mit_warnung 1}} {
    return [$neu_name scls $mit_warnung]
  }


  method start_ohne_timing {} {
    $neu_name start_ohne_timing
  }


  method mcnt {m} {
    $neu_name mcnt $m
  }


  method exp {num} {
    $neu_name exp $num
  }


  method pex {num} {
    $neu_name pex $num
  }


  method stop_ohne_timing {} {
    $neu_name stop_ohne_timing
  }


  method get_info {} {
    $neu_name get_info
  }


  method eval_info {info} {
    $neu_name eval_info $info
  }


  method get_rnr {} {
    $neu_name get_rnr
  }


  method get_enr {} {
    $neu_name get_enr
  }


  method send_lexp {el} {
    $neu_name send_lexp $el
  }


  method get_lexp {} {
    $neu_name get_lex
  }


  method set_set {elem type} {
    $neu_name set_set $elem $type
  }


  method data_init {} {}
  method save_object {fileid savelist} {}

  method srmp {} {
    $neu_name srmp
  }


  method set_pocostart {} {
    $neu_name set_pocostart
  }


  method diff_rnr {elem {diff 1}} {
    $neu_name diff_rnr $elem $diff
  }


  method get_magnetlist {} {return [$name get_magnetlist]}
  method get_trx {} {return [$neu_name get_trx]}
  method get_conn_string {} {return [$neu_name get_conn_string]}
  method set_explist {e} {$neu_name set_explist $e}
  method get_target {} {return [$neu_name get_target]}
  method get_isconnected {} {return [$neu_name get_isconnected]}
  method set_isconnected {isconn} {$neu_name set_isconnected $isconn}
  method set_magneteconn {args} {$neu_name set_magneteconn $args}
  method set_dogetinfo {val} {$neu_name set_dogetinfo $val}
  method get_rampenfehler {elem} {$neu_name get_rampenfehler $elem}
  method set_rampmagnete {{r {}}} {$neu_name set_rampmagnete $r}
  method get_rampmagnete {} {return [$neu_name get_rampmagnete]}


  public neu_name
}
