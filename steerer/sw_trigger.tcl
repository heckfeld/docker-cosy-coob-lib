# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/sw_trigger.tcl,v 1.1 2011/09/16 09:29:41 tine Exp $
itcl_class sw_trigger {
  constructor {config} {
    set method_list "\
       {Info}
    "
  }


  destructor {}
  method config {config} {}


  method trigger_list {} {return $method_list}


  ######### Trigger-Methoden ###########
  method Info {time duration cycle_number args} {
    foreach elem $crate_list {
      $elem set_pocostart
    }
  }


  protected method_list
  public crate_list {}
}
