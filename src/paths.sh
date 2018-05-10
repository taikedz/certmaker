cm:paths() {
    local host_name hostd

    host_name="${1:-}"; shift || {
        cm:paths:list
        return
    }

    hostd="$hoststore/$host_name"

    [[ -d "$hostd" ]] || out:fail "Unknown host profile '$host_name'"

    ls "$hostd/$host_name."{key,cer}
}

cm:paths:list() {
    find "$hoststore" -name '*.cnf' -exec dirname {} \; | sed "s|$hoststore/||"
}
