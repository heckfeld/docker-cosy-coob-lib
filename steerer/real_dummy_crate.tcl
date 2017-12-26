# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/real_dummy_crate.tcl,v 1.1 2012/04/25 14:40:21 tine Exp $
itcl_class real_dummy_crate_class {
  constructor {config} { }
  destructor {}
  method config {config} {}


  method connect {} {
  }


  method disconnect {} {
  }


  method set_on {{state 1}} {
  }


  method set_off {{state 1}} {
  }


  method eval_fgenstat {magnet s} {
  }


  method reset {} {
  }


  method set_soll {magnet {s 0} {akt 1}} {
  }


  method send_soll {magnet {s 0} {akt 1}} {
    return 0
  }


  method aktuate_ist {} {
  }


  method eval_ist {magnet istwert} {
  }


  method eval_state {magnet status} {
  }


  method set_dc {{magnet ""}} {
    return 0
  }


  method set_sync {} {
  }


  method set_conn_num {} {
  }


  method startup123 {{liste {}}} {
  }


  method go123 {{liste {}}} {
  }


  method download {{liste {}}} {
  }


  method download123 {{liste {}}} {
  }


  method fgeninit {} {
    return 0
  }


  method rclc {} {
  }


  method rlex {} {
  }


  method sclc {{mit_warnung 1}} {
    return 0
  }


  method start_ohne_timing {} {
  }


  method mcnt {m} {
  }


  method exp {num} {
  }


  method pex {num} {
  }


  method stop_ohne_timing {} {
  }


  method get_info {} {
  }


  method eval_info {info} {
  }


  method get_rnr {} {
  }


  method get_enr {} {
  }


  method send_lexp {el} {
  }


  method get_lexp {} {
  }


  method set_set {elem type} {
  }


  method data_init {} {}
  method save_object {fileid savelist} {}

  method srmp {} {
  }


  method set_pocostart {} {
  }


  method diff_rnr {elem {diff 1}} {
  }


  method get_magnetlist {} {return {}}
  method get_trx {} {return ""}
  method get_conn_string {} {return ""}
  method set_explist {e} {}
  method get_target {} {return ""}
  method get_isconnected {} {return 0}
  method set_isconnected {isconn} {}
  method set_magneteconn {args} {}
  method set_dogetinfo {val} {}
  method get_rampenfehler {elem} {}
  method set_rampmagnete {{r {}}} {}
  method get_rampmagnete {} {return {}}


  public neu_name
}
