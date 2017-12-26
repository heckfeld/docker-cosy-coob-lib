#!/usr/local/bin/pgwish -f
# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/blwsteer.tcl,v 1.3 2012/04/25 14:42:01 tine Exp $

global USERNAME testbetrieb
set USERNAME [exec whoami]
if {"$USERNAME" == "tine"} {
  puts ""
  puts "========================================================"
  puts "-- Test auf [exec hostname]"
  puts "-- USERNAME=$USERNAME"
  puts "--------------------------------------------------------"
  puts "-- !!!!!!!!!!!!!!!!!!!! Testbetrieb !!!!!!!!!!!!!!!!!!!!"
  puts "========================================================"
  set testbetrieb 1
} else {
  set testbetrieb 0
}

wm geometry . 400x210
wm minsize . 1 1

set foreground black
set background #c0c0c0
. config -background $background

option add *background $background
option add *foreground $foreground
option add *listBackground $background
option add *listForeground $foreground
option add *activeBackground $foreground
option add *activeForeground $background
option add *selectBackground $foreground
option add *selectForeground $background
option add *disabledForeground #b0b0b0
option add *selector red
option add *font -*-helvetica-medium-r-normal-*-14-*-*-*-*-*-*-*

set SOURCEDIR $env(SOURCEDIR)
set BACKUPDIR $env(BACKUPDIR)
set LOGDIR $env(LOGDIR)
set BITMAPDIR $env(BITMAPDIR)
set LIBDIR $env(LIBDIR)
set FGENDIR $env(FGENDIR)/steerer
set XMAD_HOME $env(XMAD_HOME)
set COSMO_SRC $env(COSMO_SRC)
set MODELLDIR $env(MODELLDIR)

set TITLE "Backlegwinding-Steerer"
set WORKSPACE "Backlegwinding-Steerer"
set NAME blwsteer

#
# !!! Testausgabe !!!
#
if {$testbetrieb} {
  puts ""
  puts "Oberflaeche zum Testen:"
  puts "$NAME: $TITLE"
  puts "============"
  puts "PATH=$env(PATH)"
  puts "============"
  puts "Testaufruf: fgendattcl (ohne irgenrwas) :[exec fgendattcl]"
  puts "------------"
}

########## WORKSPACE- und SERVER-FUNKTIONEN ############
source "$LIBDIR/Timeout.tcl"
source $LIBDIR/server.tcl
source $SOURCEDIR/sw_trigger.tcl
Timeout tt
server_class server -sw_timing on

source "$SOURCEDIR/setting.tcl"

#Browser fuer Datei mit Orbitoptimierung
source "$SOURCEDIR/Filebox.tcl"
source "$SOURCEDIR/filebox.tcl"

source "$LIBDIR/checkbutton.tcl"
source "$LIBDIR/tixinit.tcl"
source "$LIBDIR/bindings.tcl"
source "$LIBDIR/Value.tcl"
source "$LIBDIR/ScrollListBox.tcl"
source "$LIBDIR/ScrollSelectBox.tcl"
source "$LIBDIR/restore_single.tcl"
source "$LIBDIR/save_single.tcl"
source "$LIBDIR/delete_single.tcl"

if {$testbetrieb} {
  source "$SOURCEDIR/Target_all_dummy.tcl"
} else {
  source "$LIBDIR/Target_all.tcl"
}

source "$LIBDIR/log.tcl"
source "$LIBDIR/SelectBox_B1.tcl"
source "$LIBDIR/SelectBox_B2_mit_position.tcl"
source "$LIBDIR/manage.tcl"
source "$LIBDIR/dialog.tcl"
source "$SOURCEDIR/ustate.tcl"
source "$SOURCEDIR/trx.tcl"
source "$SOURCEDIR/trxview_value.tcl"
source "$SOURCEDIR/timsrxlist_value.tcl"
source "$SOURCEDIR/manage_steerer.tcl"
source "$SOURCEDIR/init.tcl"
source "$SOURCEDIR/master.tcl"
source "$SOURCEDIR/dps.tcl"
source "$SOURCEDIR/dpsview.tcl"
source "$SOURCEDIR/crate.tcl"
source "$SOURCEDIR/group.tcl"
source "$SOURCEDIR/member.tcl"
source "$SOURCEDIR/graphic.tcl"
source "$SOURCEDIR/orbit.tcl"
source "$SOURCEDIR/beule.tcl"
source "$SOURCEDIR/wedel.tcl"
source "$SOURCEDIR/orbit_einzel.tcl"
source "$SOURCEDIR/database.tcl"
source "$SOURCEDIR/features.tcl"
source "$SOURCEDIR/dummy_dps.tcl"
source "$SOURCEDIR/dummy_crate.tcl"
source "$SOURCEDIR/real_dummy_crate.tcl"
source "$SOURCEDIR/dummy_trx.tcl"
source "$SOURCEDIR/real_dummy_trx.tcl"
source "$SOURCEDIR/dummy_orbit_einzel.tcl"

# Damit die Oberflaeche auch beim Schliessen ueber den Window-Manager,
# oder mit X, ordentlich beendet wird.
wm protocol . WM_DELETE_WINDOW "master menu_quit"

rename grab tkgrab
proc grab args {
  catch {eval tkgrab $args}
}

init_class init blwsteer "Backlegwinding-Steerer" \
                blwsteer.data timing_blwsteer.data crate_blwsteer.data \
                ustate_blwsteer.init
