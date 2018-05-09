#!/bin/bash

cd "$(dirname "$0")"

exists() {
	echo "Skipping $1 -- already exists"
}

maycp() {
    [[ ! -f "$2" ]] || {
        exists "$2"
        return
    }

    cp "$1" "$2"
}

# ---------------------
# Create main dirs

BINS=/usr/bin
CONFIGD=/etc/certmaker
DATAD=/var/certmaker

if [[ "$UID" != 0 ]] ; then
    BINS="$HOME/.local/bin"
    CONFIGD="$HOME/.config/certmaker"
    DATAD="$HOME/.local/certmaker"
fi

mkdir -p "$BINS"
mkdir -p "$CONFIGD"
mkdir -p "$DATAD"/{hosts,default-cnf}

# ---------------------
# Deploy

cp bin/certmaker "$BINS/"

if [[ ! -f "$CONFIGD/certmaker.config" ]]; then
    sed "
    s=%CASTORE%=$DATAD/ca=
    s=%HOSTSTORE%=$DATAD/hosts=
    s=%DEFAULTCNF%=$DATAD/default-cnf=
    " cm-config/default-certmaker.config > "$CONFIGD/certmaker.config"
else
	exists "$CONFIGD/certmaker.config"
fi

maycp cm-config/host.cnf "$DATAD/default-cnf/host.cnf"
maycp cm-config/ca.cnf "$DATAD/default-cnf/ca.cnf"

echo "Installed certmaker"
