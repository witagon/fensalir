currentBranch=$(git rev-parse --abbrev-ref HEAD);

# Get all local branches that tracks remote branches
branches=$(git remote show origin -n | awk '/merges with remote/{print $5" "$1}')

while read remoteBranch localBranch; do
    aRemoteBranch="refs/remotes/origin/${remoteBranch}";
    aLocalBranch="refs/heads/${localBranch}";
    behindCount=$(( $(git rev-list --count "${aLocalBranch}..${aRemoteBranch}" 2>/dev/null) +0));
    aheadCount=$(( $(git rev-list --count "${aRemoteBranch}..${aLocalBranch}" 2>/dev/null) +0));
    if [ "${behindCount}" -gt 0 ]; then
        if [ "${aheadCount}" -gt 0 ]; then
	    echo " Branch ${localBranch} is ${behindCount} commit(s) behind and ${aheadCount} commit(s) ahead of origin/${remoteBranch}. Could not be fast-forwarded!";
        elif [ "${localBranch}" = "${currentBranch}" ]; then
	    echo " Branch ${localBranch} was ${behindCount} commit(s) behind of origin/${remoteBranch}. Fast-forward merge";
	    git merge -q "${aRemoteBranch}";
        else
	    echo " Branch ${localBranch} was ${behindCount} commit(s) behind of origin/${remoteBranch}. Resetting local branch to remote";
	    git branch -f "${localBranch}" -t "${aRemoteBranch}" >/dev/null;
        fi
    fi
done <<< "${branches}"
