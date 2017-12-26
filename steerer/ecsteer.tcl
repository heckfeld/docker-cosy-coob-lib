#!/bin/sh
# \
	exec bpmwish -f "$0" ${1+"$@"}

# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/ecsteer.tcl,v 1.2 2011/12/02 13:50:36 tine Exp $

proc raise.tk  { args } {
    eval raise $args
}

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
set MODELLDIR $env(MODELLDIR)

set TITLE ecsteer

#
# !!! Testausgabe !!!
#
if {$testbetrieb} {
  puts ""
  puts "Oberflaeche zum Testen:"
  puts "$TITLE"
  puts "============"
  puts "PATH=$env(PATH)"
  puts "============"
  puts "Testaufruf: fgendattcl (ohne irgenrwas) :[exec fgendattcl]"
  puts "------------"
}

lappend auto_path $env(COOB)/lib/itcl
lappend auto_path $env(LIBDIR)


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

# Damit die Oberflaeche auch beim Schliessen ueber den Window-Manager,
# oder mit X, ordentlich beendet wird.
wm protocol . WM_DELETE_WINDOW "master menu_quit"

rename grab tkgrab
proc grab args {
  catch {eval tkgrab $args}
}

init_class init ecsteer "EK-Steerer" \
                ecsteer.data timing_ecsteer.data crate_ecsteer.data \
                ustate_ecsteer.init
