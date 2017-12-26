#
# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/database.tcl,v 1.2 2012/01/20 12:56:33 tine Exp $
#

itcl_class database_class {

  constructor {} {
    global NAME max_exp PGHOST env

    set PGHOST $env(PGHOST)

    if {![string compare $NAME steererh]} {
      ### steererh
      set pocos \
       [lsort [concat [itcl_info objects -isa dps_class] {SH03 SH25 SH27}]]

    } elseif {![string compare $NAME steererv]} {
      ### steererv
      #set pocos [lsort [concat [itcl_info objects -isa dps_class] {SV26 SV28}]]
      set pocos [lsort [concat [itcl_info objects -isa dps_class] {SV04}]]

    } else {
      set pocos [lsort [itcl_info objects -isa dps_class]]
    }

    set crates [lsort [itcl_info objects -isa crate_class]]
    set trxlist [lsort [itcl_info objects -isa trx_class]]

   ### Fuer Tabelle gui (ehem. in der gui-DB)
    set gui_params [list exp_string stop akt_exp edit_exp]

    set gui_default(exp_string) 1
    set gui_default(stop) true
    set gui_default(akt_exp) 1
    set gui_default(edit_exp) 1

   ### Fuer Tabelle gui_tr (ehem. in der gui-DB)
    set guitr_params [list typ adresse wert]

    set guitr_default(typ) ""
    set guitr_default(adresse) -1
    set guitr_default(wert) -1

   ### Fuer Tabelle steerer_gui<number> (ehem. in der steerer-DB)
    set gui_num_params [list obegin oup otop odown oend btopstrom bbegin bup \
                        btop bdown wtopstrom wbegin wup1 wtop wdown wntop wup2 \
                        bexist wexist]

    set gui_num_default(obegin) 1
    set gui_num_default(oup) 1
    set gui_num_default(otop) 1
    set gui_num_default(odown) 1
    set gui_num_default(oend) 1
    set gui_num_default(btopstrom) 1
    set gui_num_default(bbegin) 1
    set gui_num_default(bup) 1
    set gui_num_default(btop) 1
    set gui_num_default(bdown) 1
    set gui_num_default(wtopstrom) 1
    set gui_num_default(wbegin) 1
    set gui_num_default(wup1) 1
    set gui_num_default(wtop) 1
    set gui_num_default(wdown) 1
    set gui_num_default(wntop) 1
    set gui_num_default(wup2) 1
    set gui_num_default(bexist) true
    set gui_num_default(wexist) true

   ### Fuer Tabellen blwanke, blwsteer, ecsteer, steererh, steererv
   ### (ehem. in der steerer-DB)
    set poco_params [list aus dc]

    set poco_default(aus) true
    set poco_default(dc) true

   ### Fuer Tabellen blwanke[1-9], blwsteer[1-9], ecsteer[1-9], steererh[1-9],
   ### steererv[1-9] (ehem. in der steerer-DB)
    set poco_num_params [list soll top beulenscale wedelscale beulenselect \
                         wedelselect orbitgraph beulegraph wedelgraph \
                         rechnen]

    set poco_num_default(soll) 0
    set poco_num_default(top) 0
    set poco_num_default(beulenscale) 1
    set poco_num_default(wedelscale) 1
    set poco_num_default(beulenselect) 0
    set poco_num_default(wedelselect) 0
    set poco_num_default(orbitgraph) 0
    set poco_num_default(beulegraph) 0
    set poco_num_default(wedelgraph) 0
    set poco_num_default(rechnen) o

   ### Fuer Tabellen blwanke[1-9]_fgen, blwsteer[1-9]_fgen, ecsteer[1-9]_fgen,
   ### steererh[1-9]_fgen, steererv[1-9]_fgen
   ### (ehem. in der steerer-DB)
    set poco_fgen_params [list zeit wert]
    set poco_fgen_default(zeit) 1
    set poco_fgen_default(wert) 1

   ### Fuer Tabelle trx (ehem. in der trx-DB)
    set trx_params [list waehl stop]
    set trx_default(waehl) true
    set trx_default(stop) true

   ### Fuer Tabelle trx_tr (ehem. in der trx-DB)
    set trxtr_params [list typ adresse wert]
    set trxtr_default(typ) ""
    set trxtr_default(adresse) -1
    set trxtr_default(wert) -1

    connect_db cosy
  }


  destructor {}


  method init {} {
    global BITMAPDIR NAME spalte max_exp TITLE

    if {[catch {pg_select $cosy_handle "SELECT * FROM gui" spalte "$this \
                gui_werte"} ret_string]} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[catch {pg_select $cosy_handle "SELECT * FROM steerer_gui$i" spalte \
                                    "$this gui_num_werte $i"} ret_string]} {
        tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                  0 Ok
      }
    }

    if {[catch {pg_select $cosy_handle "SELECT * FROM gui_tr" spalte \
                "$this guitr_werte"} ret_string]} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    }

    # Alle Crates connecten und deren Status abfragen
    foreach elem [lsort [itcl_info objects -class crate_class]] {
      $elem connect
      $elem get_info
    }

    if {[catch {pg_select $cosy_handle "SELECT * FROM $NAME" spalte "$this \
                poco_werte"} ret_string]} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    }

    for {set i 1} {$i <= $max_exp} {incr i} {
      if {[catch {pg_select $cosy_handle "SELECT * FROM $NAME$i" spalte \
                  "$this poco_num_werte $i"} ret_string]} {
        tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                  0 Ok
      }
    }

    for {set i 1} {$i <= $max_exp} {incr i} {

      if {[catch {pg_select $cosy_handle "SELECT * FROM $NAME${i}_fgen" \
                  spalte "$this poco_fgen_werte $i"} ret_string]} {
        tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                  0 Ok
      }
    }

    foreach elem $crates {
      $elem data_init
    }

    query_tx

    # Timing-Records der Timing-Receiver
    if {[catch {pg_select $cosy_handle "SELECT * FROM trx_tr" spalte "$this \
                trxtr_werte"} ret_string]} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    }

    # Timing-Receiver
    if {[catch {pg_select $cosy_handle "SELECT * FROM trx" spalte "$this \
                trx_werte"} ret_string]} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    }

    # Ok-Knopf im Master
    master gruppe
  }


  method gui_werte {} {
    global spalte BITMAPDIR NAME

    if {![string compare [string trim $spalte(name)] $NAME]} {
      foreach elem $gui_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval [string trim $spalte(gruppe)] data_init $arg_list
    }
  }


  method gui_num_werte {num} {
    global spalte BITMAPDIR NAME

    if {![string compare [string trim $spalte(name)] $NAME]} {
      foreach elem $gui_num_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval [string trim $spalte(gruppe)] data_num_init $num $arg_list
    }
  }


  method guitr_werte {} {
    global spalte BITMAPDIR NAME

    set arg_list [string trim $spalte(tr)]

    if {![string compare [string trim $spalte(name)] $NAME]} {
      foreach elem $guitr_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval tim tr_init $arg_list
    }
  }


  method poco_werte {} {
    global spalte BITMAPDIR TITLE

    if {![lsearch $pocos [string trim $spalte(name)]] != -1} {
      foreach elem $poco_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval $spalte(name) data_init $arg_list
    } else {
      tk_dialog .dia "$TITLE" "Datenbank: Fehlerhafter Eintrag $spalte(name)\
                in der Steerer-Datenbank!" @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  method poco_num_werte {num} {
    global spalte BITMAPDIR TITLE

    if {![lsearch $pocos [string trim $spalte(name)]] != -1} {
      foreach elem $poco_num_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval $spalte(name) data_num_init $num $arg_list
    } else {
      tk_dialog .dia "$TITLE" "Datenbank: Fehlerhafter Eintrag $spalte(name)\
                in der Steerer-Datenbank fuer Experiment $num!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  method poco_fgen_werte {num} {
    global spalte BITMAPDIR TITLE

    if {![lsearch $pocos [string trim $spalte(name)]] != -1} {
      foreach elem $poco_fgen_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval $spalte(name) data_fgen_init $num [string trim $spalte(zeile)] \
           $arg_list
    } else {
      tk_dialog .dia "$TITLE" "Datenbank: Fehlerhafter Eintrag $spalte(name)\
                in der Steerer-Datenbank fuer Experiment $num!" \
                @$BITMAPDIR/smily.xpm 0 Ok
    }
  }


  method trx_werte {args} {
    global spalte BITMAPDIR

    if {[lsearch $trxlist [string trim $spalte(name)]] != -1} {
      foreach elem $trx_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval [string trim $spalte(name)] data_init $arg_list
    }
  }


  method trxtr_werte {args} {
    global spalte BITMAPDIR

    set arg_list [string trim $spalte(tr)]

    if {[lsearch $trxlist [string trim $spalte(name)]] != -1} {
      foreach elem $trxtr_params {
        lappend arg_list [string trim $spalte($elem)]
      }

      eval [string trim $spalte(name)] tr_init $arg_list
    }
  }


  # Zugriff auf Tabelle poco
  method set_poco_aus_ein {magnet off} {
    set offval [manage convert2db_bool $off]
    update_tab poco $magnet "UPDATE poco SET aus=$offval WHERE name='$magnet'"
  }

  # Zugriff auf Tabelle poco
  method set_poco_dc_sync {magnet dc} {
    set dcval [manage convert2db_bool $dc]
    update_tab poco $magnet "UPDATE poco SET dc=$dcval WHERE name='$magnet'"
  }


  # Zugriff auf Tabelle $NAME
  method set_aus_ein {magnet off} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Netzgeraet ein- bzw. ausschalten.\
                $magnet existiert nicht und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # off muss 0 oder 1 sein
    if {[manage is_no_boolean $off]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet ein- bzw. ausschalten. Der\
                Wert $off ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set offval [manage convert2db_bool $off]
    update_poco $magnet "UPDATE $NAME SET aus=$offval WHERE name='$magnet'"
  }


  method set_dc_sync {magnet dc} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Netzgeraet in Dc- bzw. Sync-Mode\
                setzen. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # dc muss 0 oder 1 sein
    if {[manage is_no_boolean $dc]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Dc- bzw. Sync-Mode\
                setzen. Der Wert $dc ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set dcval [manage convert2db_bool $dc]
    update_poco $magnet "UPDATE $NAME SET dc=$dcval WHERE name='$magnet'"
  }


  method set_soll {magnet num soll} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Sollwert setzen. $magnet existiert\
                nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Sollwert fuer $magnet setzen. Die\
                Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # soll muss ein numerischer Wert sein
    if {[catch {expr $soll} val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Sollwert fuer $magnet in Experiment\
                $num. Der Wert $soll ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_num $magnet $num "UPDATE $NAME$num SET soll=$val WHERE \
                    name='$magnet'"
  }


  method set_top {magnet num top} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Topwert setzen. $magnet existiert\
                nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Topwert fuer $magnet setzen. Die\
                Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # top muss ein numerischer Wert sein
    if {[catch {expr $top} val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Topwert fuer $magnet in Experiment\
                $num. Der Wert $top ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_num $magnet $num "UPDATE $NAME$num SET top=$val WHERE \
                    name='$magnet'"
  }


  method set_beulenscale {magnet num scale} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Beule fuer Netzgeraet\
                setzen. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Beule fuer $magnet. Die\
                Experimentnummer $num ist fehlerhaft und wird nicht in\
                die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # scale muss ein numerischer Wert sein
    if {[catch {expr $scale} val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Beule fuer $magnet in\
                Experiment $num. Der Wert $scale ist fehlerhaft und wird\
                nicht in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm \
                0 Ok
      return
    }

    update_poco_num $magnet $num "UPDATE $NAME$num SET beulenscale=$val \
                    WHERE name='$magnet'"
  }


  method set_beulensel {magnet num mode} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Netzgeraet in Beule an- bzw.\
                abwaehlen! $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Beule an- bzw. abwaehlen.\
                Die Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # mode muss 0 oder 1 sein
    if {[manage is_no_boolean $mode]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Beule fuer Experiment\
                $num an- bzw. abwaehlen! Der Wert $mode ist fehlerhaft Wert\
                und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set modeval [manage convert2db_bool $mode]
    update_poco_num $magnet $num "UPDATE $NAME$num SET beulenselect=$modeval \
                    WHERE name='$magnet'"
  }


  method set_wedelscale {magnet num scale} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Wedel fuer Netzgeraet\
                setzen. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Wedel fuer $magnet. Die\
                Experimentnummer $num ist fehlerhaft und wird nicht in\
                die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # scale muss ein numerischer Wert sein
    if {[catch {expr $scale} val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Skalierung Wedel fuer $magnet in\
                Experiment $num. Der Wert $scale ist fehlerhaft und wird nicht\
                in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_num $magnet $num "UPDATE $NAME$num SET wedelscale=$val \
                    WHERE name='$magnet'"
  }


  method set_wedelsel {magnet num mode} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Netzgeraet in Wedel an- bzw.\
                abwaehlen! $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Wedel an- bzw. abwaehlen.\
                Die Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # mode muss 0 oder 1 sein
    if {[manage is_no_boolean $mode]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Wedel fuer Experiment\
                $num an- bzw. abwaehlen! Der Wert $mode ist fehlerhaft Wert\
                und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set modeval [manage convert2db_bool $mode]
    update_poco_num $magnet $num "UPDATE $NAME$num SET wedelselect=$modeval \
                    WHERE name='$magnet'"
  }


  method set_graphsel {typ magnet num mode} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Netzgeraet in Graphik an- bzw.\
                abwaehlen. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # typ darf nur orbit, beule oder einzel eines Einzelviews sein sein
    regsub {orbit|beule|einzel|wedel} $typ "" out
    if {[string length $out]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Graphik an- bzw.\
                abwaehlen. Typ $typ ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Graphik an- bzw.\
                abwaehlen. Die Experimentnummer $num ist fehlerhaft und wird\
                nicht in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # mode muss 0 oder 1 sein
    if {[manage is_no_boolean $mode]} {
      tk_dialog .dia "$TITLE" "Datenbank: $magnet in Graphik fuer Experiment\
                $num an- bzw. abwaehlen! Der Wert $mode ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set modeval [manage convert2db_bool $mode]
    update_poco_num $magnet $num "UPDATE $NAME$num SET ${typ}graph=$modeval \
                    WHERE name='$magnet'"
  }


  method set_rechne {magnet num type} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Fgenfile rechnen. $magnet existiert\
                nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Fgenfile fuer $magnet rechnen. Die\
                Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # type muss o, b, w oder e sein
    if {[manage is_no_fgentype $type]} {
      tk_dialog .dia "$TITLE" "Datenbank: Fgenfile fuer $magnet in Experiment\
                $num rechnen. Der Wert $type ist fehlerhaft und wird nicht in\
                die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_num $magnet $num "UPDATE $NAME$num SET rechnen='$type' \
                    WHERE name='$magnet'"
  }


  method set_orbit {typ num val} {
    global BITMAPDIR NAME TITLE

    if {[string compare $typ begin] && [string compare $typ up] && \
        [string compare $typ top] && [string compare $typ down] && \
        [string compare $typ end]} {
      tk_dialog .dia "$TITLE" "Datenbank: Orbitrechnung. Der Parameter $typ\
                existiert nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Orbitrechnung fuer Paramter $typ.\
                Die Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss ein numerischer Wert sein
    if {[catch {expr $val} neuval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert $param in Orbitrechnung fuer\
                Experiment $num. Der Wert $val ist fehlerhaft und wird nicht\
                in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui_num $num "UPDATE steerer_gui$num SET o$typ=$neuval \
                   WHERE name='$NAME' AND gruppe='group'"
  }


  method set_beule {typ num val} {
    global BITMAPDIR NAME TITLE

    if {[string compare $typ btopstrom] && [string compare $typ bbegin] && \
        [string compare $typ bup] && [string compare $typ btop] && \
        [string compare $typ bdown]} {
      tk_dialog .dia "$TITLE" "Datenbank: Beulenrechnung. Der Parameter $typ\
                existiert nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Beulenrechnung fuer Paramter $typ.\
                Die Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss ein numerischer Wert sein
    if {[catch {expr $val} neuval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert $param in Beulenrechnung fuer\
                Experiment $num. Der Wert $val ist fehlerhaft und wird nicht\
                in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui_num $num "UPDATE steerer_gui$num SET $typ=$neuval \
                   WHERE name='$NAME' AND gruppe='group'"
  }


  method set_wedel {typ num val} {
    global BITMAPDIR NAME TITLE

    if {[string compare $typ wtopstrom] && [string compare $typ wbegin] && \
        [string compare $typ wup1] && [string compare $typ wtop] && \
        [string compare $typ wdown] && [string compare $typ wntop] && \
                                           [string compare $typ wup2]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wedelrechnung. Der Parameter $typ\
                existiert nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wedelrechnung fuer Paramter $typ.\
                Die Experimentnummer $num ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss ein numerischer Wert sein
    if {[catch {expr $val} neuval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert $param in Wedelrechnung fuer\
                Experiment $num. Der Wert $val ist fehlerhaft und wird nicht\
                in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui_num $num "UPDATE steerer_gui$num SET $typ=$neuval \
                   WHERE name='$NAME' AND gruppe='group'"
  }


  method set_einzel_time {magnet num zeile val} {
    global BITMAPDIR NAME  TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor.\
                $magnet existiert nicht und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor\
                fuer $magnet. Die Experimentnummer $num ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls zeile keine ganze Zahl ist
    if {[manage is_no_posint $zeile]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor\
                fuer $magnet. Die Zeilennummer $zeile ist fehlerhaft und wird\
                nicht in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss ein numerischer Wert sein
    if {[catch {expr $val} neuval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor\
                fuer $magnet in Zeile $zeile. Der Wert $val ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_fgen $magnet $num $zeile "UPDATE $NAME${num}_fgen SET \
                     zeit=$neuval WHERE name='$magnet' AND zeile=$zeile"
  }


  method clear_einzel_time {magnet num} {
    global BITMAPDIR NAME  TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor.\
                $magnet existiert nicht und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit im FgenEditor\
                fuer $magnet. Die Experimentnummer $num ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    destroy_db cosy "DELETE FROM $NAME${num}_fgen WHERE name='$magnet'"
  }


  method set_einzel_ampl {magnet num zeile val} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor fuer $magnet. Die Experimentnummer $num ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls zeile keine ganze Zahl ist
    if {[manage is_no_posint $zeile]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor fuer $magnet. Die Zeilennummer $zeile ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss ein numerischer Wert sein
    if {[catch {expr $val} neuval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor fuer $magnet in Zeile $zeile. Der Wert $val ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_fgen $magnet $num $zeile "UPDATE $NAME${num}_fgen SET \
                     wert=$neuval WHERE name='$magnet' AND zeile=$zeile"
  }


  method set_einzel_time_ampl {magnet num zeile time ampl} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer Zeit und Amplitude im\
                FgenEditor. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit und Amplitude im\
                FgenEditor fuer $magnet. Die Experimentnummer $num ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls zeile keine ganze Zahl ist
    if {[manage is_no_posint $zeile]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit und Amplitude im\
                FgenEditor fuer $magnet. Die Zeilennummer $zeile ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # time muss ein numerischer Wert sein
    if {[catch {expr $time} tval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit und Amplitude im\
                FgenEditor fuer $magnet in Zeile $zeile. Der Wert fuer die\
                Zeit ($time) ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # ampl muss ein numerischer Wert sein
    if {[catch {expr $ampl} aval]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Zeit und Amplitude im\
                FgenEditor fuer $magnet in Zeile $zeile. Der Wert fuer die\
                Amplitude ($ampl) ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_poco_fgen $magnet $num $zeile "UPDATE $NAME${num}_fgen SET \
                     zeit=$tval, wert=$aval WHERE name='$magnet' AND \
                     zeile=$zeile"
  }


  method delete_einzel {magnet num zeile} {
    global BITMAPDIR NAME TITLE

    # Falls magnet kein Netzgeraet ist
    if {[lsearch $pocos $magnet] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor. $magnet existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor fuer $magnet. Die Experimentnummer $num ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls zeile keine ganze Zahl ist
    if {[manage is_no_posint $zeile]} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer die Amplitude im\
                FgenEditor fuer $magnet. Die Zeilennummer $zeile ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    destroy_db cosy "DELETE FROM $NAME${num}_fgen WHERE name='$magnet' AND \
                    zeile=$zeile"
  }


  method set_exist {type num exist} {
    global BITMAPDIR NAME TITLE

    if {[string compare $type beule] && [string compare $type wedel]} {
      tk_dialog .dia "$TITLE" "Datenbank: Existenz des Fensters fuer\
                Beulenrechnung. Der angegebene Typ $type ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # Falls num != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $num]} {
      tk_dialog .dia "$TITLE" "Datenbank: Existenz des Fensters fuer\
                Beulenrechnung. Die Experimentnummer $num ist fehlerhaft und\
                wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # exist muss 0 oder 1 sein
    if {[manage is_no_boolean $exist]} {
      tk_dialog .dia "$TITLE" "Datenbank: Existenz des Fensters fuer\
                Beulenrechnung fuer Experiment $num. Der Wert $exist ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set existval [manage convert2db_bool $exist]
    update_gui_num $num "UPDATE steerer_gui$num SET [string index $type \
                   0]exist=$existval WHERE name='$NAME' AND gruppe='group'"
  }


  method set_group_explist {e} {
    global BITMAPDIR NAME max_exp TITLE

    if {[manage is_no_expstring $e]} {
      tk_dialog .dia "$TITLE" "Datenbank: Experimentfolge. Der Wert $e ist\
                fehlerhaft und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui "UPDATE gui SET exp_string='$e' WHERE name='$NAME' AND \
               gruppe='group'"
  }


  method set_akt_exp {val} {
    global BITMAPDIR NAME TITLE

    # Falls val != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Aktuelle Experimentnummer. Der Wert\
                $val ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui "UPDATE gui SET akt_exp=$val WHERE name='$NAME' AND \
            gruppe='group'"
  }


  method set_edit_exp {val} {
    global BITMAPDIR NAME TITLE

    # Falls val != 1, 2 ... max_exp ist
    if {[manage is_no_expnum $val]} {
      tk_dialog .dia "$TITLE" "Datenbank: Editierte Experimentnummer. Der Wert\
                $val ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_gui "UPDATE gui SET edit_exp=$val WHERE name='$NAME' AND \
            gruppe='group'"
  }


  method set_tim_stop_start {s} {
    global BITMAPDIR NAME TITLE

    # s muss 0 oder 1 sein
    if {[manage is_no_boolean $s]} {
      tk_dialog .dia "$TITLE" "Datenbank: Timing-Receiver in der TimsRxList\
                starten bzw. stoppen. Der Wert $s fehlerhaft und wird nicht in\
                die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set sval [manage convert2db_bool $s]
    update_gui "UPDATE gui SET stop=$sval WHERE name='$NAME' AND gruppe='group'"
  }


  method set_record {tr type adr val} {
    global BITMAPDIR NAME TITLE

    # typ muss t1, t2, st oder -1 sein
    regsub {t1|t2|st|-1} $type "" out
    if {[string length $out]} {
      tk_dialog .dia "$TITLE" "Datenbank: Timing-Record $tr in TimsRxList. Der\
                Wert fuer den Typ $type ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # adr muss eine ganze Zahl sein sein
    if {[catch {expr $adr} aval] && ($adr == [expr int($adr)])} {
      tk_dialog .dia "$TITLE" "Datenbank: Adresse fuer Timing-Record $tr in\
                TimsRxList. Der Wert $adr ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss eine ganze Zahl sein sein
    if {[catch {expr $val} vval] && ($val == [expr int($val)])} {
      tk_dialog .dia "$TITLE" "Datenbank: Wert fuer Timing-Record $tr in\
                TimsRxList. Der Wert $val ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_guitr $tr "UPDATE gui_tr SET typ='$type', adresse=$aval, wert=$vval \
                 WHERE name='$NAME' AND gruppe='group' AND tr='$tr'"
  }


  method remove_record {tr} {
    global NAME

    destroy_db cosy "DELETE FROM gui_tr WHERE name='$NAME' AND gruppe='group' \
                   AND tr='$tr'"
  }


  method remove_all {} {
    global NAME

    destroy_db cosy "DELETE FROM gui_tr WHERE name='$NAME' AND gruppe='group'"
  }


  method set_timing_waehl {trx waehl} {
    global BITMAPDIR TITLE

    # Falls trx kein Timing-Receiver ist
    if {[lsearch $trxlist $trx] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Timing-Receiver an- bzw. abwaehlen.\
                Der Timing-Receiver $trx existiert nicht und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # waehl muss 0 oder 1 sein
    if {[manage is_no_boolean $waehl]} {
      tk_dialog .dia "$TITLE" "Datenbank: Timing-Receiver $trx an- bzw.\
                abwaehlen. Der Wert $waehl ist fehlerhaft und wird nicht in\
                die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set waehlval [manage convert2db_bool $waehl]
    update_trx $trx "UPDATE trx SET waehl=$waehlval WHERE name='$trx'"
  }


  method clear_time_records {trx} {
    global BITMAPDIR TITLE

    # Falls trx kein Timing-Receiver ist
    if {[lsearch $trxlist $trx] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Loeschen von Timing-Records fuer\
                einen Timing-Receiver. Der Timing-Receiver $trx existiert\
                nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    destroy_db cosy "DELETE FROM trx_tr WHERE name='$trx'"
  }


  method create_time_records {trx tr type adr val} {
    global BITMAPDIR TITLE

    # Falls trx kein Timing-Receiver ist
    if {[lsearch $trxlist $trx] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Hinzufuegen von Timing-Records fuer\
                einen Timing-Receiver. Der Timing-Receiver $trx existiert\
                nicht und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # typ muss t1, t2, st oder -1 sein
    regsub {t1|t2|st|-1} $type "" out
    if {[string length $out]} {
      tk_dialog .dia "$TITLE" "Datenbank: Timing-Record $tr setzen. Der Wert\
                fuer den Typ $type ist fehlerhaft und wird nicht in die\
                Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # adr muss eine ganze Zahl sein sein
    if {[catch {expr $adr} aval] && ($adr == [expr int($adr)])} {
      tk_dialog .dia "$TITLE" "Datenbank: Adresse fuer Timing-Record $tr. Der\
                Wert $adr ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # val muss eine ganze Zahl sein sein
    if {[catch {expr $val} vval] && ($val == [expr int($val)])} {
      tk_dialog .dia "$TITLE" "Datenbank: Adresse fuer Timing-Record $tr. Der\
                Wert $val ist fehlerhaft und wird nicht in die Datenbank\
                eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    update_trxtr $trx $tr "UPDATE trx_tr SET typ='$type', adresse=$aval,\
                 wert=$vval WHERE name='$trx' AND tr='$tr'"
  }


  method set_timing_start_stop {trx s} {
    global BITMAPDIR TITLE

    # Falls trx kein Timing-Receiver ist
    if {[lsearch $trxlist $trx] == -1} {
      tk_dialog .dia "$TITLE" "Datenbank: Starten bzw. Stoppen eines\
                Timing-Receivers. Der Timing-Receiver $trx existiert nicht\
                und wird nicht in die Datenbank eingetragen!" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    # s muss 0 oder 1 sein
    if {[manage is_no_boolean $s]} {
      tk_dialog .dia "$TITLE" "Datenbank: Starten bzw. Stoppen des\
                Timing-Receivers $trx. Der Wert $s ist fehlerhaft und wird\
                nicht in die Datenbank eingetragen!" @$BITMAPDIR/smily.xpm 0 Ok
      return
    }

    set sval [manage convert2db_bool $s]
    update_trx $trx "UPDATE trx SET stop=$sval WHERE name='$trx'"
  }


  ############################
  # Zugriff auf Tabelle $table
  method tab_einfuegen {table magnet} {
    global BITMAPDIR TITLE

    set values '$magnet'

    foreach elem $poco_params {
      append values ,'$poco_default($elem)'
    }

global testbetrieb
if {$testbetrieb} {
puts "tab_einfuegen ($table,$magnet) VALUES ($values)"
}
    if {[catch {pg_exec $cosy_handle "INSERT INTO $table VALUES ($values);"} \
                                                                      erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [tab_einfuegen $table $magnet]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $magnet konnte nicht in die \
                  $table-Tabelle eingefuegt werden!" @$BITMAPDIR/smily.xpm \
                  0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0

  }; #tab_einfuegen

  # Zugriff auf Tabelle $table
  method update_tab {table magnet command} {
    global BITMAPDIR TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_tab $table $magnet $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $magnet konnte in \
                  der $table-Tabelle nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![tab_einfuegen $table $magnet]} {
        update_tab $table $magnet $command
      }
    }
global testbetrieb
if {$testbetrieb} {
puts "update_tab ($table,$magnet,$command)"
}
  }; #update_tab
  ############################


  # Zugriff auf Tabelle $NAME
  method update_poco {magnet command} {
    global BITMAPDIR NAME TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_poco $magnet $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $magnet konnte in\
                  der $NAME-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![poco_einfuegen $magnet]} {
        update_poco $magnet $command
      }
    }
  }


  method update_poco_num {magnet num command} {
    global BITMAPDIR NAME TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_poco_num $magnet $num $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $magnet konnte in\
                  der $NAME$num-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![poco_num_einfuegen $magnet $num]} {
        update_poco_num $magnet $num $command
      }
    }
  }


  method update_poco_fgen {magnet num zeile command} {
    global BITMAPDIR NAME TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_poco_fgen $magnet $num $zeile $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $magnet und Zeile\
                  $zeile konnte in der $NAME${num}_fgen-Datenbank nicht\
                  aktualisiert werden!" @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![poco_fgen_einfuegen $magnet $num $zeile]} {
        update_poco_fgen $magnet $num $zeile $command
      }
    }
  }


  method update_gui {command} {
    global BITMAPDIR NAME TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_gui $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $NAME konnte in\
                  der gui-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![gui_einfuegen]} {
        update_gui $command
      }
    }
  }


  method update_gui_num {num command} {
    global BITMAPDIR NAME TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_gui_num $num $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $NAME konnte in\
                  der steerer_gui$num-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![gui_num_einfuegen $num]} {
        update_gui_num $num $command
      }
    }
  }


  method update_guitr {tr command} {
    global BITMAPDIR TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_guitr $tr $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $tr konnte in der\
                  gui_tr-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![guitr_einfuegen $tr]} {
        update_guitr $tr $command
      }
    }
  }


  method update_trx {trx command} {
    global BITMAPDIR TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_trx $trx $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $trx konnte in\
                  der trx-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![trx_einfuegen $trx]} {
        update_trx $trx $command
      }
    }
  }


  method update_trxtr {trx tr command} {
    global BITMAPDIR TITLE

    if {[catch {pg_exec $cosy_handle $command} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        update_trxtr $trx $tr $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Der Eintrag fuer $trx und $tr\
                  konnte in der trxtr-Datenbank nicht aktualisiert werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      # Ueberpruefen, ob update erfolgreich war
      set stat [lindex [pg_result $erg -cmdstat] 1]
      pg_result $erg -clear

      if {!$stat && ![trxtr_einfuegen $trx $tr]} {
        update_trxtr $trx $tr $command
      }
    }
  }


  # Zugriff auf Tabelle $NAME
  method poco_einfuegen {magnet} {
    global NAME BITMAPDIR TITLE

    set values '$magnet'

    foreach elem $poco_params {
      append values ,'$poco_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO $NAME VALUES ($values);"} \
                                                                         erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [poco_einfuegen $magnet]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $magnet konnte nicht in die\
                  $NAME-Datenbank eingefuegt werden!" @$BITMAPDIR/smily.xpm \
                  0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method poco_num_einfuegen {magnet num} {
    global NAME BITMAPDIR TITLE

    set values '$magnet'

    foreach elem $poco_num_params {
      append values ,'$poco_num_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO $NAME$num VALUES \
                                                   ($values);"} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [poco_num_einfuegen $magnet $num]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $magnet konnte nicht in die\
                  $NAME$num-Datenbank eingefuegt werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method poco_fgen_einfuegen {magnet num zeile} {
    global NAME BITMAPDIR TITLE

    set values '$magnet',$zeile

    foreach elem $poco_fgen_params {
      append values ,'$poco_fgen_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO $NAME${num}_fgen VALUES \
                                                          ($values);"} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [poco_fgen_einfuegen $magnet $num $zeile]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $magnet konnte nicht in die\
                  $NAME${num}_fgen-Datenbank eingefuegt werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method gui_einfuegen {} {
    global NAME BITMAPDIR TITLE

    set values '$NAME','group'

    foreach elem $gui_params {
      append values ,'$gui_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO gui VALUES ($values);"} \
                                                                     erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [gui_einfuegen]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $NAME konnte nicht in die\
                  gui-Datenbank eingefuegt werden!" @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method gui_num_einfuegen {num} {
    global NAME BITMAPDIR TITLE

    set values '$NAME','group'

    foreach elem $gui_num_params {
      append values ,'$gui_num_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO steerer_gui$num VALUES \
                                                 ($values);"} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [gui_num_einfuegen]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $NAME konnte nicht in die\
                  steerer_gui$num-Datenbank eingefuegt werden!" \
                  @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method guitr_einfuegen {tr} {
    global NAME BITMAPDIR TITLE

    set values '$NAME','group','$tr'

    foreach elem $guitr_params {
      append values ,'$guitr_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO gui_tr VALUES ($values);"} \
                                                                      erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [guitr_einfuegen $tr]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $tr konnte nicht in die\
                  gui_tr-Datenbank eingefuegt werden!" @$BITMAPDIR/smily.xpm \
                  0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method trx_einfuegen {trx} {
    global TITLE BITMAPDIR

    set values '$trx'

    foreach elem $trx_params {
      append values ,'$trx_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO trx VALUES ($values);"} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [trx_einfuegen $trx]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $trx konnte nicht in die\
                  trx-Datenbank eingefuegt werden!" @$BITMAPDIR/smily.xpm 0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method trxtr_einfuegen {trx tr} {
    global TITLE BITMAPDIR

    set values '$trx','$tr'

    foreach elem $trxtr_params {
      append values ,'$trxtr_default($elem)'
    }

    if {[catch {pg_exec $cosy_handle "INSERT INTO trx_tr VALUES ($values);"} \
                                                                      erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db cosy]} {
        return [trxtr_einfuegen $trx $tr]
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: $trx und $tr konnten nicht in die\
                  trxtr-Datenbank eingefuegt werden!" @$BITMAPDIR/smily.xpm \
                  0 Ok
        return 1
      }
    }

    pg_result $erg -clear
    return 0
  }


  method destroy_db {type command} {
    global BITMAPDIR TITLE

    if {[catch {pg_exec [set ${type}_handle] "$command"} erg]} {
      # falls keine Verbindung mehr
      if {[no_connection $erg] && ![connect_db $type]} {
        destroy_db $type $command
      } else {
        tk_dialog .dia "$TITLE" "Datenbank: Aus der $type-Datenbank konnte ein\
                  Eintrag nicht enfernt werden!" @$BITMAPDIR/smily.xpm 0 Ok
      }
    } else {
      pg_result $erg -clear
    }
  }


  method connect_db {typ} {
    global BITMAPDIR PGHOST TITLE

    # falls noch alte Verbindung besteht, diese disconnecten
    if {"${typ}_handle" != "0"} {
      catch {pg_disconnect ${typ}_handle}
      set ${typ}_handle 0
    }

    set rc [catch {pg_connect $typ -host $PGHOST} ${typ}_handle]

    if {$rc} {
      tk_dialog .dia "$TITLE" "Datenbank: [set ${typ}_handle]" \
                @$BITMAPDIR/smily.xpm 0 Ok
      return 1
    }

    return 0
  }


  method query_tx {} {
    global BITMAPDIR TITLE

    # Timing-Sender-Datenbank
    set rc [catch {exec coob_tx -ntimstx} ret_string]

    if {$rc} {
      tk_dialog .dia "$TITLE" "Datenbank: $ret_string" @$BITMAPDIR/smily.xpm \
                0 Ok
    } else {
      group tx_init $ret_string
    }
  }


  method no_connection {erg} {
    global BITMAPDIR TITLE

    if {([string first "connection" $erg] != -1) || ([string first \
          "irst argument" $erg] != -1) || ([string first closed $erg] != -1)} {
      return 1
    } else {
      tk_dialog .dia "$TITLE" "Datenbank: $erg" @$BITMAPDIR/smily.xpm 0 Ok
      return 0
    }
  }


  protected pocos
  protected crates
  protected trxlist

  protected cosy_handle 0

  protected gui_params
  protected gui_num_params
  protected guitr_params
  protected poco_params
  protected poco_num_params
  protected poco_fgen_params
  protected trx_params
  protected trxtr_params
  protected gui_default
  protected gui_num_default
  protected guitr_default
  protected poco_default
  protected poco_num_default
  protected poco_fgen_default
  protected trx_default
  protected trxtr_default
}
