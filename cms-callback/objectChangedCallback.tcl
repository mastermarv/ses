proc objectChangedCallback {messages} {
    set f [open "|env INSTANCE=[app get instanceName] NPS_BASE=[app get baseDir] ruby [file join [app get scriptDir] serverCmds publish_object_changes.rb]" w]
    foreach m $messages {
        puts $f $m
    }
    close $f
}
