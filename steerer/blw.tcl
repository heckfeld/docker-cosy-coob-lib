#!/usr/local/bin/pgwish -f
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

########## WORKSPACE- und SERVER-FUNKTIONEN ############
source "$LIBDIR/Timeout.tcl"
source $LIBDIR/server.tcl
source $SOURCEDIR/sw_trigger.tcl
Timeout tt
server_class server -sw_timing on

source "$SOURCEDIR/setting.tcl"
source "$LIBDIR/checkbutton.tcl"
source "$LIBDIR/tixinit.tcl"
source "$LIBDIR/bindings.tcl"
source "$LIBDIR/Value.tcl"
source "$LIBDIR/ScrollListBox.tcl"
source "$LIBDIR/ScrollSelectBox.tcl"
source "$LIBDIR/restore_single.tcl"
source "$LIBDIR/save_single.tcl"
source "$LIBDIR/delete_single.tcl"
source "$LIBDIR/Target_all.tcl"
#source "$SOURCEDIR/Target_all_dummy.tcl"
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

rename grab tkgrab
proc grab args {
  catch {eval tkgrab $args}
}

init_class init blw "Steerer Backleg Winding" bwsteertst.data \
                timing_bwsteertst.data crate_bwsteertst.data \
                ustate_bwsteertst.init
