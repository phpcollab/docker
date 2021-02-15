#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"
helperDir='./.template-helpers'

# usage: ./update.sh


# grabs all parameters passed in and looks for "images"
images=( "$@" )
if [ ${#images[@]} -eq 0 ]; then
	images=( */ )
fi
images=( "${images[@]%/}" )

replace_field() {
	targetFile="$1"
	field="$2"
	content="$3"
	extraSed="${4:-}"
	sed_escaped_value="$(echo "$content" | sed 's/[\/&]/\\&/g')"
	sed_escaped_value="${sed_escaped_value//$'\n'/\\n}"
	sed -ri -e "s/${extraSed}%%${field}%%${extraSed}/$sed_escaped_value/g" "$targetFile"
}

# Let's shove the MANIFEST into a temp file so we can use it throughout the script and export it so subscripts can use it
export MANIFEST=$(mktemp -t manifest.XXXXXXXXXX) || { echo "Failed to create temp file"; exit 1; }
../generate-stackbrew-library.sh > "$MANIFEST"



for image in "${images[@]}"; do
	repo="${image##*/}"
	namespace="${image%$repo}"
	namespace="${namespace%/}"

	# this is used by subscripts to determine whether we're pushing /_/xxx or /r/ARCH/xxx
	# (especialy for "supported tags")
	export ARCH_SPECIFIC_DOCS=
	if [ -n "$namespace" ] && [ -n "${BASHBREW_ARCH:-}" ]; then
		export ARCH_SPECIFIC_DOCS=1
	fi

	if [ -e "./content.md" ]; then
		githubRepo="$(cat "./github-repo")"
		maintainer="$(cat "./maintainer.md")"

		issues="$(cat "./issues.md" 2>/dev/null || cat "$helperDir/issues.md")"
		getHelp="$(cat "./get-help.md" 2>/dev/null || cat "$helperDir/get-help.md")"

		license="$(cat "./license.md" 2>/dev/null || true)"
		licenseCommon="$(cat "./license-common.md" 2>/dev/null || cat "$helperDir/license-common.md")"
		if [ "$license" ]; then
			license=$'\n\n''# License'$'\n\n'"$license"$'\n\n'"$licenseCommon"
		fi

		#######
		# LOGO
		#######
		logo=
		logoFile=
		for f in png svg; do
			if [ -e "./logo.$f" ]; then
				logoFile="./logo.$f"
				break
			fi
		done

		if [ "$logoFile" ]; then
			logo="![logo](https://raw.githubusercontent.com/phpcollab/docker/master/docs/logo.png)"
		fi
		#######
		# END LOGO
		#######

		#######
		# STACK.YAML
		#######
		stack=
		stackYml=
		stackUrl=
		if [ -f "../stack.yml" ]; then
			stack="$(cat "./stack.md" 2>/dev/null || cat "$helperDir/stack.md")"
			stackYml=$'```yaml\n'"$(cat "../stack.yml")"$'\n```'
			stackUrl="https://raw.githubusercontent.com/phpcollab/docker/master/stack.yml"
		fi
		#######
		# ENDSTACK.YAML
		#######

		compose=
		composeYml=
		if [ -f "./docker-compose.yml" ]; then
			compose="$(cat "./compose.md" 2>/dev/null || cat "$helperDir/compose.md")"
			composeYml=$'```yaml\n'"$(cat "./docker-compose.yml")"$'\n```'
		fi

		deprecated=
		if [ -f "./deprecated.md" ]; then
			deprecated=$'# **DEPRECATION NOTICE**\n\n'
			deprecated+="$(cat "./deprecated.md")"
			deprecated+=$'\n\n'
		fi

		if ! partial="$("$helperDir/generate-dockerfile-links-partial.sh" $MANIFEST)"; then
			{
				echo
				echo "WARNING: failed to fetch tags for 'phpcollab'; skipping!"
				echo
			} >&2
			continue
		fi

		targetFile="./README.md"

		{
			cat "$helperDir/autogenerated-warning.md"
			echo

			if [ -n "$ARCH_SPECIFIC_DOCS" ]; then
				echo '**Note:** this is the "per-architecture" repository for the `'"$BASHBREW_ARCH"'` builds of [the `'"phpcollab"'` official image](https://hub.docker.com/r/phpcollab/phpcollab'"phpcollab"') -- for more information, see ["Architectures other than amd64?" in the official images documentation](https://github.com/docker-library/official-images#architectures-other-than-amd64) and ["An image'\''s source changed in Git, now what?" in the official images FAQ](https://github.com/docker-library/faq#an-images-source-changed-in-git-now-what).'
				echo
			fi

			echo -n "$deprecated"
			cat "$helperDir/template.md"
		} > "$targetFile"

		echo '  TAGS => generate-dockerfile-links-partial.sh "'"phpcollab"'"'
		replace_field "$targetFile" 'TAGS' "$partial"

		echo '  ARCHES => arches.sh "'"phpcollab"'"'
		arches="$("$helperDir/arches.sh" $MANIFEST)"
		[ -n "$arches" ] || arches='**No supported architectures**'
		replace_field "$targetFile" 'ARCHES' "$arches"

		echo '  CONTENT => '"docs"'/content.md'
		replace_field "$targetFile" 'CONTENT' "$(cat "./content.md")"

		# has to be after CONTENT because it's contained in content.md
		echo "  LOGO => $logo"
		replace_field "$targetFile" 'LOGO' "$logo" '\s*'

		echo '  STACK => '"docs"'/stack.md'
		replace_field "$targetFile" 'STACK' "$stack"
		echo '  STACK-YML => '"docs"'../stack.yml'
		replace_field "$targetFile" 'STACK-YML' "$stackYml"
		echo '  STACK-URL => '"docs"'../stack.yml'
		replace_field "$targetFile" 'STACK-URL' "$stackUrl"

		echo '  COMPOSE => '"docs"'/compose.md'
		replace_field "$targetFile" 'COMPOSE' "$compose"
		echo '  COMPOSE-YML => '"docs"'/docker-compose.yml'
		replace_field "$targetFile" 'COMPOSE-YML' "$composeYml"

		echo '  LICENSE => '"docs"'/license.md'
		replace_field "$targetFile" 'LICENSE' "$license"

		echo '  ISSUES => "'"$issues"'"'
		replace_field "$targetFile" 'ISSUES' "$issues"

		echo '  GET-HELP => "'"$getHelp"'"'
		replace_field "$targetFile" 'GET-HELP' "$getHelp"

		echo '  MAINTAINER => "'"$maintainer"'"'
		replace_field "$targetFile" 'MAINTAINER' "$maintainer"

		echo '  IMAGE => "'"$image"'"'
		replace_field "$targetFile" 'IMAGE' "$image"

		echo '  REPO => "'"phpcollab"'"'
		replace_field "$targetFile" 'REPO' "phpcollab"

		echo '  GITHUB-REPO => "'"$githubRepo"'"'
		replace_field "$targetFile" 'GITHUB-REPO' "$githubRepo"

		echo
	else
		echo >&2 "skipping docs: missing repo/content.md"
	fi
done
