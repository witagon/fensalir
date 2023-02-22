# Get common exit code definitions
#
# shellcheck source=./.exit_codes.bash
source "${_FENSALIR_HOME}/.exit_codes.bash"


UNTRACKED="untracked"
UNSTAGED="unstaged"
STAGED="staged"


# IF current working directory (CWD) is below _FRIJA_WS_PATH and it is
# also within a Git repo this command returns a subpath to the current
# folder. That is _FRIJA_WS_PATH is stripped from CWD and returned.
#
# Otherwise an empty string is returned.
function cwd_in_workspace_repo_folder_p()
{
    print_debug_enter "${@}"

    local cwd="${1:-${_FRIJA_PWD}}"
    local result=""

    print_debug "cwd='${cwd}'"
    # Check if current working directory starts with _FRIJA_WS_PATH. If
    # so a check is made to see if we are inside a Git repo or not. If
    # we are then _FRIJA_PWD with _FRIJA_WS_PATH removed is returned.
    if [[ "${cwd}" == "${_FRIJA_WS_PATH}"* ]]; then
        print_debug "cwd starts with '${_FRIJA_WS_PATH}'"
        ! git -C "${cwd}" rev-parse 2>/dev/null
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            # Remove the prefix $_FRIJA_WS_PATH plus a following '/' from
            # $cwd to get a sub-path that does not start with '/'
            result="${cwd#${_FRIJA_WS_PATH}/}"
        fi
    fi

    print_debug_exit "'${result}'"
    echo "${result}"
}


# Return success (zero) or failure (non-zero) depending on if given
# file system path points to a VCS system or not.
#
# NOTE: Currently only Git is supported for VCS identification.
#
# First parameter is path to folder to test.
function is_vcs_folder()
{
    print_debug_enter "${@}"

    local vcspath="${1}"
    print_debug "vcspath='${vcspath}'"

    # Do not abort script if git command fails with a non-zero exit code
    print_debug "git -C '${vcspath}' rev-parse &>/dev/null"
    ! git -C "${vcspath}" rev-parse &>/dev/null
    declare -i result=$?

    print_debug_exit ${result}
    return ${result}
}


# Return name of Git repo represented by a path to the repo or a
# folder within the repo.
#
# As Git does not really have any internal name for the repo, it is
# assumed that the folder containing the .git folder is the "name" of
# the repo.
#
# First parameter is a path to the repo (or a folder within)
function git_reponame()
{
    print_debug_enter "${@}"

    local repopath="${1}"

    repopath=$(git -C "${repopath}" rev-parse --show-toplevel) >&2

    print_debug_exit "${repopath}"
    basename "${repopath}"
}


# Return name of a repo represented by a path to the repo or a folder
# within the repo. This function deduces the kind of repo the path
# points to before invoking the corresponding repo-specific function.
#
# If the repo kind is not supported an error is raised and an error
# message is printed to stderr.
#
# First parameter is a path to the repo (or a folder within)
function vcs_reponame()
{
    print_debug_enter

    local repopath="${1}"
    repoKind=$(frija_deduce_vcs_type "${repopath}")

    case "${repoKind}" in
        "${GIT_REPO}")
            git_reponame "${repopath}"
            ;;
        *)
            local message="Unknown repo kind '${repoKind}' determined for "
            message+="URI '${uri}'."
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            ;;
    esac

    print_debug_exit
}


# Create a local tag with the given name in a Git repo. Furthermore,
# if so instructed the local tag will also be pushed to the remote
# repo.
#
# First parameter is whether to push tag or not; non empty string
# means it should be psudhed, otherwise not.
#
# Second parameter is path to repo to create tag in.
#
# Third parameter is name of tag to create.
function git_create_tag()
{
    local autoPushTag="${1}"
    local repoPath="${2}"
    local tagName="${3}"

    local tagExist=""
    tagExist=$(git -C "${repoPath}" tag --list "${tagName}")
    if [[ -z "${tagExist}" ]]; then
        # Generated tag name does not exist so we create it!
        local message="Creating tag '${tagName}'..."
        local command=("${SINGLE}" "${message}" \
                                   git -C "${repoPath}" tag "${tagName}")

        run "${command[@]}"
    else
        message="Tag '${tagName}' already exist; "
        message+="no local tag created in repo '${repoPath}'."
        print_message "${message}"
    fi

    if [[ "${autoPushTag}" == "y" ]]; then
        local remoteTag=""
        remoteTag=$(git -C "${repoPath}" ls-remote --tags origin "${tagName}")
        if [[ -z "${remoteTag}" ]]; then
            local message="Pushing tag '${tagName}' to remote..."
            local command=("${SINGLE}" "${message}" \
                                       git -C "${repoPath}" \
                                       push origin "${tagName}")
            run "${command[@]}"
        else
            message="Tag '${tagName}' already exist in remote repo, "
            message=+="no tag pushed to remote repo '${repoPath}'."
            print_message "${message}"
        fi
    fi
}


