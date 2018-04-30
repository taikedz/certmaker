### New entity Usage:new
#
# Create a new Certificate Authority, or Host
#
###/doc

cm:new() {
	local target="$1"; shift

	case "$target" in
	ca)
		cm:ca:new-ca "$@"
		;;
	host)
		cm:host:new-host "$@"
		;;
	*)
		out:fail "Unknown target for new: '$target'"
		;;
	esac
}
