################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
# This file must not contain any calls to exit unless they are guarded
# using a test on _FRIJA_IS_SOURCED ; it is non-empty when we are
# sourced, otherwise it is assigned the empty string.
#
# The reason is that if a sourced script calls exit, then the users
# shell exits which is most likely not what the user expected when for
# instance trying to complete a command...
#
# File is sourced by frija and .core_preamble.bash scripts.


# Disable X11 forwarding for SSH to get rid of the annoying "X11
# forwarding request failed on channel 0" message in the terminal
# shellcheck disable=SC2034
export GIT_SSH_COMMAND="ssh -x"

# Version value to indicate that it is not a fixed version for a repo.
# shellcheck disable=SC2034
NON_VERSION="floating"

# Extension used for the initial init file used when bootstrapping the
# environment
# shellcheck disable=SC2034
INIT_FILE_EXTENSION=".init"

# Extension used for the data file used by most Frija commands
# shellcheck disable=SC2034
REPO_LIST_EXTENSION=".repos"


# Terminal width
# shellcheck disable=SC2034
WIDTH=$(tput cols)

# Begin bold mode ON sequence
# shellcheck disable=SC2034
BOLD=$(tput bold)

# Begin reverse video ON mode sequence
# shellcheck disable=SC2034
REVERSE=$(tput rev)

# Begin underline ON mode sequence
# shellcheck disable=SC2034
UNDERLINE_ON=$(tput smul)

# Begin underline OFF mode sequence
# shellcheck disable=SC2034
UNDERLINE_OFF=$(tput rmul)

# Clear all attributes
# shellcheck disable=SC2034
CLEAR=$(tput sgr0)


# This variable contain OS-specific path separator
declare OS_PATH_SEPARATOR=""

# This variable contain build environment-specific path separator
declare PATH_SEPARATOR=""

declare WINDOWS_OS="${_VOLLA_WINDOWS_OS}"
declare LINUX_OS="${_VOLLA_LINUX_OS}"

# Detect platform we are running on and initialize OPERATING_SYSTEM,
# PWA, and OS_PWA
_unameOut="$(uname -s)"
case "${_unameOut}" in
    Linux*)
        OS_SEPARATOR="/"
        OS_PATH_SEPARATOR=":"
        PATH_SEPARATOR=":"
        ;;
    CYGWIN*)
        OS_SEPARATOR="\\"
        OS_PATH_SEPARATOR=";"
        PATH_SEPARATOR=":"
        ;;
    MINGW*)
        OS_SEPARATOR="\\"
        OS_PATH_SEPARATOR=";"
        PATH_SEPARATOR=":"
        ;;
    *)
        print_error "Unknown platform '${_unameOut}', aborting." 3
        ;;
esac


_VOLLA_HOME_FOLDER="volla"
_VOLLA_PATH="${PWA}/${_VOLLA_HOME_FOLDER}"

_FRIJA_HOME_FOLDER="frija"
_FRIJA_PATH="${PWA}/${_FRIJA_HOME_FOLDER}"

# Marker folder signifying the home of Frija specific files
_FRIJA_FOLDER_NAME=".frija"

# Name of config-file containing JIRA-specific configuration that
# frija-commands depend on.
_FRIJA_CONFIG_NAME=".frija_config"

# These variables are assigned a value when _frija_locate_frija_home
# function is called
_FRIJA_CONFIG_PATH=""
_FRIJA_FOLDER_PATH=""
_FRIJA_JIRA=""


# _frija_file_list places its return value (array of files) in this
# array. When Bash 4.3 or newer is available a nameref local variable
# should be used instead.
#
# That is, all uses of below variable should be removed.
declare -a _FRIJA_FILE_LIST
_FRIJA_FILE_LIST=()


function _frija_print_error()
{
    print_separator
    print_message "${BOLD}Error:${CLEAR} ${1}"
    print_separator

    print_message ""
    print_message "Try '${BOLD}${_FRIJA_USAGE_NAME} --help${CLEAR}' for more information."
    print_message ""

    if [[ "${_FRIJA_IS_SOURCED}" == "" ]]; then
        # Only exit when top level script is NOT sourced
        exit "${2}"
    else
        return "${2}"
    fi
}


