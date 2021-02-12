#!/bin/bash
set -Eeuo pipefail

repo="${1:-}"
if [ -z "$repo" ]; then
	echo >&2 "usage: $0 repo"
	echo >&2 "   ie: $0 hylang"
	exit 1
fi

# if we haven't set BASHBREW_LIBRARY explicitly (like Jenkins does, for example), don't trust the local library
if [ -z "${BASHBREW_LIBRARY:-}" ]; then
	# Refactor this so it doesn't need the "manifest" type file.
	repo="https://raw.githubusercontent.com/phpcollab/docker/docker-docs/$repo"
fi

bashbrew cat --format '
	{{- range .Entries -}}
		{{- range .Architectures -}}
			{{- $ns := archNamespace . -}}
			{{- if $ns -}}
				[
			{{- end -}}
			`{{- . -}}`
			{{- if $ns -}}
				](https://hub.docker.com/r/{{- $ns -}}/{{- $.RepoName -}}/)
			{{- end -}}
			{{- ",\n" -}}
		{{- end -}}
	{{- end -}}
' "$repo" | sort -u | tr '\n' ' ' | sed -r -e 's/, $/\n/' -e 's/^[[:space:]]+|[[:space:]]+$//g'
