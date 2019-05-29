#%include std/searchpaths.sh
#%include std/out.sh
#%include std/vars.sh

CERTMAKER_confpaths=".:$HOME/.config/certmaker:/etc/certmaker"

cm:config:load_config() {
	local conffile="$(searchpaths:file_from "$CERTMAKER_confpaths" certmaker.config)"

	if [[ -z "$conffile" ]]; then
		out:fail "No config file found."
	fi

	. "$conffile"
}

cm:config:get_temp() {
    echo "$cnftemplates/$1.cnf"
}
