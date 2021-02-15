#!/bin/bash
set -Eeuo pipefail

../bashbrew cat --format '
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
' "$MANIFEST" | sort -u | tr '\n' ' ' | sed -r -e 's/, $/\n/' -e 's/^[[:space:]]+|[[:space:]]+$//g'
