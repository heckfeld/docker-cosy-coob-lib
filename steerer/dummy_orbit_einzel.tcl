itcl_class dummy_orbit_einzel_class {
  constructor {config} {}
  destructor {}
  method config {config} {}
  method vinsert {} {}
  method vdelete {} {}
  method _delete {num} {}
  method init {b} {}
  method summe {} {}
  method show_graph {} {}
  method set_current {num} {}
  method rechne {} {}
  method eingabe_fehler {} {return 0}
  method gruppen_werte {} {}
  method init_zeile {num zeile t a} {}
  public prev {} {}
  public next {} {}
  method toggle {num} {}
  method _swap {num fg bg} {}
  method makeline {num} {}
  method newtime {num value} {}
  method newampl {num value} {return 0}
  method time_check {num args} {}
  method ampl_check {num args} {return 0}
  method save_object {fout savelist} {}
  method set_edit_exp {{num ""}} {}
  method uebernehmen {to from} {}
  method update_orbit_einzel {} {}
  method set_begin {exp wert} {}
  method set_up {exp wert} {}
  method set_top {exp wert} {}
  method set_down {exp wert} {}
  method set_end {exp wert} {}
  method set_timeval {exp zeile val} {}
  method set_amplval {exp zeile val} {}
  method get_box {} {}
  method set_zeilenmax {num val} {}
  method set_selected {num val} {}
  method set_graphsel {args} {return {}}
  method get_current {} {return 0}
}
