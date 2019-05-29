#%include std/out.sh

#%include ctconf.sh

### certmaker template {ca|host} [OUTFILE] Usage:template
#
# Create an OpenSSL config file for a CA or a host
#
###/doc

cm:template() {
    cm:helpcheck template "$@"

    local fromfile target outfile
    target="$1"; shift
    outfile="${1:-}"; shift || :

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
