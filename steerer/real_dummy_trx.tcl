# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/real_dummy_trx.tcl,v 1.1 2012/04/25 14:41:18 tine Exp $
itcl_class real_dummy_trx_class {
  constructor {config} {}
  destructor {}
  method config {config} {}


  method connect {} {
  }


  method disconnect {} {
  }


  method start {} {
  }


  method stop {} {
  }


  method status {} {
  }


  method reset {} {
  }


  method download {{tr_list {}} {set_list {}}} {
  }


  method get_magnete_num {} {
    return 0
  }


  method set_setting {{t {}} {s {}}} {
  }


  method data_init {w st} {
  }


  method tr_init {tr typ adr val} {
  }


  method save_object {fileid} {}
  method get_setting {} {return ""}
  method get_timerecords {} {return ""}
  method get_target {} {return ""}
  method get_isconnected {} {return ""}
  method set_isconnected {isconn} {}
  method get_neuname {} {return ""}

}
