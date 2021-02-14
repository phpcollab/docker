#!/bin/bash
set -Eeuo pipefail

../bashbrew cat \
	-F "$(dirname "$BASH_SOURCE")/$(basename "$BASH_SOURCE" .sh).tmpl" \
	"$MANIFEST"