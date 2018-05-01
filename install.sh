#!/bin/bash

BINS=/usr/local/bin

if [[ "$UID" != 0 ]] ; then
    BINS="$HOME/.local/bin"
fi

mkdir -p "$BINS"

cp bin/certtool bin/cert-getter.sh "$BINS/"

echo "Installed certtool and cert-getter.sh"
