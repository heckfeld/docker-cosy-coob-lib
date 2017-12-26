#
# $Header: /mnt/cc-x3/coob/lib/steerer/rcs/filebox.tcl,v 1.2 2011/12/02 13:58:01 tine Exp $
#
# kopiert von $COOB/lib/utils
#

itcl_class fileselect_class {

  constructor {config} {}
  destructor {}
  method config {config} {}

  method make_fileselect {widget title commando} {
    global SOURCEDIR background WORKSPACE eqfont

    set w $widget
    set cmd $commando

    toplevel $w

    # Fenster muss erst beendet werden, um in der GUI weiterzumachen !!!
    grab $w

    wm minsize $w 1 1
    wm geometry $w 580x350
    wm title $w $title
    wm command $w $WORKSPACE

    wm protocol $w WM_DELETE_WINDOW "$this file_cancel"

    tixFileSelectbox $w.select 
    $w.select configure -fg black -bg $background \
                        -listboxbg white \
                        -entrybg white \
                        -listboxfont $eqfont \
                        -filter $filter \
                        -pattern "$SOURCEDIR" \
                        -command "$this okcmd" \
                        -grab none

    frame $w.row
    pack $w.select $w.row -in $w -side top -fill both

    button $w.ok_but -text Ok -width 4 -fg black \
                     -command "$this file_ok"
    button $w.cancel_but -text Cancel -width 8 -fg black \
                         -command "$this file_cancel"
    pack $w.ok_but $w.cancel_but -in $w.row -side \
         left -padx 10 -pady 10

  }; #make_fileselect


  method okcmd {name} {
    # Wenn 'name' leer ist, kann/darf nichts gemacht werden !!!
    if {[string length $name]} {
      set val [eval $cmd $name]
    }
  }

  method file_ok {} {
    global BITMAPDIR TITLE

    set ret [$w.select invoke]
# 'ret' ist leer, wenn im 'Selection'-Entry nichts steht,
# sonst ist der Wert 0 !!!

    # Fehlermeldung, wennn keine Datei ausgewaehlt !!!
    if {$ret == {}} {

      tk_dialog_max .dia 1600 "$TITLE" \
                              "Es muss eine Datei ausgewaehlt werden!" \
                              @$BITMAPDIR/smily.xpm 0 OK
    }

    # Wenn Fehler bei Dateiauswahl, das Fenster nicht beenden !!!

  }; #file_ok

  method file_cancel {} {
    destroy $w
    $this delete
    grab $parent_widget
  }


  method get_name {} {return $filename}

  public filter
  public parent_widget

  protected w
  protected cmd
}
