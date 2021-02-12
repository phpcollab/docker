#!/bin/bash
set -Eeuo pipefail

# Why am I getting a permission denied on this line?
TAGLIST=$(mktemp -t taglist.XXXXXXXXXX) || { echo "Failed to create temp file"; exit 1; }
./generate-stackbrew-library.sh > "$TAGLIST"

bashbrew cat \
	-F "$(dirname "$BASH_SOURCE")/$(basename "$BASH_SOURCE" .sh).tmpl" \
	$TAGLIST