itcl_class usta_class {
  constructor {config} {}
  destructor {}
  method config {config} {}


  method host {host} {
    $target send_receive "()$this :host:'$host'"
  }

  method port {port} {
    $target send_receive "()$this :port:$port"
  }

  method start {} {
    $target send_receive "()$this start"
  }

  method stop {} {
    $target send_receive "()$this stop"
  }

  method init_state {} {
    connect
  }


  method connect {} {
    global ustate_port ustate_host

    set do_init 0
    set is_connected 1

    if {![$target get_islinked]} {
        $target link
    }

    $target send_receive "()$this getc"
    if {(![$target get_islinked]) || ([string first "null" \
        [$target get_scsrtext]] != -1)} {
      $target send_receive \
            "()$this connect '$conn_string' $type"
      set do_init 1
    }

    if {$first_init} {
      stop
    }

    if {$first_init || $do_init} {
      host $ustate_host
      port $ustate_port
      start
      set first_init 0
    }
  }

  method get_isconnected {} {return $is_connected}
  method set_isconnected {c} {set is_connected $c}
  method get_target {} {return $target}

  public conn_string
  public type
  public target
  protected first_init 1
  protected is_connected 0
}