# Clone or fetch a Git repo from a given URI. The URI is assumed to end with
# '.git' and that anything before up till the first '/' is the name of
# the repo to be cloned.
#
# NOTE: If the repo already exist it is instead fetched.
#
#
# First parameter is the base path to use; an empty path does not change CWD
#
# Second parameter is the URI to clone/fetch
#
function git_clone_repo()
{
    print_debug_enter

    local base="${1}"
    local uri="${2}"

    local reponame=""
    reponame=$(frija_extract_repo_name "${uri}")
    if [[ -n "${reponame}" ]]; then
        declare -a command

        if [[ -d "${base}/${reponame}" ]]; then
            if [[ "${UPDATE}" == "y" ]]; then
                command=("${SINGLE}" "Fetching repo '${reponame}'" \
                                     git -C "${base}/${reponame}" fetch)
                run "${command[@]}"
            else
                local message="${BOLD}Repo '${reponame}' already cloned "
                message+="(no fetch of repo)${CLEAR}"
                print_message "${message}"
            fi
        else
            command=("${SINGLE}" "Cloning repo '${reponame}'" \
                                 git -C "${base}" clone "${uri}")
            run "${command[@]}"
        fi
    else
        local message="Unknown repo URI format; unable to extract repo name "
        message+="from URI '${uri}'."
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit
}


# Clone a Git repo from a given URI. The URI is assumed to end with
# '.git' and that anything before up till the first '/' is the name of
# the repo to be cloned. This function deduces the kind of repo the path
# points to before invoking the corresponding repo-specific function.
#
# If the repo kind is not supported an error is raised and an error
# message is printed to stderr.
#
# First parameter is destination folder for cloned repo
#
# Second parameter is the URI to clone
function vcs_clone_repo()
{
    print_debug_enter

    local base="${1}"
    local uri="${2}"

    local repoKind=""
    repoKind=$(frija_deduce_vcs_type "${uri}")

    case "${repoKind}" in
        "${GIT_REPO}")
            git_clone_repo "${base}" "${uri}"
            ;;
        *)
            local message="Unknown repo kind '${repoKind}' "
            message+="determined for URI '${uri}'."
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            ;;
    esac

    print_debug_exit
}


# Check if repo is dirty or not; files have been staged but not
# committed or if changes have been made to the working tree that
# could be staged.
#
# Returns 0 (zero) if repo is clean, otherwise a value between 1 and
# 255 (inclusive).
function git_is_repo_dirty()
{
    local repopath="${1:-.}"

    # There is a reason for having a two-step process rather than a
    # single step like
    #
    # if git diff-index --quiet HEAD --; then
    #     ...
    #
    # to check if the repo is dirty or not. When this approach is used
    # then it will still report "no differences" if you have staged a
    # change that is undone by another change in the working tree.
    #
    # To be on the safe side the stricter approach is taken and due to
    # this it is a two-step process to check whether the repo is dirty
    # or not.


    declare -i dirty=0

    # Check if repo has staged but not yet committed changes.
    #
    # --cached is used to avoid command writing data to disk
    #
    # 'HEAD --' is used to avoid command failing if there is a file
    # named 'HEAD'
    if git -C "${repopath}" diff-index --quiet --cached HEAD --; then
        dirty=1
    fi

    if (( dirty > 0 )); then
        # Check if working tree has changes that could be staged.
        if git -C "${repopath}" diff-files --quiet; then
            dirty=1
        fi
    fi

    return $dirty
}


function git_print_ahead_state()
{
    print_debug_enter "${@}"

    local repopath="${1:-.}"

    declare -i exitcode=0
    declare -i commitsAhead=0

    local branchname=""
    branchname=$(git -C "${repopath}" branch --show-current)
    if [[ -n "${branchname}" ]]; then
        commitsAhead=$(git -C "${repopath}" \
                           rev-list --count "@{upstream}"..HEAD)
        if (( commitsAhead > 0 )); then
            # Indicate to caller that we are not at same commit as remote
            exitcode=1

            local reponame=""
            reponame=$(git_reponame "${repopath}")

            local plural=""
            plural=$(plural "${commitsAhead}")

            print_newline_only_after_dot
            local message="Repo '${reponame}' is ${commitsAhead} "
            message+="commit${plural} ahead of upstream."
            print_message "${message}"
        fi
    fi

    print_debug_exit ${exitcode}
    return ${exitcode}
}


