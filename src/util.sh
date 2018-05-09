#%include colours.sh

::() {
    [[ -n "$*" ]] || out:fail "No command specified"

	echo  "${CBTEA}$*${CDEF}"

	if [[ "${DRYRUN:-}" != true ]]; then
		"$@"
	fi
}
