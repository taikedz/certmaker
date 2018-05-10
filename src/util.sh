#%include colours.sh bincheck.sh

::() {
    [[ -n "$*" ]] || out:fail "No command specified"

	echo  "${CBTEA}$*${CDEF}"

	if [[ "${DRYRUN:-}" != true ]]; then
		"$@" || out:fail "$?"
	fi
}

# Attempt to use a default editor
# 
# If EDITOR is not set,
#  first try emacs - if present, it was probably deliberately installed
#  then try to use the easiest editor (nano)
#  then try to use vim
#  finally fallback to vi
cm:util:edit() {
    local editor
	if [[ -z "${EDITOR:-}" ]]; then
        for editor in nano emacs vim vi; do 
            if bincheck:has "$editor"; then
                EDITOR="$(which "$editor")"
            fi
        done
    fi

	"$EDITOR" "$1"
}
