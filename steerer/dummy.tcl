itcl_class dummy_class {
  constructor {config} {
    global dc

    set dc($this) 1
  }


  destructor {}
  method config {config} {}


  method set_bgraphwaehl {args} {}
  method set_egraphwaehl {args} {}
  method set_ographwaehl {args} {}
  method set_wgraphwaehl {args} {}
  method set_rfgentyp {args} {}
  method set_beulenscale {args} {}
  method set_wedelscale {args} {}
  method set_sollval {args} {}
  method set_topval {args} {}
  method set_dorech {args} {}
  method set_top {args} {}
  method set_begin {args} {}
  method set_up {args} {}
  method set_down {args} {}
  method set_end {args} {}
  method set_graphsel {args} {}
  method set_lfgentyp {args} {}
  method set_download {args} {}
  method set_soll {args} {}
  method get_isloaded {args} {return 1}
  method get_num {} {return 1}
  method get_wedelscale {args} {return 0}
  method data_init {args} {}
  method convert2bit {args} {}
  method set_timeval {args} {}
  method set_zeilenmax {args} {}
  method set_selected {args} {}
  method get_aktpunkt {args} {return 1}
  method set_amplval {args} {}
  method get_xmax {args} {return 0}
  method get_x {args} {return 0}
  method get_crate {args} {return $this}
  method send_soll {args} {}
}
