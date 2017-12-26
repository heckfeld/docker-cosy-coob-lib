# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/dummy_trx.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class dummy_trx_class {
  constructor {config} {}
  destructor {}
  method config {config} {}


  method connect {} {
   $neu_name connect
  }


  method disconnect {} {
   $neu_name disconnect
  }


  method start {} {
   $neu_name start
  }


  method stop {} {
   $neu_name stop
  }


  method status {} {
   $neu_name status
  }


  method reset {} {
   $neu_name reset
  }


  method download {{tr_list {}} {set_list {}}} {
   $neu_name download $tr_list $set_list
  }


  method get_magnete_num {} {
    return [$neu_name get_magnete_num]
  }


  method set_setting {{t {}} {s {}}} {
   $neu_name set_setting $t $s
  }


  method data_init {w st} {
    $neu_name data_init $w $st
  }


  method tr_init {tr typ adr val} {
    $neu_name tr_init $tr $typ $adr $val
  }


  method save_object {fileid} {}
  method get_setting {} {return [$neu_name get_setting]}
  method get_timerecords {} {return [$neu_name get_setting]}
  method get_target {} {return [$neu_name get_setting]}
  method get_isconnected {} {return [$neu_name get_setting]}
  method set_isconnected {isconn} {$neu_name set_isconnected $isconn}
  method get_neuname {} {return $neu_name}


  public neu_name
}
