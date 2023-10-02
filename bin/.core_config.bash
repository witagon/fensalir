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


# PWA == Personal Work Area
# This variable holds the *nix-like path to users private PWA folder
declare PWA=""

# This variable holds the OS-specific path to users private PWA folder
declare OS_PWA=""

# Detect platform we are running on and initialize OPERATING_SYSTEM,
# PWA, and OS_PWA
_unameOut="$(uname -s)"
case "${_unameOut}" in
    Linux*)
        OPERATING_SYSTEM="Linux"
        PWA="/p/pwa/${USER}"
        OS_PWA="${PWA}"
        ;;
    CYGWIN*)
        OPERATING_SYSTEM="Windows"
        PWA="/x"
        OS_PWA="X:/"
        ;;
    MINGW*)
        # shellcheck disable=SC2034
        OPERATING_SYSTEM="Windows"
        PWA="/x"
        # shellcheck disable=SC2034
        OS_PWA="X:/"
        ;;
    *)
        print_error "Unknown platform '${_unameOut}', aborting." 3
        ;;
esac


_VOLLA_HOME_FOLDER="volla"

_VOLLA_PATH="${PWA}/${_VOLLA_HOME_FOLDER}"

# Marker folder signifying the home of Frija specific files
# shellcheck disable=SC2034
_FRIJA_FOLDER_NAME=".frija"

_FRIJA_HOME_FOLDER="frija"

# shellcheck disable=SC2034
_FRIJA_PATH="${PWA}/${_FRIJA_HOME_FOLDER}"

_FRIJA_CONFIG_NAME=".frija_config"

# shellcheck disable=SC2034
_FRIJA_CONFIG_PATH="${_VOLLA_PATH}/${_FRIJA_CONFIG_NAME}"

# _frija_file_list places its return value (array of files) in this
# array. When Bash 4.3 or newer is available a nameref local variable
# should be used instead.
#
# That is, all uses of below variable should be removed.
declare -a _FRIJA_FILE_LIST
_FRIJA_FILE_LIST=()


function _frija_print_error()
{
    echo -n "${BOLD}Error:${CLEAR} "

    print_message "${1}"

    echo "Try '$NAME --help' for more information."

    if [[ "${_FRIJA_IS_SOURCED}" == "" ]]; then
        # Only exit when top level script is NOT sourced
        exit "${2}"
    else
        return "${2}"
    fi
}


function frija_list_files()
{
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

    {
        echo "pathPrefix='${pathPrefix}'"
        echo "filePrefix='${filePrefix}'"
        echo "fileSuffix='${fileSuffix}'"
        echo "globIgnore='${globIgnore}'"
    } >> /tmp/foo.log

    if [[ -n "${globIgnore}" ]]; then
        # Exclude all files with file names matching the GLOBIGNORE glob
        # when doing globbing file name expansion.
        #
        # Note: This setting is local to this function, so there is no
        # need to do any fancy save and restore operation of the
        # GLOBIGNORE variable.
        GLOBIGNORE="${globIgnore}"
    fi

    local foo=("/p/pwa-user/8/johnols/frija/FLTS-4452/"*".repos")
    echo "foo='${foo[*]}" >> /tmp/foo.log
    if [[ -d "${pathPrefix}" ]]; then
        echo "pathPrefix='${pathPrefix}' exists!" >> /tmp/foo.log

        # Glob-expand path to get all files located in $pathPrefix and
        # that starts with $filePrefix and store result in $files
        files=("${pathPrefix}"/"${filePrefix}"*"${fileSuffix}")
        echo "files='${files[*]}'" >> /tmp/foo.log

        if [[ "${files[0]}" == "${pathPrefix}/${filePrefix}*${fileSuffix}" ]]; then
            # There were no files matching the glob
            echo "No files matching" >> /tmp/foo.log
            files=()
        else
            # Remove $pathPrefix from each element in the $files array
            files=("${files[@]##${pathPrefix}/}")
            echo "filtered files='${files[*]}'" >> /tmp/foo.log
        fi
    fi

    # Remove 2 lines below when Bash 4.3 or newer is used.
    # shellcheck disable=SC2034
    _FRIJA_FILE_LIST=("${files[@]}")
    echo "_FRIJA_FILE_LIST='${_FRIJA_FILE_LIST[*]}'" >> /tmp/foo.log
}