function git_print_dirty_state()
{
    print_debug_enter "${@}"

    local repopath="${1:-.}"
    local version="${2:-}"

    declare -i exitcode=0

    print_debug "repopath: ${repopath}"

    declare -a command
    # Will return exit code 128 if not in a git repo.
    command=(git -C "${repopath}" status "--porcelain=v1")

    # Execute $command and ignore anything sent to stdout and stderr
    ! gitStatus=$("${command[@]}") 2>/dev/null
    exitcode=${PIPESTATUS[0]}

    if (( exitcode != 128 )); then
        declare -i aheadResult=0
        ! git_print_ahead_state "${repopath}"
        aheadResult=${PIPESTATUS[0]}

        # Assume repo is dirty in some way. Fewer places where we have
        # to change it to 0 (zero) to indicate repo is clean then the
        # other way around
        exitcode=1

        print_debug "gitStatus='${gitStatus}'"

        # Get current branch
        local branch=""
        branch=$(git_current_branch "${repopath}")
        print_debug "branch='${branch}'"

        local reponame=""
        reponame=$(git_reponame "${repopath}")
        print_debug "reponame: ${reponame}"

        local message=""
        local repoIdentity=""
        repoIdentity="${BOLD}${reponame}${CLEAR} ($repopath)"

        if [[ -n "${gitStatus}" ]]; then
            print_newline_only_after_dot
            print_message "${repoIdentity}"

            if [[ -z "${branch}" ]]; then
                message="${BOLD}WARNING!${CLEAR} Headless repo is modified"
            else
                message="${BOLD}${branch}${CLEAR}"
            fi
            print_message "${message}" 2
            print_message

            #message="  ${UNDERLINE_ON}Status${UNDERLINE_OFF}"
            #print_message "${message}"

            git_print_status "${UNTRACKED}" "${gitStatus}"
            git_print_status "${UNSTAGED}" "${gitStatus}"
            git_print_status "${STAGED}" "${gitStatus}"
        else
            if [[ -n "${branch}" ]]; then
                # Mark repo as clean to the caller
                exitcode=0

                if [[ "${WORDY}" == "y" ]]; then
                    print_newline_only_after_dot
                    print_message "${repoIdentity}"
                    print_message "${BOLD}${branch}${CLEAR} (up to date)\\n" 2
                fi
            else
                print_debug "  Repo in ${BOLD}headless${CLEAR} state"
                if [[ -n "${version}" ]]; then
                    print_debug "  Validating tag '${version}'..."

                    if validate_tag "${repopath}" "${version}" "y"; then
                        # Mark repo as clean to the caller
                        exitcode=0

                        if [[ "${WORDY}" == "y" ]]; then
                            print_newline_only_after_dot
                            print_message "${repoIdentity}"
                            message="Repo at tag ${BOLD}${version}${CLEAR} "
                            message+="(Detached HEAD)"
                            print_message "${message}\\n" 2
                        fi
                    else
                        print_newline_only_after_dot
                        print_message "${repoIdentity}"
                        message="Repo assumed to be at tag '${version}', but "
                        message+="could ${BOLD}NOT validate${CLEAR} it!"
                        print_message "${message}" 2

                        local sha=""
                        sha=$(get_short_sha "${repopath}")
                        message="Repo at SHA ${BOLD}${sha}${CLEAR} "
                        message+="(Detached HEAD)"
                        print_message "${message}\\n" 2
                    fi
                else
                    print_newline_only_after_dot
                    print_message "${repoIdentity}"

                    local sha=""
                    sha=$(get_short_sha "${repopath}")
                    local head=""
                    head=$(get_short_sha "${repopath}" "HEAD")

                    if [[ "${sha}" == "${head}" ]]; then
                        message="Repo at ${BOLD}HEAD${CLEAR} "
                        message+="(Detached HEAD)"
                    else
                        message="Repo at SHA ${BOLD}${sha}${CLEAR} "
                        message+="(Detached HEAD)"
                    fi
                    print_message "${message}\\n" 2
                fi
            fi
        fi
    else
        print_newline_only_after_dot
        print_command_failure_status "${PIPESTATUS[0]}" "${command[*]}"
    fi

    if (( exitcode == 0 )); then
        if (( aheadResult > 0 )); then
            exitcode=1
        elif [[ "${WORDY}" != "y" ]]; then
            print_dot
        fi
    fi

    print_debug_exit ${exitcode}
    return ${exitcode}
}


