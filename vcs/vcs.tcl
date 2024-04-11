
proc call_in_toplevel_scope { command } {
    global tc_name
    set oldScope [scope]
    set result [call $command]
    scope $oldScope
    return $result
}

proc flush_waves {} {
    call_in_toplevel_scope {$vcdplusflush}
    return ""
}

proc show_time {} {
    set curr_time [call_in_toplevel_scope {$time}]
    call_in_toplevel_scope "\$display(\"Current Time: %t\", 0x$curr_time)"
    return ""
}

set FID             [dump -file waves.fsdb -type fsdb]

dump -fid ${FID} -add :* -depth 8 -aggregates -fsdb_opt +mda+packedmda+struct


run  

exit
