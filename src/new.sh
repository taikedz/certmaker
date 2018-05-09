### New entity Usage:new
#
# Create a new Certificate Authority, or Host
#
#   certmaker new host HOSTNAME
#
#   certmaker new ca CACONF
#
# You can generate a CACONF file with
#
#   certmaker template ca [CACONF]
#
###/doc

cm:new() {
    cm:helpcheck new "$@"

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