# Return name of current branch, or empty string if in headless state.
#
# First parameter is path to repo (optional); if not given current
# working directory is assumed to be within a repo.
function git_current_branch()
{
    print_debug_enter

    local repopath="${1:-.}"

    print_debug_exit

    # Note that 'git branch --show-current' return an empty string
    # when in headless state. Otherwise current branch name is
    # returned.
    git -C "${repopath}" branch --show-current
}


# Pretty print Git status for given status type and porcelain V1 format.
#
# First parameter is status type to print status for
#
# Second parameter is porcelain V1 format to parse
function git_print_status()
{
    print_debug_enter "${@}"

    local statusType="${1}"
    local gitStatus="${2}"

    print_debug "statusType='${statusType}'"

    declare -i mainIndex=0
    declare -i subIndex=0
    declare -i fileIndex=3
    local pattern=""
    case "${statusType}" in
        "${UNTRACKED}")
            pattern="^([?])([?]) (.*)"
            mainIndex=1
            subIndex=2
            ;;
        "${UNSTAGED}")
            pattern="^([ MTARC])([MTDRC]) (.*)"
            mainIndex=2
            subIndex=1
            ;;
        "${STAGED}")
            pattern="^([MTADRC])([ MTDRC]) (.*)"
            mainIndex=1
            subIndex=2
            ;;
        *)
            local message="Unsupported statusType '${statusType}', aborting."
            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
            ;;
    esac

    # Convert the Bash regexp to one that grep supports. This is done
    # by escaping all parentheses with the '\' character. This has to
    # be done in two steps since the Bash string replace function does
    # not support back references.
    #
    # Furthermore, to pull this off extended glob expression must be
    # turned on.
    #
    # shellcheck disable=SC2064
    trap "$(frija_restore_extglob_expression)" RETURN
    shopt -s extglob

    local grepPattern="${pattern//[(]/\\(}"
    grepPattern="${grepPattern//[)]/\\)}"
    print_debug "grepPattern='${grepPattern}'"

    declare -i count=0
    ! count=$(grep -c -e "${grepPattern}" <<< "${gitStatus}")
    print_debug "count='${count}'"
    print_debug "PIPESTATUS[0]='${PIPESTATUS[0]}'"
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
        if (( count > 0 )); then
            local plural=""
            plural=$(plural "${count}")
            local message="${UNDERLINE_ON}${BOLD}${statusType^} "
            message+="change${plural}${CLEAR} (${count})"
            print_message "${message}" 2

            # -r make read to not treat backslash character
            # as an escape character
            while IFS= read -r line; do
                #echo "QQQQ" 1>&2
                if [[ "${line}" =~ ${pattern} ]]; then
                    print_debug "Matched ${statusType} regex '${pattern}'"
                    local mainState="${BASH_REMATCH[$mainIndex]}"
                    local subState="${BASH_REMATCH[$subIndex]}"
                    local file="${BASH_REMATCH[$fileIndex]}"
                    declare -i indent=4
                    case "${mainState}" in
                        "M")
                            state="modified   "
                            if [[ "${subState}" == "R" ]]; then
                                # File renames are shown as
                                # from -> to
                                #
                                # Extract the 'from' and 'to' parts
                                # and set $file to the 'to' part.
                                local rename="^(\".+[^\\\\]\"|[^ ]+) -> (.+)"
                                if [[ "${file}" =~ $rename ]]; then
                                    file="${BASH_REMATCH[2]}"
                                else
                                    message="Unexpected rename format "+
                                    message+="'${file}', aborting."
                                    print_error "${message}" \
                                                $_FRIJA_EXIT_INTERNAL_ERROR
                                fi
                            fi
                            ;;
                        "T")
                            state="new type   "
                            ;;
                        "A"|"C")
                            state="new file   "
                            ;;
                        "D")
                            if [[ "${subState}" == "D" ]]; then
                                # We have stumbled upon an unmerged
                                # state that we ignore as it is in a
                                # commit.
                                continue
                            fi
                            state="deleted    "
                            ;;
                        "R")
                            state="renamed    "
                            ;;
                        "?")
                            state=""
                            ;;
                        *)
                            local message="Unexpected status letter "
                            message+="'${mainState}', aborting."
                            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
                            ;;
                    esac

                    message="${state}${BOLD}${file}${CLEAR}"
                    print_message "${message}" "${indent}"
                else
                    print_debug "Did NOT Match ${statusType} regex '${pattern}'"
                fi
            done<<<"${gitStatus}"
            print_message
        fi
    fi

    print_debug_exit
}


