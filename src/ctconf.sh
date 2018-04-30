#%include searchpaths.sh out.sh vars.sh

CERTMAKER_confpaths=".:$HOME/.config/certmaker:/etc/certmaker"

ctconf:load_config() {
	local conffile="$(searchpaths:file_from "$CERTMAKER_confpaths" certmaker.config)"

	if [[ -z "$conffile" ]]; then
		out:fail "No config file found."
	fi

	. "$conffile"

	ctconf:verify
}

ctconf:verify() {
	# Most basic required configurations
	vars:require castore certhosts
}
