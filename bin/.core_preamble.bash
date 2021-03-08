# More safety, by turning some bugs into errors. Without 'errexit' you
# don't need ! and can replace PIPESTATUS with a simple $?, but then
# we would need to remember to explcitly test return status for each
# command. Note that ! hides the exit status of the executed command.
# Due to this we have to use PIPESTATUS to get to it.
set -o errexit -o pipefail -o noclobber -o nounset


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


# Remove longest matching prefix matching "*/", i.e. all paths up to
# but not including the program name
PROGRAM_NAME="${PROGRAM_PATH##*/}"

# If command is "frija-build" then NAME will be "build"
NAME=${PROGRAM_NAME//-/ }


# OS variant
declare OPERATING_SYSTEM=""

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


# shellcheck disable=SC2034
CONFIG_NAME="metadata-config.bash"

VOLLA_HOME_FOLDER="volla"

VOLLA_PATH="${PWA}/${VOLLA_HOME_FOLDER}"

# Marker folder signifying the home of Frija specific files
# shellcheck disable=SC2034
FRIJA_FOLDER_NAME=".frija"

FRIJA_HOME_FOLDER="frija"

# This global variable is dynamically set depending on Jira issue
# number, that is it is the path to a folder that contain
# FRIJA_FOLDER_NAME which in turn depend on Jira issue number.
FRIJA_HOME=""

# shellcheck disable=SC2034
FRIJA_PATH="${PWA}/${FRIJA_HOME_FOLDER}"

FRIJA_CONFIG_NAME=".frija_config"

# shellcheck disable=SC2034
FRIJA_CONFIG_PATH="${VOLLA_PATH}/${FRIJA_CONFIG_NAME}"


function cleanup()
{
    if [[ -n "${FRIJA_HOME}" ]]; then
        if [[ -d "${FRIJA_HOME}/${FRIJA_FOLDER_NAME}" ]]; then
            cd "${FRIJA_HOME}/${FRIJA_FOLDER_NAME}"

            echo "Cleaning up ${FRIJA_HOME}/${FRIJA_FOLDER_NAME} ..."
            # Remove all files stored here
            rm -fr ./*
            echo "Done!"
        fi
    fi
}

# Install exit trap function that will be called when script exits
trap cleanup EXIT


function ensure_option_not_set()
{
    if [[ -n "${2}" ]]; then
        print_error "Multiple ${BOLD}'${1}'${CLEAR} options not allowed!" 2
    fi
}


function ensure_option_argument_set()
{
    if [[ -z "${2}" ]]; then
        print_error "${BOLD}'${1}'${CLEAR} option argument must not be an empty string." 2
    fi
}


function ensure_mode_set()
{
    local target_mode="${1}"
    local current_mode="${2}"
    local option="${3}"

    if [[ -z "${current_mode}" ]]; then
        print_error "Must be in ${BOLD}${target_mode}${CLEAR} mode to use ${BOLD}'${option}'${CLEAR} option." 2
    elif [[ "${current_mode}" != "${target_mode}" ]]; then
        print_error "${BOLD}'${option}'${CLEAR} option may only be used in ${BOLD}${target_mode}${CLEAR} mode."
    fi
}


function ensure_mode_not_set()
{
    local target_mode="${1}"
    local current_mode="${2}"

    if [[ -n "${current_mode}" ]]; then
        if [[ "$current_mode" == "${target_mode}" ]]; then
            print_error "${BOLD}${current_mode}${CLEAR} mode may not be repeated." 2
        else
            print_error "${BOLD}${current_mode}${CLEAR} mode may not be combined with ${BOLD}${target_mode}${CLEAR} mode." 2
        fi
    fi
}


function ensure_boolean_option_not_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" != "n" ]]; then
            print_error "Multiple ${BOLD}'${1}'${CLEAR} options not allowed!" 2
        fi
    fi
}


function print_initfile_format_doc()
{
    echo
    echo
    echo "${BOLD}Initifile file format:${CLEAR}"
    cat "$PROGRAM_DIR/.initfile_format_doc.txt"
}


function print_file_format_doc()
{
    echo
    echo
    echo "${BOLD}Repo list file format:${CLEAR}"
    cat "$PROGRAM_DIR/.file_format_doc.txt"
}


function print_exit_codes_doc()
{
    echo
    echo
    echo "${BOLD}Exit status:${CLEAR}"
    cat "$PROGRAM_DIR/.exit_codes_doc.txt"
}


# NOTE: Command line parsing below relies on GNU getopt which is a
# separate binary that canonicalizes the command line so it can be
# more easily parsed and sould not be confused with the Bash builtin
# getopts which does not support long options and so on.

# Ensure that we actually use GNU getopt
# - Allow command to fail with !'s side effect on errexit
# - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "Aborting, GNU getopt not in search path.";
    exit 1
fi

# Ensure getopt is not working in compatible mode as this makes
# parsing of optional arguments virtually impossible.
unset -v GETOPT_COMPATIBLE

! PARSED=$(getopt --options="$OPTIONS" --longoptions="$LONGOPTS" --name "$NAME" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # E.g. return value is 1
    #  Then getopt has complained to stdout about wrong arguments
    usage;
    exit 2
fi

# To handle quoting correctly in output from getopt we have to do this
eval set -- "$PARSED"


# NOTE: Command line parsing below relies on GNU getopt which is a
# separate binary that canonicalizes the command line so it can be
# more easily parsed and sould not be confused with the Bash builtin
# getopts which does not support long options and so on.

# Ensure that we actually use GNU getopt
# - Allow command to fail with !'s side effect on errexit
# - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo "Aborting, GNU getopt not in search path.";
    exit 1
fi

# Ensure getopt is not working in compatible mode as this makes
# parsing of optional arguments virtually impossible.
unset -v GETOPT_COMPATIBLE

! PARSED=$(getopt --options="$OPTIONS" --longoptions="$LONGOPTS" --name "$NAME" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # E.g. return value is 1
    #  Then getopt has complained to stdout about wrong arguments
    usage;
    exit 2
fi

# To handle quoting correctly in output from getopt we have to do this
eval set -- "$PARSED"


function plural()
{
    local count="${1}"
    local result="s"

    if [[ "${count}" == "1" ]]; then
        result=""
    fi

    echo "${result}"
}


function print_message()
{
    # Ensure given text wraps nicely to terminal width
    fold --spaces --width="${WIDTH}"<<<"${1}"
}


function print_error()
{
    echo -n "${BOLD}Error:${CLEAR} "

    print_message "${1}"

    echo "Try '$NAME --help' for more information."

    if [[ -n "${2}" ]]; then
        exit "${2}"
    fi
}


function print_command_error()
{
    local msg
    msg="${BOLD}Illegal combination of options;${CLEAR} ${1} may not be combined with ${2}."
    print_error "${msg}" "${3}"
}


function print_command_failure_status()
{
    local status="${1}"
    local command="${2}"

    echo "Command"
    echo "${command}"
    echo "failed with exit code ${status}, rerun with --verbose or -v."
}


function print_separator()
{
    if [[ -z "${1}" ]];
    then
        echo "--------------------"
    else
        echo "----- $1 -----"
    fi
}


function conditional_separator_print_before()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ ("${method}" == "${SINGLE}") || ("${method}" == "${FIRST}") ]]; then
        print_separator "${field}"
    fi
}


function conditional_separator_print_after()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ "${method}" == "${SINGLE}" || "${method}" == "${LAST}" ]]; then
        print_separator "${field}"
        echo
    fi
}


function set_dry_run()
{
    ensure_boolean_option_not_set "Dry run" "${DRY_RUN}"
    DRY_RUN="y"
}


####
# Constants used for controlling echo behavior of run command.

# Single command with separators before and after command
SINGLE="single"

# Only separator before command
FIRST="first"

# No separator AND command echo in non-verbose mode
#
# Ignore shellcheck complaining about not used variable
# shellcheck disable=SC2034
MIDDLE="middle"

# Only separator after command
LAST="last"

# No separator and NO command echo in non-verbose mode
NONE="none"


# Copy of PIPESTATUS when a command is executed by run function.
declare -a STATUS


# As run function below but also redirects stdout to given destination in $3
function run_with_redirect()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # If and where to redirect stdout from command
    local destination="${3}"

    # Skip first two arguments
    shift 3

    # Store rest of args in command array
    declare -a command
    local command=("${@}")


    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[*]} >| ${destination}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >| ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}" 2> /dev/null
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    fi

    return "${STATUS[0]}"
}


# Run a command in different ways:
# * If verbose mode is set to "y"
#   o Show stdout AND stderr output from command
#   o If dry-run enabled, show command line but do not execute
# * If verbose mode is set to NOT "y"
#   o If dry-run enabled, do not execute
#   o If method is _not_ NONE, echo command line
#   o Hide stdout AND stderr from command
#     - If command fails, print message to stdout
#
# Note PIPESTATUS[0] is returned, but complete PIPESTATUS is saved in
# global variable STATUS.
function run()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # Skip first two arguments
    shift 2

    # Store rest of args in command array
    declare -a command
    local command=("${@}")

    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[@]}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}"
            STATUS=("${PIPESTATUS[@]}")
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" &>/dev/null
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    fi

    return "${STATUS[0]}"
}


function make_destination()
{
    local mg="${1}"
    local name="${2}"
    local version="${3}"
    local result=""

    if [[ -n "${mg}" ]]; then
        if [[ -n "${version}" ]]; then
            result="${mg}/${name}/${version}"
        fi
    elif [[ -n "${version}" ]]; then
        result="${name}/${version}"
    else
        result="${name}"
    fi

    echo "${result}"
}


function make_replication_message()
{
    local prefix="${1}"
    local name="${2}"
    local version="${3}"
    local destination="${4}"

    local result=""

    if [[ "${name}" == "${destination}" ]]; then
        echo "${prefix} ${name}..."
    else
        echo "${prefix} ${name} ${version} to ${destination}..."
    fi

    echo "${result}"
}


# Regex pattern used for capturing name of repo
GIT_REPO_PATTERN=".*/([^/]+).git"

# source: Type of service to use when replicating, e.g. git
# uri: From where to obtain the data
# mg: Material Group name, e.g. 97-60 [optional]
# version: Version identifier to use, e.g. "x.y.z" [optional]
#
# NOTE: Name of destination folder is derived from uri, mg, and
# version using the function make_destination().
function replicate_data()
{
    local source="${1}"
    local uri="${2}"
    # Make $3 optional by having default value be an empty string
    local mg="${3:-}"
    # Make $4 optional by having default value be an empty string
    local version="${4:-}"

    local destination=""
    local message=""
    local name=""
    local replication_type=""

    # Make command to be a local variable and an array
    declare -a command

    case "${source}" in
        git)
            [[ "$uri" =~ $GIT_REPO_PATTERN ]]
            name="${BASH_REMATCH[1]}"
            destination=$(make_destination "${mg}" "${name}" "${version}")
            message=$(make_replication_message "Cloning" "${name}" "${version}" "${destination}")
            command=(git clone "$uri" "$destination")
            replication_type="cloned"
            ;;
        *)
            print_error "Unsupported SOURCE: '${source}' for '${uri}', aborting."
            exit 6
            ;;
    esac


    if [[ "${DEBUG}" == "y" ]]; then
        echo "*** $LINENO  name: $name"
        echo "*** $LINENO  destination: $destination"
        echo "*** $LINENO  command: ${command[*]}"
    fi

    echo "$message"
    if [[ ! -d "$destination" ]]; then
        if [[ "${VERBOSE}" == "y" ]]; then
            # Send any stderr output from command to terminal
            print_separator "${name}"
            if [[ "${DRY_RUN}" == "y" ]]; then
                echo "${command[@]}"
            else
                "${command[@]}"
            fi
            print_separator "${name}"
            echo ""
        else
            if [[ "${DRY_RUN}" == "y" ]]; then
                echo "${command[@]}"
            else
                # Ignore anything sent to stdout and stderr
                ! "${command[@]}" &>/dev/null
                if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
                    # E.g. return value is 1
                    echo "Command"
                    echo "${command[@]}"
                    echo "failed with exit code ${PIPESTATUS[0]}, rerun with --verbose or -v."
                    # Cleaning up
                    rm -fr "${destination}"
                    exit 5
                fi
            fi
        fi
    else
        echo "   ${destination} already ${replication_type}, skipping."
        echo ""
    fi
}
