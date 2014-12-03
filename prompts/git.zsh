#! /bin/zsh

function __git_prompt() {
	# Get the current commit
	COMMIT=$(git rev-parse --short HEAD 2> /dev/null)

	# Skip early if not in a git-managed folder (or something else is broken)
	if [[ $? != 0 ]]; then
		return 0
	fi

	# Get the branch assigned to the commit
	BRANCH=$(git symbolic-ref --short 'HEAD' 2> /dev/null)
	
	# Fetch some additional values if tree is detached
	if [[ -n "${BRANCH}" ]]; then
		# Try to find upstream branche
		REMOTE_BRANCH=$(git rev-parse --abbrev-ref 'HEAD@{upstream}' 2> /dev/null)

		# Fetch diff between local branch and tracking branch
		if [[ -n "${REMOTE_BRANCH}" ]]; then
			REMOTE_DIFF=(${=$(git rev-list --left-right --count "${REMOTE_BRANCH}...${BRANCH}" 2> /dev/null)})
		fi
	fi

	# Get the tags assigned to this commit
	TAGS=$(git tag --points-at 'HEAD' 2> /dev/null)
	
	# Get the modification status
	STATS_MODIFIED=0
	STATS_INDEXED=0
	STATS_UNTRACKED=0
	STATS_CONFLICTS=0

	while IFS='' read STAT_LINE; do
		STAT="${STAT_LINE[0,2]}"

		if [[ "${STAT}" =~ '( |M|A|R|C)(M|D)' ]]; then
			((STATS_MODIFIED++))
		fi

		if [[ "${STAT}" =~ '(M( |M|D))|(A( |M|D))|(D( |M))|(R( |M|D))|(C (M|D))' ]]; then
			((STATS_INDEXED++))
		fi

		if [[ "${STAT}" == '??' ]]; then
			((STATS_UNTRACKED++))
		fi

		if [[ "${STAT}" =~ 'DD|AU|UD|UA|DU|AA|UU' ]]; then
			((STATS_CONFLICTS++))
		fi

		STATS_DIRTY='yes'
	done < <(git status --porcelain --untracked-files=all)

	# Generate the prompt line
	echo -n '{'

	if [[ -n "${BRANCH}" ]]; then
		echo -n "%{%F{blue}%B%}${BRANCH}%{%b%f%}"
	else
		echo -n "%{%F{magenta}%B%}:${COMMIT}%{%b%f%}"
	fi

	if [[ "${REMOTE_DIFF[1]}" -gt 0 ||
		  "${REMOTE_DIFF[2]}" -gt 0 ]]; then
		echo -n '|'
		
		if [[ -n "${REMOTE_BRANCH}" ]]; then
			echo -n "%{%F{cyan}%B%}$REMOTE_BRANCH%{%b%f%}"
		fi

		if [[ "${REMOTE_DIFF[2]}" -gt 0 ]]; then
			echo -n -e "%{%F{yellow}%}\\xE2\\x86\\x91%{%B%}${REMOTE_DIFF[2]}%{%b%f%}"
		fi

		if [[ "${REMOTE_DIFF[1]}" -gt 0 ]]; then
			echo -n -e "%{%F{yellow}%}\\xE2\\x86\\x93%{%B%}${REMOTE_DIFF[1]}%{%b%f%}"
		fi
	fi

	echo -n '|'

	if [[ -n "${STATS_DIRTY}" ]]; then

		if [[ "${STATS_MODIFIED}" -gt 0 ]]; then
			echo -n -e "%{%F{green}%}\\xC2\\xB1%{%B%}${STATS_MODIFIED}%{%b%f%}"
		fi

		if [[ "${STATS_INDEXED}" -gt 0 ]]; then
			echo -n -e "%{%F{yellow}%}\\xE2\\x9A\\xAA%{%B%}${STATS_INDEXED}%{%b%f%}"
		fi

		if [[ "${STATS_UNTRACKED}" -gt 0 ]]; then
			echo -n -e "%{%F{cyan}%}\\xD9\\xAD%{%B%}${STATS_UNTRACKED}%{%b%f%}"
		fi

		if [[ "${STATS_CONFLICTS}" -gt 0 ]]; then
			echo -n -e "%{%F{red}%}\\xC3\\x97%{%B%}${STATS_CONFLICTS}%{%b%f%}"
		fi

	else
		echo -n -e "%{%F{green}%B%}\\xE2\\x9C\\x94%{%b%f%}"
	fi
	
	echo -n '}'
}

