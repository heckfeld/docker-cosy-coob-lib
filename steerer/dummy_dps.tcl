# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/dummy_dps.tcl,v 1.6 2012/04/11 09:48:45 tine Exp $
itcl_class dummy_dps_class {

  constructor {config} {

global testbetrieb
if {$testbetrieb} {
puts "dummy_dps_class ($this)"
}
    ### Tine: 18.01.2012
    ### Netzgeraete sind noch im Crate, sollen aber nicht mehr bedient werden!

    if {[string compare "$this" "SH03"] == 0 \
     || [string compare "$this" "SV04"] == 0} {
      global aus dc

      set aus($this) 1
      set dc($this) 0
    }
  }; #constructor

  destructor {}
  method config {config} {}

  method soll_check {args} {
    return 0
  }

  method top_check {args} {
    return 0
  }

  method set_top {{t 0}} {}
  method set_beulenscale {enum s} {}
  method set_wedelscale {enum s} {}
  method set_download {n} {}
  method rech_fgen {{enum ""}} {}
  method data_init {off dcval} {}
  method data_num_init {num s t bs ws cb cw go gb gw rf} {}
  method data_fgen_init {num zeile zeit wert} {}
  method save_object {fileid savelist} {}
  method uebernehmen {to from} {}
  method make_punkte {enum} {}
  method modell {op val enum mode} {return 0}
  method set_sollval {enum {s ""}} {}
  method set_topval {enum {t 0}} {}
  method set_ographwaehl {enum val} {}
  method set_bgraphwaehl {enum val} {}
  method set_wgraphwaehl {enum val} {}
  method set_rfgentyp {enum typ} {}
  method set_tgesamt {num} {}
  method sum_fgen {num} {return 0}

  method get_name_num {} {
    # Falls nicht Backlegwinding-Steerer Anke
    if {[string first BLW-D $this] == -1} {
      return [string range $this 2 3]
    } else {
      return [string range $this 5 6]
    }
  }

  method set_null {args} {return 0}
  method set_topnull {enum} {}
  method is0fgenfile {file} {return 0}
  method cmp_fgen {num} {}
  method go123 {} {}
  method single_go {} {}
  method single_startup {} {}
  method save_werte {} {}
  method undo_werte {} {}
  method startup_abbruch {} {}
  method startwerte_pruefen {} {}
  method fgenlaenge_pruefen {} {}
  method diff_startwerte {elist} {}
  method convert2bit {s} {}
  method set_soll {s {akt 1}} {}
  method set_edit_exp {} {}
  method get_top {enum} {}
  method get_soll {enum} {}
  method get_crate {} {}
  method set_crate {c} {}
  method get_connum {} {}
  method get_num {} {}
  method get_rmin {} {}
  method get_rmax {} {}
  method get_scmin {} {}
  method get_scmax {} {}
  method get_beulenscale {enum} {}
  method get_wedelscale {enum} {}
  method set_lfgentyp {args} {}
  method get_rfgentyp {enum} {}
  method get_waehl {} {}

  ###
  method get_was_dc {} {return 0}
  ###

  method set_dorech {d} {}
  method get_dorech {} {}
  method set_rwerte {args} {}
  method set_lwerte {args} {}
  method set_aktpunkt {enum a} {}
  method get_aktpunkt {enum} {}
  method get_xmax {enum} {}
  method get_x {enum} {}
  method get_y {enum} {}
  method get_ographwaehl {enum} {}
  method get_bgraphwaehl {enum} {}
  method get_wgraphwaehl {enum} {}
  method get_magnetegroup {} {}
  method get_tgesamt {enum} {}
  method set_isloaded {enum val} {}
  method get_isloaded {enum} {return 0}
  method set_egraphwaehl {args} {}
  method get_commandok {} {}

}
