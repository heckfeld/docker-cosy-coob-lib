# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/init.tcl,v 1.11 2012/04/26 09:19:02 tine Exp $

itcl_class init_class {

  constructor {name title filemag filetim filecrate fileustate} {
    global DATADIR SOURCEDIR LOGDIR stop explist akt_exp edit_exp expok NAME max_exp

    set max_exp 9
    set akt_exp 1
    set edit_exp 1
    set explist ""
    set expok 0


    set targetlist {}
    set steerer_list {}
    set dummy_steerer_list {}


    #################
    # ustate einlesen
    #################
    set fin [open "$DATADIR/$fileustate" "r"]

    gets $fin line
    gets $fin line
    while {![eof $fin]} {
      set split_list [split $line :]

      set magnet [lindex $split_list 0]
      set conn_string [lindex $split_list 1]
      set type [lindex $split_list 2]
      set target [lindex $split_list 3]

      # Falls Target noch nicht in der Liste steht
      if {[lsearch $targetlist $target] == -1} {
        lappend targetlist $target
      }

      usta_class $magnet -conn_string $conn_string \
                         -type $type \
                         -target $target

      gets $fin line
    }

    close $fin


    ##################
    # Steerer einlesen
    ##################
    set fin [open "$DATADIR/$filemag" "r"]

    gets $fin line
    gets $fin line
    while {![eof $fin]} {
      set split_list [split $line :]

      set magnet [lindex $split_list 0]
      set conn_num [lindex $split_list 1]
      set num [lindex $split_list 2]
      set type [lindex $split_list 3]
      set target [lindex $split_list 4]
      set rmin [lindex $split_list 5]
      set rmax [lindex $split_list 6]
      set scmin [lindex $split_list 7]
      set scmax [lindex $split_list 8]

      # Falls Target noch nicht in der Liste steht
      if {[lsearch $targetlist $target] == -1} {
        lappend targetlist $target
      }

      dps_class $magnet -conn_num $conn_num -num $num \
                        -rmin $rmin -rmax $rmax \
                        -scmin $scmin -scmax $scmax \
                        -group group -target $target

      lappend steerer_list $magnet
      gets $fin line
    }

    close $fin


    #######################
    # !!! Dummy-Steerer !!!
    #######################
    # Dummies schon hier, weil sonst set_crate ggfs. danach nicht
    # funktioniert, da Ansteuerung fuer das Netzgeraet ggfs. noch im Crate !!!
    if {![string compare $NAME steererh]} {
      lappend dummy_steerer_list SH03
      lappend dummy_steerer_list SH25
      lappend dummy_steerer_list SH27
      lappend dummy_steerer_list SH30

    } elseif {![string compare $NAME steererv]} {
      lappend dummy_steerer_list SV04
      lappend dummy_steerer_list SV40

    } elseif {![string compare $NAME blwsteer]} {
      lappend dummy_steerer_list BLW01
      lappend dummy_steerer_list BLW02
      lappend dummy_steerer_list BLW03
      lappend dummy_steerer_list BLW04
    }

    foreach elem $dummy_steerer_list {
      dummy_dps_class $elem
    }


    #################
    # Timing einlesen
    #################
    set fin [open "$DATADIR/$filetim" "r"]

    gets $fin line
    gets $fin line
    while {![eof $fin]} {
      set split_list [split $line :]

      set tr [lindex $split_list 0]
      set conn_string [lindex $split_list 1]
      set type [lindex $split_list 2]
      set target [lindex $split_list 3]
      set stop($tr) 2

      # Falls Target noch nicht in der Liste steht
      if {[lsearch $targetlist $target] == -1} {
        lappend targetlist $target
      }

      trx_class $tr -conn_string $conn_string \
                    -type $type \
                    -target $target

      gets $fin line
    }

    close $fin


    #################
    # Crates einlesen
    #################
    set fin [open "$DATADIR/$filecrate" "r"]

    gets $fin line
    gets $fin line
    while {![eof $fin]} {
      set split_list [split $line :]

      set crate [lindex $split_list 0]
      set conn_string [lindex $split_list 1]
      set type [lindex $split_list 2]
      set target [lindex $split_list 3]

      set magnete [lrange $split_list 4 end]

      set trx t[string tolower $crate]

      crate_class $crate -conn_string $conn_string \
                         -type $type \
                         -target $target \
                         -magnetlist $magnete \
                         -trx $trx -group group

      foreach elem $magnete {
        $elem set_crate $crate
      }

      gets $fin line
    }

    close $fin


    ###############


    # Magnetliste der Targets bestimmen
    foreach elem $targetlist {
      set magnetlist($elem) {}
    }

    set magnete [concat [itcl_info objects -isa usta_class] \
                [itcl_info objects -isa crate_class] \
                [itcl_info objects -isa trx_class]]

    foreach elem $magnete {
      set magnetlist([$elem get_target]) \
          [lappend magnetlist([$elem get_target]) $elem]
    }

    foreach elem $targetlist {
      target_class $elem -devicelist $magnetlist($elem) \
                         -ustate 1 \
                         -update_proc update_data
    }

    set crate_list [lsort [itcl_info objects -isa crate_class]]
    sw_trigger soft_trigger -crate_list $crate_list

    group_class group $title -magnete_group $steerer_list \
                             -wedel wedel \
                             -orbit orbit \
                             -beule beule \
                             -crates $crate_list

    orbit_class orbit group
    beule_class beule group
    wedel_class wedel group

    foreach elem $steerer_list {
      orbit_einzel_class orbit$elem -magnet $elem
    }

    # Dummies fuer orbit_einzel_class
    foreach elem $dummy_steerer_list {
      dummy_orbit_einzel_class orbit$elem
    }

    logclass tlog $LOGDIR/$name.log
    manage_steerer_class manage
    steerer_master master

    timsrxlist_class tim group
    database_class database


    # Dummies fuer Crates und Timing,
    # z.T. nur neuer Cratename,
    # z.T. ist das Crate ganz weg !!!

    if {![string compare $NAME steererh]} {

      dummy_crate_class SH29/30/31/33 -neu_name SH29/31/33
      dummy_trx_class tsh29/30/31/33 -neu_name tsh29/31/33

    } elseif {![string compare $NAME steererv]} {

      dummy_crate_class SV32/34 -neu_name SV30/32/34
      dummy_trx_class tsv32/34 -neu_name tsv30/32/34

      dummy_crate_class SV36/38/40 -neu_name SV36/38
      dummy_trx_class tsv36/38/40 -neu_name tsv36/38

    } elseif {![string compare $NAME blwsteer]} {

     ### Crate gibt es nicht mehr, deshalb andere Dummy-Klasse als oben,
     ### wo sich nur der Name bzw. die Bestueckung geaendert haben!
      real_dummy_crate_class BLW01/02/03/04
      real_dummy_trx_class tblw01/02/03/04
    }


    manage busy_hold
    update

    #################
    # Initialisierung
    #################
    # Ustates initialisieren
    foreach elem [lsort [itcl_info objects -isa usta_class]] {
      $elem init_state
    }

    # Datenbank auslesen
    database init

    # Aktualitaet der Fgenfiles ueberpruefen
    foreach elem $steerer_list {
      for {set i 1} {$i <= $max_exp} {incr i} {
        $elem cmp_fgen $i
      }
    }

    manage busy_release
  }


  destructor {}

}