function git_checkout_committype()
{
    print_debug_enter

    local repopath="${1}"
    local commitType="${2}"
    local commitIdentifier="${3}"

    print_debug "repopath='${repopath}'"
    print_debug "commitType='${commitType}'"
    print_debug "commitIdentifier='${commitIdentifier}'"

    local reponame=""
    reponame=$(git_reponame "${repopath}")
    print_debug "reponame='${reponame}'"

    local message=""
    if git_is_repo_dirty "${repopath}"; then
        git_print_dirty_state "${repopath}"

        message="Git repo '${reponame}' is dirty and due to this cannot be "
        message+="updated. Please fix and re-run command."
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    local commitish=""
    commitish=$(git_translate_commitType "${repopath}" \
                                         "${commitType}" \
                                         "${commitIdentifier}")
    print_debug "commitish='${commitish}'"

    if [[ -n "${reponame}" ]]; then
        declare -a command
        local message=""

        local currentBranch=""
        currentBranch=$(git_current_branch "${repopath}")
        print_debug "currentBranch='${currentBranch}'"

        if [[ "${commitish}" == "${currentBranch}" ]]; then
            print_message "Already on target branch '${currentBranch}'"
            # We are already on target branch ($commitish) and we know
            # repo is not dirty. Check if local branch and tracking
            # branch have diverged and if so whether it can be
            # fast-forwarded or not. In the latter case we abort and
            # instruct the user has to resolve the situation.

            # First check if it is possible to do a fast-forward merge
            # or not. That is if HEAD is an ancestor of @{upstream}.
            #
            # @{upstream} is synonymous with tracking branch for
            # current branch, that is tip of the tracking branch
            if git -C "${repopath}" merge-base \
                   --is-ancestor HEAD "@{upstream}"; then
                print_debug "HEAD is ancestor to @{upstream}"
                # Check if there is at least one commit ahead of us.
                # Above command return true also for the case when
                # local and remote branches point to same commit.
                #
                # 'git rev-list --count' will count number of commits
                # reachable when following parent links from the given
                # set of commits. Note that the first commit in the
                # list HEAD..@{upstream} is ommitted (i.e. HEAD as it
                # is synonymous with @{upstream} ^HEAD for this
                # command, see manual page for more information). Thus
                # the command counts number of commits reachable from
                # @{upstream} but not HEAD.
                declare -i commitsAhead=0
                commitsAhead=$(git -C "${repopath}" rev-list --count \
                                   HEAD.."@{upstream}")
                if (( commitsAhead > 0 )); then
                    # We can do a fast-forward merge.
                    local plural=""
                    plural=$(plural "${count}")
                    message="${BOLD}${reponame}:${CLEAR} Branch "
                    message="'${commitish}' is behind remote tracking "
                    message+="branch by ${commitsAhead} commit${plural} "
                    message+="and can be fast-forwarded."
                    print_message "${message}"

                    # The easiest way to do a fast-forward merge
                    # without having to switch to another branch first
                    # (git merge would require that) is to do a rebase
                    # against upstream branch instead. The git rebase
                    # command will automatically discover that it is
                    # possible to do a fast-forward merge instead of a
                    # rebase when this is the case.
                    #
                    # It is important to note that at this point we
                    # know that HEAD is indeed an ancestor of
                    # @{upstream}, but also that if HEAD and
                    # @{upstream} are the same commit then they are
                    # each others ancestors. Hence this extra check
                    # above to ensure that there is at least one
                    # commit between @{upstream} and HEAD, otherwise
                    # we would risk rebasing HEAD on top of HEAD@{1}
                    # that would create an unnecessary new commit
                    # with a new SHA...
                    declare -a command
                    command=("${SINGLE}" "Fast forwarding repo '${reponame}'" \
                                         git -C "${repopath}" rebase \
                                         "@{upstream}")
                    run "${command[@]}"
                    print_message "Branch is fast forwarded."
                else
                    message="Branch is up to date with remote tracking branch, "
                    message+="nothing to do."
                    print_message "${message}"
                fi
            else
                message="Local and remote tracking branches have diverged. "
                message+="Not possible to do a fast-forward merge to get them "
                message+="aligned again."
                print_message "${message}"

                message="Please resolve this situation manually, for instance "
                message+="with a rebase operation."
                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
        else
            print_message "Not on target branch (${commitish})"
            print_message "Repo is located at '${repopath}'"
            # We are not on target branch; simply do a checkout of
            # target branch to get there and also get local and
            # upstream branches synchronized at the same time (unless
            # we are checking out a tag).
            declare -a command
            command=("${SINGLE}" "Checking out '${commitish}'" \
                                 git -C "${repopath}" checkout "${commitish}")
            run "${command[@]}"
            print_message "Target branch checked out successfully"
        fi
    else
        local message="Unknown repo URI format; unable to extract repo name "
        message+="from URI '${uri}'."
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit
}


