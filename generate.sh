#!/usr/bin/env bash
set -Eeuo pipefail

image="${GITHUB_REPOSITORY##*/}" # "python", "golang", etc

[ -n "${GENERATE_STACKBREW_LIBRARY:-}" ] || [ -x ./generate-stackbrew-library.sh ] # sanity check

tmp="$(mktemp -d)"
trap "$(printf 'rm -rf %q' "$tmp")" EXIT
echo 1
if ! command -v bashbrew &> /dev/null; then
	dir="$(readlink -f "$BASH_SOURCE")"
	dir="$(dirname "$dir")"
	dir="$(cd "$dir/../.." && pwd -P)"
	if [ ! -x "$dir/bin/bashbrew" ]; then
		echo >&2 'Building bashbrew ...'
		"$dir/bashbrew.sh" --version > /dev/null
		"$dir/bin/bashbrew" --version >&2
	fi
	export PATH="$dir/bin:$PATH"
	bashbrew --version > /dev/null
fi
echo 2
mkdir "$tmp/library"
export BASHBREW_LIBRARY="$tmp/library"

eval "${GENERATE_STACKBREW_LIBRARY:-./generate-stackbrew-library.sh}" > "$BASHBREW_LIBRARY/$image"
ls "$BASHBREW_LIBRARY/$image"
# if we don't appear to be able to fetch the listed commits, they might live in a PR branch, so we should force them into the Bashbrew cache directly to allow it to do what it needs
if ! bashbrew from ./"$image" &> /dev/null; then
	bashbrewGit="${BASHBREW_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/bashbrew}/git"
	git -C "$bashbrewGit" fetch --quiet --update-shallow "$PWD" HEAD > /dev/null
	bashbrew from ./"$image" > /dev/null
fi
echo 3
tags="$(bashbrew list --build-order --uniq ./"$image")"
echo 4
# see https://github.com/docker-library/python/commit/6b513483afccbfe23520b1f788978913e025120a for the ideal of what this would be (minimal YAML in all 30+ repos, shared shell script that outputs fully dynamic steps list), if GitHub Actions were to support a fully dynamic steps list

order=()
declare -A metas=()
for tag in $tags; do
	echo >&2 "Processing $tag ..."
	bashbrewImage="${tag##*/}" # account for BASHBREW_NAMESPACE being set
	meta="$(
		bashbrew cat --format '
			{{- $e := .TagEntry -}}
			{{- $arch := $e.HasArchitecture arch | ternary arch ($e.Architectures | first) -}}
			{{- "{" -}}
				"name": {{- json ($e.Tags | first) -}},
				"tags": {{- json ($.Tags namespace false $e) -}},
				"directory": {{- json ($e.ArchDirectory $arch) -}},
				"file": {{- json ($e.ArchFile $arch) -}},
				"constraints": {{- json $e.Constraints -}},
				"froms": {{- json ($.ArchDockerFroms $arch $e) -}}
			{{- "}" -}}
		' ./"$bashbrewImage" | jq -c '
			{
				name: .name,
				os: (
					if (.constraints | contains(["windowsservercore-1809"])) or (.constraints | contains(["nanoserver-1809"])) then
						"windows-2019"
					elif .constraints | contains(["windowsservercore-ltsc2016"]) then
						"windows-2016"
					elif .constraints == [] or .constraints == ["!aufs"] then
						"ubuntu-latest"
					else
						# use an intentionally invalid value so that GitHub chokes and we notice something is wrong
						"invalid-or-unknown"
					end
				),
				meta: { entries: [ . ] },
				runs: {
					build: (
						[
							"docker buildx build --pull --push --platform linux/arm/v7,linux/arm64/v8,linux/amd64"
						]
						+ (
							.tags
							| map(
								"--tag " + (. | @sh)
							)
						)
						+ if .file != "Dockerfile" then
							[ "--file", ((.directory + "/" + .file) | @sh) ]
						else
							[]
						end
						+ [
							(.directory | @sh)
						]
						| join(" ")
					),
					history: ("docker history " + (.tags[0] | @sh)),
					test: ("~/oi/test/run.sh " + (.tags[0] | @sh)),
				},
			}
		'
	)"

	metas["$tag"]="$meta"
	order+=( "$tag" )	
done
echo 5
strategy="$(
	for tag in "${order[@]}"; do
		jq -c '
			.meta += {
				froms: (
					[ .meta.entries[].froms[] ]
					- [ .meta.entries[].tags[] ]
					| unique
				),
				dockerfiles: [
					.meta.entries[]
					| .directory + "/" + .file
				],
			}
			| .runs += {
				prepare: ([
					(
						if .os | startswith("windows-") then
							"# enable symlinks on Windows (https://git-scm.com/docs/git-config#Documentation/git-config.txt-coresymlinks)",
							"git config --global core.symlinks true",
							"# ... make sure they are *real* symlinks (https://github.com/git-for-windows/git/pull/156)",
							"export MSYS=winsymlinks:nativestrict",
							"# make sure line endings get checked out as-is",
							"git config --global core.autocrlf false"
						else
							empty
						end
					),
					"git clone --depth 1 https://github.com/docker-library/official-images.git -b master ~/oi",
					"# create a dummy empty image/layer so we can --filter since= later to get a meaningful image list",
					"{ echo FROM " + (
						if (.os | startswith("windows-")) then
							"mcr.microsoft.com/windows/servercore:ltsc" + (.os | ltrimstr("windows-"))
						else
							"busybox:latest"
						end
					) + "; echo RUN :; } | docker build --no-cache --tag image-list-marker -",
					(
						if .os | startswith("windows-") | not then
							(
								"# PGP Happy Eyeballs",
								"git clone --depth 1 https://github.com/tianon/pgp-happy-eyeballs.git ~/phe",
								"~/phe/hack-my-builds.sh",
								"rm -rf ~/phe"
							)
						else
							empty
						end
					)
				] | join("\n")),
				# build
				# history
				# test
				images: "docker image ls --filter since=image-list-marker",
			}
		' <<<"${metas["$tag"]}"
	done | jq -cs '
		{
			"fail-fast": false,
			matrix: { include: . },
		}
	'
)"
echo 6
if [ -t 1 ]; then
	jq <<<"$strategy"
else
	cat <<<"$strategy"
fi