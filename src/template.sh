#%include out.sh
#%include ctconf.sh

cm:template() {
    local fromfile
    local target="$1"; shift
    local outfile="${1:-}"; shift || :

    case "$target" in
    ca|host)
        fromfile="$(cm:config:get_temp "$target")"
        [[ -n "${outfile:-}" ]] || outfile="./$(basename "$fromfile")"

        sed "
        s|%CASTOREDIR%|$castore|
        " "$fromfile" > "$outfile"
        ;;
    *)
        out:fail "No template for $target"
        ;;
    esac
}