function frija_closest_branch()
{
    local result=""

    # git log --oneline --decorate=short HEAD^
    #
    # Use git log to get one line per commit where first line is
    # newest commit and start from commit before HEAD using "HEAD^".
    # Also ensure that the corresponding branch and tag names are
    # included in the output also when redirecting (--decroate=short).
    #
    #
    # grep "^[a-z0-9]* ([^)]*\\(origin\\|develop\\|master\\)"
    #
    # Pick only lines that contain a branch; they start either with
    # origin or are named "master" or "develop".
    #
    #
    # sed -e "s/[)].*/)/" -e "s/HEAD.*, //" -e "s/tag[:][^,]*, //"...
    #
    # Use sed to remove things from the remaining lines, each part
    # works like this (filter are run sequentially)
    #
    # -e "s/[)].*/)/"
    # Replace everything after (and including) first ')' with ')'
    #
    # -e "s/HEAD.*, //"
    # Remove everything starting with 'HEAD' and ending with ', '
    #
    # -e "s/tag[:][^,]*, //"
    # Remove everything starting with 'tag:' and ending with ', '
    #
    # -e "s|origin/||"
    # Remove 'origin/'; here | is used instead of / as separator
    #
    # -e "s/[()]//g"
    # Remove all '(' and ')' characters
    #
    # -e "s/, /\\n/g"
    # Finally replace all ', ' with a newline character
    #
    #
    # head --lines=1
    # Only pick first line
    result=$(git log --oneline --decorate=short HEAD^ | grep "^[a-z0-9]* ([^)]*\\(origin\\|develop\\|master\\)" | sed -e "s/[)].*/)/" -e "s/HEAD.*, //" -e "s/tag[:][^,]*, //" -e "s|origin/||" -e "s/[()]//g" -e "s/, /\\n/g" | head --lines=1)

    # Result now contain a short SHA plus corresponding branch name
    # separated by a single space, return it
    echo "${result}"
}


function restore_globignore_expression()
{
    if [[ -v GLOBIGNORE ]]; then
        # Save current value in returned expression
        echo eval GLOBIGNORE="\"${GLOBIGNORE}\""
    else
        # Unset GLOBIGNORE in returned expression, since it was unset
        # when this function was called
        echo unset -v GLOBIGNORE
    fi
}


function frija_list_files()
{
    # We want the expansion to expand before trap executes to be able
    # to restore it to its original value.
    #
    # shellcheck disable=SC2064
    trap "$(restore_globignore_expression)" RETURN

    # Use nameref for indirection, that is $array hold a reference to
    # the variable used as the first (in this case) parameter of this
    # function. That is, it behaves in the same way as a reference in
    # Java, C#, or C++
    #
    # When Bash 4.3 or newer is used the nameref variable files could
    # be used instead.
    #local -n files="${1}"
    local -a files

    local pathPrefix="${2}"
    local filePrefix="${3}"
    local fileSuffix="${4}"
    local globIgnore="${5:-}"

    if [[ -n "${globIgnore}" ]]; then
        # Exclude all files with file names matching the GLOBIGNORE glob
        # when doing globbing file name expansion.
        GLOBIGNORE="${globIgnore}"
    fi

    if [[ -d "${pathPrefix}" ]]; then
        # Glob-expand path to get all files located in $pathPrefix and
        # that starts with $filePrefix and store result in $files
        files=("${pathPrefix}"/"${filePrefix}"*"${fileSuffix}")

        if [[ "${files[0]}" == "${pathPrefix}/${filePrefix}*${fileSuffix}" ]]; then
            # There were no files matching the glob
            files=()
        else
            # Remove $pathPrefix from each element in the $files array
            files=("${files[@]##${pathPrefix}/}")
        fi
    fi

    # Remove 2 lines below when Bash 4.3 or newer is used.
    # shellcheck disable=SC2034
    _FRIJA_FILE_LIST=("${files[@]}")
}
