$%function cm:paths:_dispatch(?action ?host_name) {
    if [[ -z "$action" ]]; then
        cm:paths:list
        return
    fi

    if [[ "$action" = "tgz" ]]; then
        cm:paths:give-tgz "$host_name" "$@"

    elif [[ "$action" = "show" ]]; then
        cm:paths:show "$host_name"
    else
        out:fail "Unknown action - try 'tgz HOSTNAME [TARNAME]' or 'show HOSTNAME'"
    fi
}

$%function cm:paths:show(host_name) {
    local hostd="$hoststore/$host_name"

    [[ -d "$hostd" ]] || out:fail "Unknown host profile '$host_name'"

    ls "$hostd/$host_name."{key,cer}
}

cm:paths:list() {
    find "$hoststore" -name '*.cnf' -exec dirname {} \; | sed "s|$hoststore/||"
}

$%function cm:paths:give-tgz(host_name ?tarname) {
    local hostd="$hoststore/$host_name"

    [[ -d "$hostd" ]] || out:fail "Unknown host profile '$host_name'"

    if [[ -z "$tarname" ]]; then
        tarname=./"$host_name-certkey.tgz"
    fi

    ( set -x
    tar czf "$tarname" -C "$hostd" "$host_name.cer" "$host_name.key"
    )
}
