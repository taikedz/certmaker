

files:ensure_file() {
	local target="$1"; shift
	local tdir="$(dirname "$target")"

	[[ -d "$tdir" ]] || mkdir -p "$tdir"

	[[ -f "$target" ]] || echo -n "$*" > "$target"
}