function vcs_checkout_committype()
{
    print_debug_enter

    local repopath="${1}"
    local branchKind="${2}"
    local identifier="${3}"

    local repoKind=""
    repoKind=$(frija_deduce_vcs_type "${repopath}")

    case "${repoKind}" in
        "${GIT_REPO}")
            git_checkout_committype "${repopath}" \
                                    "${branchKind}" \
                                    "${identifier}"
            ;;
        *)
            local message="Unknown repo kind '${repoKind}' determined for "
            message+="URI '${uri}'."
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            ;;
    esac

    print_debug_exit
}


# Return number of commits between two commitish.
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is oldest commitish
#
# Third parameter is newest commitish (default HEAD)
function git_delta_commits()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local oldest="${2}"
    local newest="${3:-HEAD}"

    print_debug "repopath='${repopath=}'"
    print_debug "oldest='${oldest}'"
    print_debug "newest='${newest}'"

    local delta=""
    delta=$(git -C "${repopath}" rev-list --count "${oldest}..${newest}")

    print_debug_exit "${delta}"
    echo "${delta}"
}


# A repo is identified by a combination of
#
# - Tag if current commit is selected by a tag
#
# - Delta to tag (if it exist)
#
# - Branch name (if it exist); up to and including any feature ID
#
# - Current SHA in short-SHA format (4+4 hex digits with a dot in-between)
function git_repo_identity()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local composite="${2}"
    local reponame="${3}"
    local systemname="${4}"

    local currentBranch=""
    currentBranch=$(git_current_branch "${repopath}")

    # Remove any portion of branch name after a Feature ID; it is
    # Feature ID that is guaranteed to be unique, what follows is thus
    # not necessary to use and this also shortens the archive name as
    # well
    if [[ "${currentBranch}" =~ ${_FRIJA_BRANCH_PATTERN} ]]; then
        currentBranch="${BASH_REMATCH[${_FRIJA_BRANCH_INDEX}]}"
    fi

    # Find
    local baseVersion=""
    baseVersion=$(latest_tag "${repopath}" HEAD)
    if [[ -z "${baseVersion}" ]]; then
        # Fallback is to identify first common commit between current
        # branch and develop branch as a short SHA
        baseVersion=$(git -C "${repopath}" merge-base HEAD develop)
        baseVersion="${baseVersion:0:${SHORT_SHA_LENGTH}}"
    fi

    local delta=""
    declare -i baseDelta=0
    baseDelta=$(git_delta_commits "${repopath}" "${baseVersion}")
    if (( delta < 10 )); then
        # Pad delta with leading zero if delta is less than 10. No
        # need to handle padding for larger deltas. This is simply due
        # to that if you have a delta of 99 commits on your task
        # branch, then you should really have considered doing a
        # rebase with squash to consolidate your commits way before
        # you reached 99 commits. Also, if there are more than 99
        # commits between HEAD on feature branch and last version tag
        # on develop there are other problems that are way worse.
        delta="0"
    fi
    delta+="${baseDelta}"

    # Now we can strip short SHA from tag if it is a tag name, or make
    # a shrink wrapped SHA of it
    if [[ "${baseVersion}" == *"${SHA_SEPARATOR}"* ]]; then
        baseVersion="${baseVersion%%${SHA_SEPARATOR}*}"
    else
        baseVersion=$(shrinkwrap_short_sha "${baseVersion}")
    fi

    local currentSha=""
    currentSha=$(get_short_sha "${repopath}")
    currentSha=$(shrinkwrap_short_sha "${currentSha}")

    local result="(${currentBranch})[${systemname}]${composite}.${reponame}"
    result+="@${baseVersion}-${delta}__@${currentSha}"

    print_debug_exit "${result}"
    echo "${result}"
}
