# This file is sourced by .preamble.bash.

# Remove longest matching prefix matching "*/", i.e. all paths up to
# but not including the program name
_FRIJA_PROGRAM_NAME="${_FRIJA_PROGRAM_PATH##*/}"

# If command is "frija-build" then _FRIJA_NAME will be "build"
_FRIJA_USAGE_NAME=${_FRIJA_PROGRAM_NAME//-/ }

# This global variable is dynamically set depending on Feature ID,
# that is it is the path to a folder that contain
# _FRIJA_CONFIG_FOLDER_NAME which in turn depend on Feature ID.
# _FRIJA_CONFIG_FOLDER_PATH is in turn a convenience variable that
# contain the path to the config folder in _FRIJA_CONFIG_FOLDER_NAME.
_FRIJA_WS_PATH=""

# This global variable hold the current working directory. What
# differs compared to PWD is that it is set once during the script
# execution and that it is corrected if PWD points to within a PWA
# folder but contain the actual path and not the symlinked "/p/pwa/"
# path.
_FRIJA_PWD=""

# TODO: Is this good or bad?
#
# Guard against this script being sourced multiple times.
#
# Note: -v tests if variable name is set or not.
if [[ -v _CORE_PREAMBLE_IS_SOURCED ]]; then
    return
fi
_CORE_PREAMBLE_IS_SOURCED="y"

# Include common configuration (global variables)
# shellcheck source=./.core_config.bash
source "${_FENSALIR_HOME}/.core_config.bash"

# TODO: Add _FRIJA_ prefix
#
# Regex pattern used for capturing name of repo
#
# TODO: Better to use stricter regexp such as below?
# ^[a-zA-Z]+://.*/([^/]+)[._]([a-zA-Z]+)$
GIT_BITBUCKET_REPO_PATTERN=".*/([^/]+).git"
GIT_TFS_REPO_PATTERN=".*/_git/([^/]+)"
GIT_REPO_PATTERN="^${GIT_BITBUCKET_REPO_PATTERN}|${GIT_TFS_REPO_PATTERN}$"

GIT_REPO="git"


# Destructively filter out empty elements from the indirectly
# referenced array. Note that the array indexes are unmodified.
#
# First parameter; Name of array to trim
function _frija_trim_array()
{
    local arrayname="${1}"

    # Expand the array reference to the number of elements in the
    # array. If Bash 4.3 or newer can be used then replace with named
    # references instead to get simpler code.
    local arrayRef="${arrayname}[@]"
    declare -i index=0
    local element=""
    for element in "${!arrayRef}"; do
        if [[ -z "${element}" ]]; then
            unset "${arrayname}[${index}]"
        fi
        (( index++ ))
    done
}


# Destructively filter out elements equal to the given value from the
# indirectly referenced array. Note that the array indexes are
# unmodified.
#
# First parameter; Name of array to filter
#
# Second parameter; Element value to remove from array
#
# Third parameter; If non-empty, trim any empty elements from the array as well
function _frija_filter_array()
{
    local arrayname="${1}"
    local value="${2}"
    local trim="${3}"

    # Expand the array reference to the number of elements in the
    # array. If Bash 4.3 or newer can be used then replace with named
    # references instead to get simpler code.
    local arrayRef="${arrayname}[@]"
    declare -i index=0
    local element=""
    for element in "${!arrayRef}"; do
        # Update the indirect reference to point to specific element
        # in array. Named references would simplify this as well.
        if [[ -n "${trim}" && -z "${element}" ]] \
               || [[ "${element}" == "${value}" ]]
        then
            unset "${arrayname}[${index}]"
        fi
        (( index++ ))
    done

    print_debug_array "${arrayname}"
}


# Create a natural language sequence from a entries in an array. That
# is, if the array is (a b c) then the output from this function could
# the string "a, b, and c". On the other hand, if the array is (a b)
# then the output could be "a and b".
#
# First parameter is the conjunction to use, that is "and" or "or"
#
# Second parameter is the name of the array to create the sequence for.
#
# Third parameter If provided and set to $BOLD, then each item in the
#                 list is bolded. (Optional)
function _frija_create_sentence_sequence()
{
    local conjunction="${1}"
    local arrayname="${2}"
    local bold="${3:-}"

    local prefix=""
    local suffix=""
    if [[ "${bold}" == "${BOLD}" ]]; then
        print_debug "Using BOLD"
        prefix="${BOLD}"
        suffix="${CLEAR}"
    fi

    # Create an array reference
    local arrayRef="${arrayname}[@]"
    # Expand the array reference to the content of the array and
    # assign it to a new array. If Bash 4.3 or newer can be used then
    # replace with named references instead to get simpler code.
    declare -a tempItems=("${!arrayRef}")
    declare -a items=()

    # Filter out any empty elements from the array by copying
    # non-empty elements to the new array. This is due to that if
    # unset had been used to remove elements from the array then holes
    # in the array would have been created. By copying the array this
    # is avoided since the indices in the new array are consecutive.
    declare -i index=0
    local element=""
    for index in "${!tempItems[@]}"; do
        element="${tempItems[index]}"
        if [[ -n "${element}" ]]; then
            items+=("${element}")
        fi
    done

    local itemSequence=""
    declare -i length=${#items[@]}
    if (( length > 2 )); then
        for entry in "${items[@]::length-1}"; do
            itemSequence+="${prefix}${entry}${suffix}, "
        done
        itemSequence+="and ${prefix}${items[length-1]}${suffix}"
    elif (( length > 1 )); then
        itemSequence="${prefix}${items[0]}${suffix} ${conjunction} "
        itemSequence+="${prefix}${items[1]}${suffix}"
    elif (( length > 0 )); then
        itemSequence="${prefix}${items[0]}${suffix}"
    fi

    echo "${itemSequence}"
}


# Fields used in the comment header of the input file and their
# corresponding global variables
#

# Fields to look for in the head of the .repos file and the
# corresponding global variable names to store the read values in.
# Since we want to print the fields in a specific order but still use
# an associative array we need to use both an indexed array and an
# associative array (since the latter is ordered by hash value). In
# order to no duplicate inforamtion the associative array is
# constructed from the ordered array.
declare -a _FRIJA_REPOS_KEY_VALUES=(
    "Build Env Repo: _FRIJA_ENVIRONMENT_REPO_NAME"
    "Build Env Repo SHA: _FRIJA_ENVIRONMENT_REPO_SHA"
    "Volla Repo: _FRIJA_VOLLA_REPO"
    "Version Tag: _FRIJA_VERSION_TAG"
    "Delta Commits: _FRIJA_DELTA_COMMITS"
    "Current SHA: _FRIJA_CURRENT_SHA"
    "Branch Name: _FRIJA_BRANCH_NAME"
    "System: _FRIJA_SYSTEM_NAME"
    "System Version: _FRIJA_SYSTEM_VERSION"
    "Subsystem: _FRIJA_SUBSYSTEM_NAME"
    "Subsystem Version: _FRIJA_SUBSYSTEM_VERSION"
    "Repo Filter: _FRIJA_REPO_FILTER")

# Go from field name to global variable name
declare -A _FRIJA_REPOS_METAFIELDS=()
for keyval in "${_FRIJA_REPOS_KEY_VALUES[@]}"; do
    # Treat everything BEFORE space as key and AFTER colon+space as value
    _FRIJA_REPOS_METAFIELDS+=(["${keyval% *}"]="${keyval#*: }")
done

# Go from global variable name to field name
declare -A _FRIJA_REVERSE_REPOS_METAFIELDS=()
for keyval in "${_FRIJA_REPOS_KEY_VALUES[@]}"; do
    # Treat everything AFTER colon+space plus '_FIELD' as global
    # variable name and everything BEFORE space as value
    #
    # That is 'Locale Repo: _FRIJA_LOCALE_REPO_NAME' result in global
    # variable '_FRIJA_LOCALE_REPO_NAME_FIELD' set to 'Locale Repo:'
    variableName="${keyval#*: }_FIELD"
    value="${keyval% *}"

    if [[ -n "${variableName}" ]]; then
        declare -g "${variableName}"="${value}"
    else
        message="Empty variable name when extracting from '${keyval}'"
        print_warning "${message}"
    fi
done



# Parse a comment line in .repos file and extract any metadata setting
# if it is there. This function updates the corresponding global value
# if it is known. If an unknown field is found a warning message is
# printed to the terminal.
function _frija_parse_repos_file_comment_line()
{
    print_debug_enter "${@}"

    line="${1}"

    local metadataRegex="^[ ]*#[ ]*([a-zA-Z][a-zA-Z ]*[a-zA-Z]:)[ ]*([^ ]+)$"
    if [[ "${line}" =~ ${metadataRegex} ]]; then
        local field="${BASH_REMATCH[1]}"
        local value="${BASH_REMATCH[2]}"

        if (( ALL_METAFIELDS_SET == 0 )); then
            # Fetch variable name from associative array based on field name
            variableName="${_FRIJA_REPOS_METAFIELDS[${field}]:-}"

            if [[ -n "${variableName}" ]]; then
                declare -g "${variableName}"="${value}"
            elif [[ "${field}" == *":" ]]; then
                message="Unknown metadata-field '${field}'"
                print_warning "${message}"
            fi
        fi
    fi

    print_debug_exit
}


# Non-meta item field names read from each non-commented line in
# .repos file. Can be used for instance for indirect variable name
# access, e.g. when passing a field name to a function and not the
# value.
_FRIJA_OS="os"
_FRIJA_VCS="vcs"
_FRIJA_COMPOSITE="composite"
_FRIJA_VERSION="version"
_FRIJA_URI="uri"
_FRIJA_REPOKIND="repoKind"
_FRIJA_TOOL="tool"
_FRIJA_DEPENDENCIES="dependencies"
_FRIJA_TOOLDEPENDENCIES="toolDependencies"
_FRIJA_LOCALE="locale"
_FRIJA_EXTERNALDEPS="externalDeps"
_FRIJA_TAGS="tags"
_FRIJA_REST="rest"

# Array of non-meta items to read from each non-commented line in
# .repos file.
#
# Note: The items are listed in the order they are expected to be in
# the .repos input file.
declare -a _FRIJA_REPOS_ITEMS=(
    "${_FRIJA_OS}"
    "${_FRIJA_VCS}"
    "${_FRIJA_COMPOSITE}"
    "${_FRIJA_VERSION}"
    "${_FRIJA_URI}"
    "${_FRIJA_REPOKIND}"
    "${_FRIJA_TOOL}"
    "${_FRIJA_DEPENDENCIES}"
    "${_FRIJA_TOOLDEPENDENCIES}"
    "${_FRIJA_LOCALE}"
    "${_FRIJA_EXTERNALDEPS}"
    "${_FRIJA_TAGS}"
    "${_FRIJA_REST}")

# Associative array mapping between repo-name (expressed as a
# combination of composite, repo-name, and repo-version). To do a
# lookup in this hash-map the accessor-function _frija_repo_kind()
# should be used.
declare -A _FRIJA_REPO_KINDS=()

# Lookup repo-kind for a given repo; possible repo kinds are defined
# in file ".preamble.bash". In order to globally identify a repo its
# composite and version must also be provided.
#
# First parameter is composite repo belongs to.
#
# Second parameter is name of repo.
#
# Third parameter is version of repo to lookup kind for.
function _frija_repo_kind()
{
    local composite="${1}"
    local reponame="${2}"
    local version="${3}"

    local result="${_FRIJA_REPO_KINDS[${reponame}_${composite}_${version}]:-}"

    echo "${result}"
}


# Internal helper function.
function __frija_add_repo_kind()
{
    print_debug_enter "${@}"
    local composite="${1}"
    local reponame="${2}"
    local version="${3}"
    local repokind="${4}"

    _FRIJA_REPO_KINDS["${reponame}_${composite}_${version}"]="${repokind}"

    print_debug_exit
}

# Use regexp based on VCS system to extract name of repo from
# clone-URI.
function _frija_reponame_from_uri()
{
    print_debug_enter "${@}"

    local vcs="${1}"
    local uri="${2}"
    local inputFile="${3:-}"

    local repoName=""
    case "${vcs}" in
        git)
            if [[ "${uri}" =~ ${GIT_REPO_PATTERN} ]]; then
                repoName="${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}"
            else
                message="Unsupported ${BOLD}Git repo URI path${CLEAR}: URI is "
                message+="'${uri}' and pattern is '${GIT_REPO_PATTERN}', "
                message+="aborting."
                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            fi
            ;;
        *)
            message="Unsupported VCS: '${vcs}' for '${uri}' "
            if [[ -n "${inputFile}" ]]; then
                message+="found in input file '${inFile}'"
            fi
            message+=", aborting."
            print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            ;;
    esac

    print_debug_exit "${repoName}"
    echo "${repoName}"
}


# NOTE: This function is only intended to be called from the main loop
# parsing the .repos file.
#
# Given line is parsed using read function and fields read are
# assigned to the items listed in the $_FRIJA_REPOS_ITEMS array (in
# the order listed in the array). The variables assigned are the first
# found on the stack, hence it is very strongly recommended that this
# function is called from the top level and not from another function.
#
# First parameter is line to parse
#
# This function relies only on implicit side effects!
function _frija_parse_repos_file_line ()
{
    print_debug_enter "${@}"

    local line="${1}"

    # Parse line we just read; values are stored in the variable names
    # listed in $_FRIJA_REPOS_ITEMS, the expression
    # ${_FRIJA_REPOS_ITEMS[@]} (NOT "${_FRIJA_REPOS_ITEMS[@]}")
    # expands to a space separated list of the values which then the
    # read command uses to assign values to the respective variable
    # names.
    #
    # TODO: Investigate why comment and actual expression below differ!
    read -r "${_FRIJA_REPOS_ITEMS[@]}" <<< "${line}"

    # Strip any carriage returns from the read values
    for element in "${_FRIJA_REPOS_ITEMS[@]}"; do
        # We are forced to use eval here since it is not possible
        # to do indirect assignments in Bash 4.2. However named
        # variable references might work which are included in
        # Bash 4.3 and if that version or newer is made available
        # in Linux, then the code could be made much cleaner.
        eval "${element}=\${${element}//\$'\\r'}"
        print_debug "${element}='${!element}', "
    done

    local reponame=""
    reponame=$(_frija_reponame_from_uri "${!_FRIJA_VCS}" "${!_FRIJA_URI}")
    if [[ -n "${!_FRIJA_COMPOSITE}" ]] \
           && [[ -n "${!_FRIJA_VERSION}" ]] \
           && [[ -n "${reponame}" ]] \
           && [[ -n "${!_FRIJA_REPOKIND}" ]]
    then
        __frija_add_repo_kind "${!_FRIJA_COMPOSITE}" \
                              "${reponame}" \
                              "${!_FRIJA_VERSION}" \
                              "${!_FRIJA_REPOKIND}"
    else
        local message="Given line '${line}' contain "
        message+="${_FRIJA_VCS}='${!_FRIJA_VCS}' and "
        message+="${_FRIJA_URI}='${!_FRIJA_URI}', aborting."
        print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
    fi

    print_debug_exit
}


# Check if program/script sourcing this script is the same as Bash own
# understanding of what its binary is called. When sourced from a
# script $0 contain the name of that script and when sourced from for
# instance .bashrc or from a function in the shell environment $0 is
# instead the bash binary.
#
# It turns out that it is platform dependent whether $0 and/or $BASH
# contain just the name of the binary or the search path to the
# binary. To avoid such inconsitency problems any leading path is
# removed using '##*/' when variable (parameter) is expanded.
#echo "   0='${0##*/}'" 1>&2
#echo "BASH='${BASH##*/}'" 1>&2
if [[ "${0##*/}" == "${BASH##*/}" ]]; then
    # Sourced from outside of a frija-command
    return
fi


# Test if _FRIJA_IS_SOURCED is *not* an empty string
# and
# if _BOOTSTRAP_PATH is unset.
#
# -v tests if variable name is set, and negating test gives instead a
# test whether variable is unset or not.
#
# Note that $_FRIJA_IS_SOURCED is expanded using ':-' to avoid running
# into problems if accessing unset variables is an error (set
# --nounset is enabled).
if [[ ! -v _BOOTSTRAP_PATH ]]; then
    # Top level script is sourced, for instance fensalir_setup.bash
    #
    # Note: This check is ONLY valid when we are not sourced from the
    # bootstrap script. Since it reuses some of the functions defined
    # in this script.

    if [[ ! -v _FRIJA_IS_SOURCED ]]; then
        # Sourced from a script that is not a Frija command and not an
        # init-file, for instance .bashrc
        return
    elif [[ -n "${_FRIJA_IS_SOURCED:-}" ]]; then
        # Sourced from bootstrap-script
        return
    fi
    #echo "FNORD: A.3 (sourced from Frija command)" 1>&2
#else
#    echo "FNORD: B" 1>&2
#    echo "FNORD: $*" 1>&2
#    if [[ -v _BOOTSTRAP_PATH ]]; then
#        echo "FNORD: _BOOTSTRAP_PATH='${_BOOTSTRAP_PATH:-}'" 1>&2
#    else
#        echo "FNORD: _BOOTSTRAP_PATH not defined" 1>&2
#    fi
#
#    if [[ -v _FRIJA_IS_SOURCED ]]; then
#        echo "FNORD: _FRIJA_IS_SOURCED='${_FRIJA_IS_SOURCED:-}'" 1>&2
#    else
#        echo "FNORD: _FRIJA_IS_SOURCED not defined" 1>&2
#    fi
fi



################################################################################
# Below this point it is safe to for instance call exit; above it
# would cause the users shell to exit if we are sourced...


# Name of generated per-repo file with dependency information
#
# shellcheck disable=SC2034
FRIJA_GENERATED_MAKEFILE_FRAGMENT="FrijaGenerated.Makefilefragment"


# Name of generated per-repo dependency graph in Graphviz Dot-format
#
# shellcheck disable=SC2034
FRIJA_GENERATED_DEPENDENCY_GRAPH="FrijaGeneratedDependencyGraph.dot"


# Flag used to indicate that all metadata fields have been assigned a
# value and thus there is no need to go through all of them again.
declare -i ALL_METAFIELDS_SET=0


# This function checks if all metadata fields (originating from .repos
# file) have been assigned a value. If not, then an error is raised.
#
# Note: Once this function is called, it is no longer possible to
# parse any more metadata comment lines and get corresponding variable
# set.
function ensure_all_metafields_set ()
{
    print_debug_enter ""

    if (( ALL_METAFIELDS_SET == 0 )); then
        # Iterate over all values in associative array
        # $_FRIJA_REPOS_METAFIELDS and evaluate them as if they were variable
        # names so we can check if they are set and contain a
        # non-empty string
        local element=""
        for element in "${_FRIJA_REPOS_METAFIELDS[@]}"; do
            local message=""

            if [[ -v "${element}" ]]; then
                if [[ -z "${!element}" ]]; then
                    message="Metadata variable '${element}' is empty, "
                    message+="please ensure that the input file "
                    message+="(.repos file) is not corrupt, aborting."
                fi
            else
                message="Metadata variable '${element}' does not "
                message+="exist, please ensure that the input file "
                message+="(.repos file) is not corrupt, aborting."
            fi

            if [[ -n "${message}" ]]; then
                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            fi
        done

        ALL_METAFIELDS_SET=1
    fi

    print_debug_exit
}


# Frija export configuration file name extension
FRIJA_EXPORT_EXTENSION=".frija"

FRIJA_EXPORT_NAME="prepare"

# shellcheck disable=SC2034
FRIJA_EXPORT_FILE="${FRIJA_EXPORT_NAME}${FRIJA_EXPORT_EXTENSION}"

function frija_config_export_filename()
{
    print_debug_enter

    local system="${1}"
    local systemVersion="${2}"
    local subsystem="${3}"
    local subsystemVersion="${4}"
    local branchName="${5}"
    local versionTag="${6}"
    local deltaCommits="${7}"
    local currentSha="${8}"
    local timeStamp="${9}"

    local result=""

    if [[ -n "${system}" ]]; then

        if [[ -n "${branchName}" ]]; then
            result+="${branchName#*/}_"
        fi

        result+="${system}"
        result+="_${systemVersion}"
        if [[ -n "${subsystem}" ]]; then
            result+="--${subsystem}"
            result+="_${subsystemVersion}"
        fi
        result+="__${versionTag}"
        if [[ -n "${deltaCommits}" ]]; then
            if (( "${deltaCommits}" > 0 )); then
                result+="-${deltaCommits}"
                result+="@${currentSha}"
            fi
        fi
    fi

    if [[ -n "${result}" ]]; then
        result+="_${timeStamp}"
        result+="${FRIJA_EXPORT_EXTENSION}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Ensure WORDY has a value
WORDY=${WORDY:-"n"}


# More safety, by turning some bugs into errors. Without 'errexit' you
# don't need ! and can replace PIPESTATUS with a simple $?, but then
# we would need to remember to explcitly test return status for each
# command. Note that ! hides the exit status of the executed command.
# Due to this we have to use PIPESTATUS to get to it.
set -o errexit -o errtrace -o pipefail -o noclobber -o nounset

# Enable extended globbing that support regular expression-like syntax
shopt -s extglob
# Disable error message if globbing fails
shopt -u failglob
# Enable empty string no match response instead of glob pattern being returned
shopt -s nullglob

# Return intersection between two lists using the form "a,b,c,d";
# comma is used as item separator.
#
# Note that this implementation does NOT support items separated by
# ',' containing any spaces as those spaces would cause the items to
# split into separate subitems.
#
#
# First argument  First list
#
# Second argument  Second list
function list_intersection()
{
    print_debug_enter "${@}"

    # Split list at all ',' to create an array of the individual items.
    #
    # shellcheck disable=SC2206
    declare -a firstList=(${1//,/ })

    # Split list at all ',' to create an array of the individual items
    #
    # shellcheck disable=SC2206
    declare -a secondList=(${2//,/ })


    # Algorithm used is
    #
    # 1. Use an associative array $seen to mark elements found in $firstList.
    #
    # 2. Iterate through $secondList and only add those elements that
    #    are also found in the associative array $seen to the array
    #    $intersection
    #
    # 3. Intersection between $firstList and $secondList is found in
    #    $intersection

    local result=""

    if (( ${#firstList[@]} > 0 )); then
        declare -A seen=()
        local item=""
        for item in "${firstList[@]}"; do
            seen["${item}"]=1
        done

        if (( ${#secondList[@]} > 0 )); then
            declare -a intersection=()
            for item in "${secondList[@]:-}"; do
                if [[ -n "${seen[${item}]:-}" ]]; then
                    intersection+=( "${item}" )
                fi
            done

            result="${intersection[*]:-}"
        fi
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function ensure_option_not_set()
{
    if [[ -n "${2}" ]]; then
        local message="Multiple ${BOLD}'${1}'${CLEAR} options not allowed!"
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


function ensure_option_argument_set()
{
    if [[ -z "${2}" ]]; then
        local message="${BOLD}'${1}'${CLEAR} option argument must not be an "
        message+="empty string."
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


# Check if given value is a member of given enum list.
#
# First parameter is value to check
#
# Second parameter is exit code to use if check fails
#
# Rest is list of enum values to check against.
#
# If check fails function abort with an error message.
function ensure_value_in_enum()
{
    # Save value we want to check if it is a member of the given enum
    local value="${1}"

    declare -i exitCode="${2}"

    # Shift argument list so it only contain enum entries
    shift 2

    # Iterate over given enum and see if can find a match with $value
    for item in "$@"; do
        if [[ "${item}" == "${value}" ]]; then
            # Found a match
            return
        fi
    done

    # No match found if we reach this point
    local enum="${*}"
    message="'${value}' does not match any of {${enum// /, }}, aborting."
    # shellcheck disable=SC2086
    print_error "${message}" $exitCode
}


function ensure_mode_set()
{
    declare -a target_mode_list=()
    declare -a option_list=()

    local current_mode_name="${1}"
    local current_mode="${!1}"  # Indirect parameter expansion

    # Move to next option
    shift

    local option=""

    # Loop over argument list in installments of two arguments at a
    # time and store values in separate arrays
    while (( $# > 0 )); do
        target_mode_list+=("${1}")
        # Move to next argument
        shift

        option_list+=("${1}")
        # Move to next argument
        shift
    done

    declare -i list_length=${#target_mode_list[@]}
    if (( list_length == 0 )); then
        local message="${BOLD}Internal error!${CLEAR} No target mode defined."
        print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
    fi

    if [[ -z "${current_mode}" ]]; then
        # Current mode unset; set it indirectly with first item in
        # $target_mode_list using declare and we are done
        declare -g "${current_mode_name}"="${target_mode_list[0]}"
        return;
    else
        local key
        # Iterate over the keys in $target_mode_list and check if we
        # can find a match for $current_mode
        for key in "${!target_mode_list[@]}"; do
            if [[ "${current_mode}" == "${target_mode_list[${key}]}" ]]; then
                # We have a match!
                return
            fi
        done
    fi

    # If we reach this point we were unable to find $current_mode
    # among the items in the $target_mode_list array
    if (( list_length == 1 )); then
        local message="${BOLD}'${option}'${CLEAR} option may only be used in "
        message+="${BOLD}${target_mode_list[0]}${CLEAR} mode."
        print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    else
        local message="${BOLD}'${option}'${CLEAR} option may only be used in "
        message+="one of ${BOLD}"

        declare -i last_index=$(( list_length - 1 ))
        for key in "${!target_mode_list[@]}"; do
            message+="${target_mode_list[key]}"
            if (( key < last_index )); then
                message+=", "
            fi
        done


        print_error "${message}${CLEAR} modes." $_FRIJA_EXIT_CMD_LINE_PROBLEMS
    fi
}


function ensure_boolean_option_not_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" != "n" ]]; then
            local message="Multiple ${BOLD}'${1}'${CLEAR} options not allowed!"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi
    fi
}


function ensure_boolean_option_set()
{
    if [[ -n "${2}" ]]; then
        if [[ "${2}" == "n" ]]; then
            local message="${BOLD}'${1}'${CLEAR} option must be selected!"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi
    fi
}


function current_date_and_time()
{
    print_debug_enter

    # Separator between date and time of day; default is to use '_'
    # (underscore) as the separator
    local separator="${1:-_}"

    # This is the "now" used for the time and date calculations
    local secondsSinceEpoch=""
    secondsSinceEpoch=$(date "+%s")

    # Finally create a timestamp
    # --utc  : Use UTC
    # --date : Use given value for calculations
    #     %g : 4-digit year
    #     %m : Month of year (01..12)
    #     %d : Day of month (01..28/30/31)
    #     %H : Hour (00..24)
    #     %M : Minute (00..59)
    #     %S : Second (00..59)
    #
    # The format used for the time-of-day follows "military time" as
    # used for instance within US and allied English-speaking military
    # forces
    #
    # - No separator between hours and minutes and 24-hour clock with
    #   leading zero
    #
    # - NATO phonetic alphabet is used for time zone indication; UTC
    #   is 'Zulu' or just 'Z'
    timestamp=""
    timestamp=$(date "--utc" \
                     "--date=@${secondsSinceEpoch}" \
                     "+%G-%m-%d${separator}%H%M.%SZ")

    # Delta between UTC and local time zone with sign, for instance
    # CET is +0100 and CEST is +0200
    local tzDelta=""
    tzDelta=$(date "--date=@${secondsSinceEpoch}" "+%z")

    # Create final timestamp
    timestamp="${timestamp}${tzDelta}"

    print_debug_exit "${timestamp}"
    echo "${timestamp}"
}


function get_branch_name()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local currentBranch=""

    # -C : Switch to $repopath before 'git rev-parse' is executed
    currentBranch=$(git -C "${repopath}" rev-parse --abbrev-ref HEAD)

    # Extract branch prefix and minimal part of label. That is, if it is
    # the main issue branch it has a format similar to
    #
    # feature/ABCD-0123_issue_title
    #
    # And if it is a sub-branch it has a format similar to
    #
    # ABCD-0123/some_label_assigned_by_developer
    #
    # The idea here is to in the former case transform the branch name to
    # something similar to "feature+ABCD-0123" and "ABCD-0123+some_label"
    declare -r ISSUE_TAG="[A-Z]+-[0-9]+"
    declare -r LABEL="[^/]+"
    declare -r PREFIX="${LABEL}"
    declare -r BRANCH_PATTERN="^(${PREFIX})/(${ISSUE_TAG}).*$"
    declare -r SUB_BRANCH_PATTERN="^(${ISSUE_TAG})/(${LABEL}).*$"

    local prefix
    local label
    if [[ "${currentBranch}" =~ ${BRANCH_PATTERN} ]]; then
        prefix="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        currentBranch="${label}"
    elif [[ "${currentBranch}" =~ ${SUB_BRANCH_PATTERN} ]]; then
        prefix="${BASH_REMATCH[1]}"
        label="${BASH_REMATCH[2]}"
        currentBranch="${prefix}_${label}"
    fi

    print_debug_exit "${currentBranch}"
    echo "${currentBranch}"
}


# Note: Command line parsing below relies on GNU getopt which is a
# separate binary that canonicalizes the command line so it can be
# more easily parsed and should not be confused with the Bash builtin
# getopts which does not support long options and so on.

# Ensure that we actually use GNU getopt
# - Allow command to fail with !'s side effect on errexit
# - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
! getopt --test
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    message="Aborting, GNU getopt not in search path."
    print_error "${message}" $_FRIJA_EXIT_GETOPT_NOT_FOUND
fi


# During TAB-completion the variable $_FENSALIR_CMD_NAME will be set
# to the command name on the command line. On the other hand, when a
# script is executed then it it won't be set to anything. To handle
# this case we re-assign $_FENSALIR_CMD_NAME. In case
# $_FENSALIR_CMD_NAME is empty then the value assigned is
# $_FRIJA_PROGRAM_NAME with everything after (and including) the first
# '-' removed.
#
# That is, if $_FENSALIR_CMD_NAME is empty and $_FRIJA_PROGRAM_NAME is
# "frija-fnord" then ${_FRIJA_PROGRAM_NAME%%-*} expands to just
# "frija".
_FENSALIR_CMD_NAME="${_FENSALIR_CMD_NAME:-${_FRIJA_PROGRAM_NAME%%-*}}"


# Ensure getopt is not working in compatible mode as this makes
# parsing of optional arguments virtually impossible.
unset -v GETOPT_COMPATIBLE

! _FRIJA_PARSED=$(getopt --options="${_FRIJA_SUBCOMMAND_OPTIONS}" \
                         --longoptions="${_FRIJA_SUBCOMMAND_LONGOPTS}" \
                         --name "${_FRIJA_USAGE_NAME}" \
                         -- "${@}")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # E.g. return value is 1 Then getopt has complained to stdout
    #  about wrong arguments. Note that we rely on that Bash scripts
    #  are interpreted and that the function name is evaluated before
    #  it is called.
    _"${_FENSALIR_CMD_NAME}"_subcommand_usage;
    exit $_FRIJA_EXIT_GETOPT_NOT_FOUND
fi

# To handle quoting correctly in output from getopt we have to do this
eval set -- "${_FRIJA_PARSED}"


function print_command_error()
{
    local message
    message="${BOLD}Illegal combination of options;${CLEAR} ${1} may not be "
    message+="combined with ${2}."
    print_error "${message}" "${3}"
}


function relative_path_to()
{
    local path="${1}"
    local name="${path##*/}"
    local relativeTo="${2:-${PWD}}"

    # Path to where Volla-folder is located
    local basePath="${_VOLLA_PATH%/*}"

    print_debug "path='${path}'"
    print_debug "name='${name}'"
    print_debug "relativeTo='${relativeTo}'"
    print_debug "basePath='${basePath}'"

    # Only get a relative path when given $path and $relativeTo both
    # are below $basePath, otherwise an absolute path is returned.
    # Also request that no symlinks are followed in order to eliminate
    # for instance "/p/pwa/fnord" being turned into
    # "/p/pwa-user/7/fnord".
    path=$(realpath --no-symlinks \
                    --relative-base="${basePath}" \
                    --relative-to="${relativeTo}" \
                    "${path}")

    print_debug "path='${path}'"

    if [[ "${path}" == "${name}" ]]; then
        # Path is name itself; we have to add "./"
        # in front of it
        path="./${path}"
    elif [[ ! ("${path}" == "../"* || "${path}" == "/"*) ]]; then
        # Path to  is neither a relative path nor an absolute
        # path; make it a relative path originating from $PWD
        path="./${path}"
    fi

    echo "${path}"
}


function print_command_failure_status()
{
    local status="${1}"
    local command="${2}"

    print_newline_only_after_dot
    print_message
    print_double_separator

    local message="${command}\\n"
    message+="failed with exit code ${status}"

    if [[ "${VERBOSE}" != "y" ]]; then
        message+=", please rerun with flag --verbose to get more information."
    fi

    _frija_fold "${message}" "0" "" "Command error:"
    _frija_print_stack_trace "${status}"
}


function conditional_separator_print_before()
{
    print_debug_enter "${@}"

    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # Whether entire message should be bolded or not; DEFAULT bolded
    local isBold="${2:-${BOLD}}"

    if [[ "${method}" == "${SINGLE}" ]]; then
        if [[ -n "${field}" ]]; then
            print_message "${BOLD}${field}${CLEAR}" 2
        fi
    elif [[ "${method}" == "${FIRST}" ]]; then
        if [[ -n "${field}" ]]; then
            if [[ "${isBold}" == "${BOLD}" ]]; then
                print_separator "${BOLD}${field}${CLEAR}"
            else
                print_separator "${field}"
            fi
        fi
    elif [[ "${method}" != "${LAST}" ]]; then
        if [[ -n "${field}" ]]; then
            if [[ "${isBold}" == "${BOLD}" ]]; then
                print_message "${BOLD}${field}${CLEAR}"
            else
                print_message "${field}"
            fi
        fi
    fi

    print_debug_exit
}


function conditional_separator_print_after()
{
    print_debug_enter "${@}"

    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    if [[ "${method}" == "${SINGLE}" ]] || [[ "${method}" == "${LAST}" ]]; then
        if [[ -n "${field}" ]]; then
            print_separator "${BOLD}Done${CLEAR} ${field}"
            print_message
        fi
    fi

    print_debug_exit
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


# As run function below but appends instead of redirects stdout to
# given destination in $3
function run_with_append()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # If and where to redirect stdout from command
    local destination="${3}"

    # Skip first three arguments
    shift 3

    # Store rest of args in command array
    declare -a command
    local command=("${@}")


    if [[ "${VERBOSE}" == "y" ]]; then
        conditional_separator_print_before "${method}" "${field}"
        echo "${command[*]} >> ${destination}"
        STATUS=("${PIPESTATUS[@]}")

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >> "${destination}"

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >> ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                # Need to get a new-line after the prefix
                print_prefix "${field}"
                echo ""
            fi
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >> "${destination}" 2> /dev/null
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


# As run function below but also redirects stdout to given destination in $3
function run_with_redirect()
{
    # method is one of SINGLE, FIRST, LAST, or NONE
    local method="${1}"

    # Value to use within separator
    local field="${2}"

    # If and where to redirect stdout from command
    local destination="${3}"

    # Skip first three arguments
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
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        if [[ "${DRY_RUN=}" == "y" ]] && [[ "${method}" != "${NONE}" ]]; then
            conditional_separator_print_before "${method}" "${field}"
            echo "${command[*]}  >| ${destination}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ -n "${field}" ]]; then
                # Need to get a new-line after the prefix
                print_prefix "${field}"
                echo ""
            fi
        fi

        if [[ "${DRY_RUN=}" != "y" ]]; then
            ! "${command[@]}" >| "${destination}" 2> /dev/null
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

    print_debug "Command: ${*}"
    print_debug "VERBOSE='${VERBOSE}'"
    if [[ "${VERBOSE}" == "y" ]]; then
        print_debug "method='${method}'  field='${field}'"
        conditional_separator_print_before "${method}" "${field}"

        # Execute given command, unless dry-run mode
        if [[ "${DRY_RUN=}" == "y" ]]; then
            print_message "${command[*]}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ "${WORDY}" == "y" ]]; then
                print_message "${BOLD}Calling${CLEAR} ${command[*]}" 2
            fi

            # Redirect ALL command output to stderr
            ! "${command[@]}" 1>&2

            # Save PIPESTATUS so we do not destroy it when for instance
            # echo something
            STATUS=("${PIPESTATUS[@]}")
            if [[ "${STATUS[0]}" -ne 0 ]]; then
                print_command_failure_status "${STATUS[0]}" "${command[*]}"
            fi
        fi

        if [[ "${STATUS[0]}" -eq 0 ]]; then
            conditional_separator_print_after "${method}" "${field}"
        fi
    else
        print_debug "method='${method}'  field='${field}'"
        conditional_separator_print_before "${method}" "${field}"

        if [[ "${DRY_RUN=}" == "y" ]]; then
            print_message "${command[*]}"
            STATUS=("${PIPESTATUS[@]}")
        else
            if [[ "${WORDY}" == "y" ]]; then
                print_message "${BOLD}Calling${CLEAR} ${command[*]}" 2
            fi

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


# Run a process in an isolated environment. That is remove all
# environment variables (including PATH) before the script
# frija_isolate.bash is executed in a separate process. This script
# then rebuild the target environment based on the content in the
# referenced .seci files.
#
# First parameter: Method is one of SINGLE, FIRST, LAST, or NONE
#
# Second parameter: Value to use within separator
#
# Third parameter: Path to locale repo to read .seci-files from
#
# Fourth parameter: Version tag to select within repo or "floating"
#                   for whatever is visible in the file system
#
# Fifth parameter: List of .seci-files to add to isolated environment
#
# Sixth parameter: List of variables with values to add to
#                  environment; NAME,NAME,... The function will
#                  automatically use NAME as the name of a Bash
#                  variable and the value of this varible when
#                  exporting to the environment. That is if you give
#                  the value "FOO,BAR" then the environment variable
#                  "FOO" will be exported with the value "${FOO}" and
#                  environment variable "BAR" with value "${BAR}".
function run_isolated()
{
    local method="${1}"
    local field="${2}"
    local localePath="${3}"
    local version="${4}"
    local seciList="${5}"
    local variableList="${6}"

    # Skip first six arguments up to but not including the command to
    # run
    shift 6

    # Any environment variables to explicitly set in the cleared
    # environment are listed in this variable, for instance DEBUG for
    # debug printouts and USERNAME in Windows.
    declare -a extraVariables=("")

    # Iterate over list of extra environment variables to explicitly
    # set in the isolated environment. This loop builds an argument
    # list for 'env' command that support the format
    # "<variable-name>=<value>" format. See manual page for env
    # command for further information.
    for variable in ${variableList//,/ }; do
        # Use indirect evaluation using ${!...} notation, that is take
        # the value of the variable and evaluate that value to get the
        # result.
        extraVariables+=("${variable}=${!variable}")
        print_debug "${variable}='${!variable}'"
    done

    if [[ "${DEBUG}" == "y" ]]; then
        # Force debug printouts in frija_isolate.bash script
        extraVariables+=("DEBUG=t")
    fi
    print_debug "DEBUG='${DEBUG}'"

    if [[ "${_FENSALIR_CURRENT_OS}" == "${_FENSALIR_WINDOWS}" ]]; then
        extraVariables+=("USERNAME=${USERNAME}")
        print_debug "USERNAME='${USERNAME}'"
    fi

    print_debug_array "extraVariables"

    if [[ -n "${seciList}" ]]; then
        # Transform $seciList by appending ${_FENSALIR_CURRENT_OS} to each
        # element in the list as the content of the SECI file need to
        # be adapted by selected OS. First fix the first element in
        # the list...
        seciList="${_FENSALIR_CURRENT_OS,,}-${seciList}"

        # ...and then fix the rest of the elements if there are any.
        seciList="${seciList//,/,${_FENSALIR_CURRENT_OS,,}-}"
    fi

    # Parse list of given .seci-files and the result is stored in the
    # global associative array $COMMON_SECI_VARIABLES[] as a side
    # effect.
    parse_seci_files "${localePath}" "${version}" "${seciList}"

    # Add additional environment variables to the $extraVariables[]
    # array so they get added to the isolated environment
    local item=""
    for item in "${!COMMON_SECI_VARIABLES[@]}"; do
        extraVariables+=("__FRIJA_${item}=${COMMON_SECI_VARIABLES[${item}]}")
    done

    print_message "${BOLD}About to execute:${CLEAR} ${*}" 2

    # Use env command to create a clean environment (absolute bare
    # minimum set of environment variables), that is not even $PATH is
    # inherited. In this minimalistic environment the
    # frija_isolate.bash script is executed which in turn sets up a
    # new environment based on what is provied in the $seciList
    # variable. Once that is done the actual command is executed in
    # this prestine environment; this latter part (which command and
    # with which options) is hidden in the $@ expansion.
    #
    # Note: $BASH is set by Bash itself and "Expands to the full file
    # name used to invoke this instance of bash" according to the
    # manual page for Bash.
    #
    # Explicitly allow word splitting when expanding $extraVariables[]
    # since if there are no extra environment variables then the array
    # expansion should just be treated as white space instead of one
    # or more arguments containing white space.
    #
    # shellcheck disable=SC2068
    ! run "${method}" "${field}" \
      "env" "--ignore-environment" \
      ${extraVariables[@]} \
      "${BASH}" "--norc" "--noprofile" \
      "${_FENSALIR_HOME}/frija_isolate.bash" "${WORDY:-}" "${@}"
    STATUS=("${PIPESTATUS[@]}")

    if [[ "${STATUS[0]}" -ne 0 ]]; then
        print_command_failure_status "${STATUS[0]}" "${command[*]}"
    fi

    return "${STATUS[0]}"
}


REPO_SEPARATOR="__"


# Depending on build tool used the actual build folder that is used
# when resolving dependencies between repos might differ. For
# instance, CMake requires that the build result is "installed" before
# inter-repo dependencies can be resolved as the file structure differ
# between what is in the build folder and the "install" folder.
#
# First parameter is the tool name to use when deducing build folder
#
# Result is name of build folder to use when resolving inter-repo
# dependencies.
function deduce_builddir()
{
    print_debug_enter "${@}"

    local tool="${1}"

    local result=""
    case "${tool}" in
        cmake)
            result="${BUILD_RESULT_DIR}"
            ;;
        msbuild)
            result="${BUILD_DIR}"
            ;;
        *)
            message="Unsupported build tool '${tool}' for '${repopath}', "
            message+="aborting."
            print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
    esac

    print_debug_exit "${result}"
    echo "${result}"
}


# Create filename prefix for build metadata files. This prefix is then
# combined with for instance $BUILD_DATE_FILE_SUFFIX to form the
# actual name of the build metadata file.
function make_build_metadata_prefix()
{
    print_debug_enter "${@}"

    local composite="${1}"
    local version="${2}"
    local name="${3}"

    local result="${composite}_${version}_${name}"

    print_debug_exit "${result}"
    echo "${result}"
}


# Check if current repo has changed enough since last build to warrant
# that build metadata files are recreated (repo metadata and git log
# files).
#
# First parameter is SHA value to compare with
#
# Second parameter is Version tag to compare with
#
# Third parameter is Dirty state to compare with
#
# Fourth parameter is Branch name to compare with
#
# If there are no changes return value is 0, otherwise
#
# 1: SHA differ
# 2: Dirty state differ
# 3: Version tag differ
# 4: Branch name differ
function is_build_metadata_dirty()
{
    print_debug_enter "${@}"

    local buildFolder="${1}"
    local metafilePrefix="${2}"
    local metafileSuffix="${3}"

    declare -i result=1

    local metadataFile="${buildFolder}"
    metadataFile+="/${metafilePrefix}${metafileSuffix}"

    local metadataSha=""
    local metadataDirtyState=""
    local metadataTag=""
    # Note: $metadataDelta is explicitly never used in this function.
    local metadataDelta=""
    local metadataBranch=""
    local metadataOS=""
    local metadataVersion=""
    local metadataComposite=""
    local metadataReponame=""
    local metadataDependencies=""
    local metadataToolDependencies=""
    local metadataExtDependencies=""
    local metadataBuildType=""
    local rest=""

    if [[ -e "${metadataFile}" ]]; then
        # Read values to compare with when deciding whether metadata
        # is dirty or not. Note that it is not necessary to use the
        # $metadataDelta value we read since any change in it is
        # always seen in changes in SHA and/or tag.
        local rest=""
        while read -r \
                   metadataSha \
                   metadataDirtyState \
                   metadataTag \
                   metadataDelta \
                   metadataBranch \
                   metadataOS \
                   metadataVersion \
                   metadataComposite \
                   metadataReponame \
                   metadataDependencies \
                   metadataToolDependencies \
                   metadataExtDependencies \
                   metadataBuildType \
                   rest
        do
            metadataSha=${metadataSha//$'\r'}
            metadataDirtyState=${metadataDirtyState//$'\r'}
            metadataTag=${metadataTag//$'\r'}
            metadataDelta=${metadataDelta//$'\r'}
            metadataBranch=${metadataBranch//$'\r'}
            metadataOS=${metadataOS//$'\r'}
            metadataVersion=${metadataVersion//$'\r'}
            metadataComposite=${metadataComposite//$'\r'}
            metadataReponame=${metadataReponame//$'\r'}
            metadataDependencies=${metadataDependencies//$'\r'}
            metadataToolDependencies=${metadataToolDependencies//$'\r'}
            metadataExtDependencies=${metadataExtDependencies//$'\r'}
            metadataBuildType=${metadataBuildType//$'\r'}

            if [[ -z "${metadataSha}" ]]; then
                # Skip to next entry since it is an empty line
                continue
            fi

            if [[ "${metadataSha}" == "#"* ]]; then
                # Skip to next entry since it is a comment
                continue
            fi

            # We have read a line, time to get out of loop
            break
        done < "${metadataFile}"
    else
        # No existing file exist, thus no point in comparing anything
        result=0
    fi


    # Compare SHA values
    if (( result == 1 )); then
        local currentSha=""
        currentSha=$(get_short_sha "${repopath}")

        if [[ "${currentSha}" != "${metadataSha}" ]]; then
            result=0
        fi
    fi


    # Compare dirty states
    if (( result == 1 )); then
        local dirtyState="${CLEAN_REPO_STATE}"
        if git_is_repo_dirty "${repopath}"; then
            dirtyState="${DIRTY_REPO_STATE}"
        fi

        if [[ "${dirtyState}" != "${metadataDirtyState}" ]]; then
            result=0
        fi
    fi


    # Compare tags
    if (( result == 1 )); then
        # Find either first reachable version tag on current branch, or no
        # such commit is found first common commit between develop branch
        # and current branch
        local baseVersion=""
        baseVersion=$(latest_tag "${repopath}" HEAD)
        if [[ -z "${baseVersion}" ]]; then
            # Fallback is to identify first common commit between current
            # branch and develop branch as a short SHA
            baseVersion=$(git -C "${repopath}" merge-base HEAD develop)
            baseVersion="${baseVersion:0:${_FRIJA_SHORT_SHA_LENGTH}}"
        fi

        if [[ "${baseVersion}" != "${metadataTag}" ]]; then
            result=0
        fi
    fi


    # Compare branches
    if (( result == 1 )); then
        local currentBranch=""
        currentBranch=$(git_current_branch "${repopath}")
        currentBranch="${currentBranch:-${currentSha}}"

        if [[ "${currentBranch}" != "${metadataBranch}" ]]; then
            result=0
        fi
    fi

    # Compare OS (from .repos file)
    if (( result == 1 )); then
        if [[ "${os}" != "${metadataOS}" ]]; then
            result=0
        fi
    fi

    # Compare version (from .repos file)
    if (( result == 1 )); then
        if [[ "${version}" != "${metadataVersion}" ]]; then
            result=0
        fi
    fi

    # Compare composite (from .repos file)
    if (( result == 1 )); then
        if [[ "${composite}" != "${metadataComposite}" ]]; then
            result=0
        fi
    fi

    # Compare reponame (from .repos file)
    if (( result == 1 )); then
        if [[ "${reponame}" != "${metadataReponame}" ]]; then
            result=0
        fi
    fi

    # Compare dependencies (from .repos file)
    if (( result == 1 )); then
        local deps=""
        deps=$(transform_metadata_list "${BUILD_METADATA_FILE_SUFFIX}" \
                                       "${dependencies}")
        if [[ "${deps}" != "${metadataDependencies}" ]]; then
            result=0
        fi
    fi

    # Compare tool dependencies (from .repos file)
    if (( result == 1 )); then
        if [[ "${toolDependencies:-${NONE}}" != "${metadataToolDependencies}" ]]
        then
            result=0
        fi
    fi

    # Compare external dependencies (from .repos file)
    if (( result == 1 )); then
        local deps="${externalDeps:-${NONE}}"
        if [[ "${deps}" != "${metadataExtDependencies}" ]]; then
            result=0
        fi
    fi

    # Compare build type
    if (( result == 1 )); then
        if [[ "${buildType}" != "${metadataBuildType}" ]]; then
            result=0
        fi
    fi

    print_debug_exit "${result}"
    return ${result}
}


# This function copies build metadata files from each dependent repo
# in the given list to the referenced repo.
#
# First parameter is path to repo
#
# Second parameter is type of build (RELEASE vs. DEBUG)
#
# Third name of Build Dir to use when linking between repos, that is
# this differ between MSBuild/GNU Make and CMake
#
# Fourth parameter is comma-separated list of dependencies
function update_dependent_metadata_build_files()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local buildType="${2}"
    local buildDir="${3}"
    local buildDepList="${4}"    # List of build dependencies
    local buildToolList="${5}"   # List of build dependencies
    local metafilePrefix="${6}"  # Prefix used for current repo

    # Merge buildDepList and buildToolList into a single list. Note
    # that both or comma-separated lists and that if any of them are
    # empty the corresponding variables contain only $NONE. Thus there
    # are four cases to handle.
    local list=""
    if [[ "${buildDepList}" == "${NONE}" ]]; then
        if [[ "${buildToolList}" != "${NONE}" ]]; then
            list="${buildToolList}"
        fi
    else
        if [[ "${buildToolList}" == "${NONE}" ]]; then
            list="${buildDepList}"
        else
            list="${buildDepList},${buildToolList}"
        fi
    fi

    local buildFolder="${repopath}/${buildDir}/${buildType}"

    if [[ -n "${list}" ]]; then
        # Array containing temporary data; different sets of
        # glob-expanded files
        declare -a fileList=()

        # Associative array containing all copied metadata files. This
        # is later used when removing files that are no longer
        # supposed to be copied due to changes in input .repos file.
        #
        # Note that only the key is used and the reason an associative
        # array is used is because it ensures there are no duplicates
        # and it is also simple to remove elements from it based on
        # the key.
        declare -A dependencyList=()


        # Create shorter aliases to use
        local bdfs="${BUILD_DATE_FILE_SUFFIX}"
        local bmfs="${BUILD_METADATA_FILE_SUFFIX}"
        local btmfs="${BUILD_TOOL_METADATA_FILE_SUFFIX}"

        # Expand to build date file for repo and metadata file for repo
        fileList=("${buildFolder}/${metafilePrefix}"*)

        # Add above files to $dependencyList associative array to ensure
        # that they will not be purged below where we remove no longer
        # referenced files
        for element in "${fileList[@]#${buildFolder}/}"; do
            dependencyList+=(["${element}"]=10)
        done

        print_debug "Iterating over '${list//,/ }'"
        # For each dependency copy metadata files from it to current
        # build folder in case they are newer than what we already have
        local dep=""
        while read -d, -r dep; do
            # Strip any carriage returns from the read value
            dep=${dep//$'\r'}
            print_debug "Processing '${dep}'"

            local composite=""
            local version=""
            local reponame=""
            local rest=""
            IFS=';' read -r composite version reponame rest<<<"${dep}"
            dep=$(make_build_metadata_prefix "${composite}" \
                                             "${version}"\
                                             "${reponame}")

            local destination=""
            destination=$(make_destination "${composite}" \
                                           "${reponame}" \
                                           "${version}")
            destination+="/${buildDir}/${buildType}"


            local depBuildDate="${destination}/${dep}${bdfs}"
            local curBuildDate="${repopath}/${buildDir}"
            curBuildDate+="/${buildType}/${dep}${bdfs}"

            # Retrieve potential list of files to copy
            fileList=("${destination}/"*{"${bdfs}","${bmfs}","${btmfs}"})
            print_debug "${BOLD}Potential files to copy${CLEAR}"
            print_debug "${BOLD}from${CLEAR} ${destination}"
            print_debug "${BOLD}to${CLEAR} ${buildFolder}"
            print_debug_array fileList

            # Regardless of if they are copied or not we need to store
            # the file names in our dependencyList associative array
            # so to ensure they are preserved when purging no longer
            # referenced files later. This involves converting the
            # indexed array into an associative array and this is done
            # by looping over the indexed array and within the loop
            # append to the associative array.
            if (( ${#fileList[@]} > 0 )) ; then
                # Append potentially copied dependency build date file
                dependencyList+=(["${dep}${bdfs}"]=11)

                # Keep track of potentially copied files sans path to them
                # in a separate array
                for element in "${fileList[@]#${destination}/}"; do
                    print_debug "${BOLD}Adding '${element}' to array${CLEAR}"
                    dependencyList+=(["${element}"]=12)
                done
            fi

            # Check if there exist a dependency build date file at
            # all. If so, then we check if that dependency build date
            # file is newer than the corresponding build date file for
            # the current repo. If so then the build date file
            # together with build and build tool metadata files are
            # copied.
            print_debug "Checking if '${depBuildDate}' exists"
            if [[ -e "${depBuildDate}" ]]; then
                local message="Checking if '${curBuildDate}' does not exist "
                message+="or is too old and need to be replaced"
                print_debug "${message}"
                if [[ ! -e "${curBuildDate}" ]] \
                       || [[ "${depBuildDate}" -nt "${curBuildDate}" ]]
                then
                    print_debug "${BOLD}Files to Copy${CLEAR}"
                    print_debug_array "fileList"
                    if (( ${#fileList[@]} > 0 )) ; then
                        # shellcheck disable=SC2086
                        cp --preserve=timestamps \
                           "${fileList[@]}" \
                           "${buildFolder}"
                    fi
                else
                    print_debug "${BOLD}Nothing to do for ${destination}!${CLEAR}"
                fi
            fi
        done <<<"${list}," # Add ',' to cover single-item case

        print_debug "${BOLD}Expected files${CLEAR}"
        print_debug_array "dependencyList"

        # Now that files have potentially been copied all metadata
        # files no longer in use should be removed. Those in use are
        # found in the associative array $dependencyList. Find all
        # build metadata files in the repo folder and store them in an
        # array. Iterate over this array and remove the files found in
        # the $dependencyList and what the remainder is should be
        # removed.
        fileList=("${buildFolder}/"*"${bdfs}" \
                  "${buildFolder}/"*{"${bmfs}","${btmfs}"})

        print_debug "${BOLD}Found files${CLEAR}"
        print_debug_array "fileList"

        if (( ${#fileList[@]} > 0 )) ; then
            # Iterate over potentially copied files and remove them
            # one by one from the total set of files found in
            # $buildFolder. Any remaining files are surplus and can be
            # safely removed. Note that it is not an error if there is
            # no match when removing an element.
            for element in "${!dependencyList[@]}"; do
                element="${buildFolder}/${element}"
                print_debug "${BOLD}purging '${element}' from array${CLEAR}"
                # Replace all elements in $fileList[@] matching
                # $element and replace them with empty strings
                fileList=( "${fileList[@]/${element}/}" )
            done

            print_debug "${BOLD}Reminder${CLEAR}"
            print_debug_array "fileList"

            # Delete remaining paths; note that removed paths are now
            # empty strings
            for element in "${fileList[@]}"; do
                if [[ -n "${element}" ]]; then
                    print_debug "${BOLD}deleting '${element}'${CLEAR}"
                    rm -f "${buildFolder}/${element}"
                fi
            done
        fi
    fi

    print_debug_exit ""
}


# Transform dependency list containing composite, version, and
# reponame triplets separated by ';' and then within each such triplet
# the items are separated by ','.
#
# Return string where all triplets are transformed to build metadata
# filenames separated by ','.
function transform_metadata_list()
{
    print_debug_enter "${@}"

    local metadataSuffix="${1}"
    local list="${2}"

    local result=""

    # Note that variation point repo names are not transformed to hide
    # their true identity.
    if [[ -z "${list}" ]] || [[ "${list}" == "${NONE}" ]]; then
        result+="${NONE}"
    else
        local dep=""
        while read -d, -r dep; do
            # Strip any carriage returns from the read value
            dep=${dep//$'\r'}

            local composite=""
            local version=""
            local reponame=""
            local rest=""
            IFS=';' read -r composite version reponame rest<<<"${dep}"
            dep=$(make_build_metadata_prefix "${composite}" \
                                             "${version}" \
                                             "${reponame}")
            dep="${dep}${metadataSuffix}"

            # Append $dep to $result using ',' as separator. This means
            # that the last entry in the list will end with ','.
            result+="${dep},"
        done <<<"${list}," # Add ',' to cover single-item case

        # Remove last ',' from result
        result="${result%,}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function generate_build_info_metadata()
{
    local buildDate="${1:-${NONE}}"

    local result=""
    result+="${buildDate}"
    result+="########################################"
    result+="########################################\\n"
    result+="## Build Info\\n"
    result+="########################################"
    result+="########################################\\n"
    # Find out maximum field width for metadata fields
    declare -i maxWidth=0
    local element=""
    for element in "${!_FRIJA_REPOS_METAFIELDS[@]}"; do
        declare -i width="${#element}"
        if (( width > maxWidth )); then
            maxWidth="${width}"
        fi
    done

    # Construct metadata field header
    for element in "${_FRIJA_REPOS_KEY_VALUES[@]}"; do
        local key="${element% *}"
        local value="${element#*: }"
        local field=""
        printf -v field "%${maxWidth}s" "${key}"

        # Note: Indirect reference to variable using '!' where the
        # name of the variable is stored in $value
        result+="# ${field} ${!value:-}\\n"
    done

    result+="########################################"
    result+="########################################\\n"

    echo "${result}"
}


# Generate build metadata files (repo metadata and git log file). The
# repo metadata file contain
#
# - All metadata fields from .repos file used when building
# - Version specified in .repos file for repo
# - Closest reachable version tag with highest version number or short SHA
# - Current branch if any; if headless state then short SHA
# - Dirty/clean state
# - Number of commits to either version tag or develop branch
#
# The git log file contain up to 20 latest reachable commit subject
# lines together with committer and author.
function generate_build_metadata()
{
    print_debug_enter "${@}"

    local repopath="${1}"

    local os="${2}"
    local version="${3}"
    local composite="${4}"
    local reponame="${5}"
    local dependencies="${6}"
    local toolDependencies="${7}"
    local externalDeps="${8}"
    local buildType="${9}"
    local buildDate="${10:-}"

    local result=""
    result+="#%FBEMF 1.0.0 (Frija Build Metadata Exchange Format)\\n"

    result+=$(generate_build_info_metadata "${buildDate}")

    result+="\\n"
    result+="########################################"
    result+="########################################\\n"
    result+="## Documentation for rest of file\\n"
    result+="## ------------------------------\\n"
    result+="## Each row contain the following set of fields in this order\\n"
    result+="## - Current SHA\\n"
    result+="## - Dirty state "
    result+="('${CLEAN_REPO_STATE}' or '${DIRTY_REPO_STATE}')\\n"
    result+="## - Base version (Git tag or first common commit with develop)\\n"
    result+="## - Number of commits between current commit and base\\n"
    result+="## - Current branch or SHA if no branch\\n"
    result+="## - OS from input file\\n"
    result+="## - Version from input file\\n"
    result+="## - Composite from input file\\n"
    result+="## - Repo name from input file\\n"
    result+="## - Dependencies ('${NONE}' or list of metadata filenames)\\n"
    result+="## - Tool dependencies "
    result+="('${NONE}' or list of metadata filenames)\\n"
    result+="## - External dependencies; '${NONE}' or 4-tuple\\n"
    result+="##   \"repo\";\"version\";\"buildconf-list\";\"seci-list\"\\n"
    result+="##   Note: Lists contain files found in repo of given version.\\n"
    result+="##         Empty lists are represented as empty strings.\\n"
    result+="## - Build type "
    result+="('${_FRIJA_BUILD_RELEASE}' or '${_FRIJA_BUILD_DEBUG}')\\n"
    result+="##\\n"
    result+="## Note: All tuples are semicolon-separated sequences.\\n"
    result+="## Note: All lists are comma-separated sequences.\\n"
    result+="########################################"
    result+="########################################\\n"

    ##############################
    # Generate build metadata line
    #
    local currentSha=""
    currentSha=$(get_short_sha "${repopath}")

    # Find either first reachable version tag on current branch, or no
    # such commit is found first common commit between develop branch
    # and current branch
    local baseVersion=""
    baseVersion=$(latest_tag "${repopath}" HEAD)
    if [[ -z "${baseVersion}" ]]; then
        # Fallback is to identify first common commit between current
        # branch and develop branch as a short SHA
        baseVersion=$(git -C "${repopath}" merge-base HEAD develop)
        baseVersion="${baseVersion:0:${_FRIJA_SHORT_SHA_LENGTH}}"
    fi

    declare -i delta=0
    delta=$(git_delta_commits "${repopath}" "${baseVersion}")

    local dirtyState="${CLEAN_REPO_STATE}"
    if git_is_repo_dirty "${repopath}"; then
        dirtyState="${DIRTY_REPO_STATE}"
    fi

    local currentBranch=""
    currentBranch=$(git_current_branch "${repopath}")

    result+="${currentSha} ${dirtyState} ${baseVersion} ${delta} "
    result+="${currentBranch:-${currentSha}} "
    result+="${os} ${version} ${composite} ${reponame}"

    # Note that variation point repo names are not transformed to hide
    # their true identity.
    result+=" "
    result+=$(transform_metadata_list "${BUILD_METADATA_FILE_SUFFIX}" \
                                      "${dependencies}")
    result+=" "
    result+=$(transform_metadata_list "${BUILD_TOOL_METADATA_FILE_SUFFIX}" \
                                      "${dependencies}")

    result+=" ${externalDeps:-${NONE}}"
    result+=" ${buildType:-${NONE}}"

    print_debug_exit "${result}"
    echo "${result}"
}


# Creates a path from given composite-name, repo-name and optional version.
# The separator used between repo-name and optional version is defined
# by $REPO_SEPARATOR.
#
# NOTE: Name is assumed to be a non-empty string. However composite is
# allowed to be an empty string even though it is a mandatory
# parameter.
function make_destination()
{
    print_debug_enter "${@}"

    local composite="${1}"
    local name="${2}"
    local version="${3:-}"
    local result=""

    if [[ "${version}" == "${NON_VERSION}" ]]; then
        version=""
    fi

    if [[ -n "${composite}" ]]; then
        if [[ -n "${version}" ]]; then
            result="${composite}/${name}${REPO_SEPARATOR}${version}"
        else
            result="${composite}/${name}"
        fi
    elif [[ -n "${version}" ]]; then
        result="${name}${REPO_SEPARATOR}${version}"
    else
        result="${name}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# A variation point means that there are several different
# implementations of a repo that adhere to the same interface. As the
# build script for a repo may not refer to a specific such repo the
# variation point repo name must be transformed to become more
# generic.
#
# This function removes the variation point ID (including the '_'
# separator) from given string. It is assumed that the variation point
# ID is the last part of the name and that it is preceded by a _' and
# does not in itself contain any '_' characters. It is assumed that
# the resulting string is still a unique value within a
# system/sub-system.
#
# For instance if given value is "FOO-BAR_GAZONK_42" then this
# function will return "FOO-BAR_GAZONK".
#
# It is an error to try to transform a string that does not end with
# a variation point ID.
#
# First parameter is the string value to transform.
#
# Return value is transformed string.
function transformVariationPoint()
{
    print_debug_enter "${@}"

    local name="${1}"

    local result=""

    # Create regex that catches the part of the name that precedes the
    # last '_' in the name. What follows the last '_' is the variation
    # point ID and should be removed for all variation points. It is
    # also assumed that the name without this ID is still unique
    # within a system/sub-system.
    local regex="^(.+)_([^_]+)$"
    if [[ "${name}" =~ ${regex} ]]; then
        print_debug "Field #1='${BASH_REMATCH[1]}'"
        print_debug "Field #2='${BASH_REMATCH[2]}'"

        result="${BASH_REMATCH[1]}"
    else
        local message="Not possible to remove variation point ID from "
        message+="'${name}'. A variation point ID is the last part of a repo "
        message+="name that starts with '_' and is not followed any more '_' "
        message+="characters. For instance 'FOO-BAR_GAZONK_42' has variation "
        message+="point ID '_42'. Aborting due to this."
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function make_replication_message()
{
    print_debug_enter "${@}"

    local prefix="${1}"
    local name="${2}"
    local version="${3}"
    local destination="${4}"
    local preposition="${5:-to}"

    local result="${BOLD}${prefix}${CLEAR} ${name}"

    if [[ "${name}" != "${destination}" ]]; then
        if [[ -n "${version}" ]]; then
            result+=" ${version} ${preposition} ${BOLD}${destination}${CLEAR}"
        else
            result+=" ${preposition} ${BOLD}${destination}${CLEAR}"
        fi
    fi
    result+="..."

    print_debug_exit "${result}"
    echo "${result}"
}


# Include tag handling functions.
# shellcheck source=./.tag_handling.bash
source "${_FENSALIR_HOME}/.tag_handling.bash"


# Return VCS kind based on given path or URI. That is, if given
# parameter starts with '/' then it is assumed that it is a file
# system path pointing to a repo and different VCS systems are queried
# based on this path if they recognize the repo. The first VCS that
# claims it recognizes the repo is assumed to define the kund of repo.
#
# Otherwise, the given parameter is expected to be a URI and VCS kind
# is deduced from inspecting this URI.
#
# NOTE: Currently only Git is supported for path based VCS
# identification. For URI based identification only URIs starting with
# 'ssh:' and ends with '.git', i.e. standard Git URIs.
#
# First parameter is either a path or a URI to a repo.
#
# TODO: Duplicate of function in .vcs_functions.bash ?
function frija_deduce_vcs_type()
{
    print_debug_enter "${@}"

    local uri="${1}"
    local result=""

    print_debug "uri='${uri}'"

    if [[ "${uri}" == "/"* ]]; then
        # Do not abort script if non-zero exit code is returned
        # - Allow command to fail with !'s side effect on errexit
        # - Use return value from ${PIPESTATUS[0]}, because ! hosed $?
        print_debug "git -C '${uri}' rev-parse &>/dev/null"
        ! git -C "${uri}" rev-parse &>/dev/null
        declare -i exitCode=${PIPESTATUS[0]}
        if (( exitCode == 0 )); then
            result="${GIT_REPO}"
        else
            local message="Unknown VCS type for repo '${uri}' "
            message+="(exit code ${exitCode})"
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    else
        # Check if we have been given a URI
        local result=""

        if [[ "${uri}" =~ ^[a-zA-Z]+://.*/[^/]+[._]([a-zA-Z]+)$ ]]; then
            # Ensure result is always in lowercase due to ',,'
            # parameter expansion
            local result="${BASH_REMATCH[1],,}"
        fi

        if [[ -z "${result}" ]]; then
            local message="Unknown repo URI format: '${uri}'"
            print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi

        case "${result}" in
            git)
                result="${GIT_REPO}"
                ;;
            *)
                local message="Can't deduce VCS type from given URI: '${uri}'"
                print_error "${message}" $_FRIJA_EXIT_CMD_LINE_PROBLEMS
                ;;
        esac
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Either checks out a specific tag (and enter headless state) or
# feature-branch (based on Feature ID) or develop or master. That is,
# if Feature ID can't be found then fallback is develop or master in
# that priority order.
#
# First parameter is the "base" that is a relative path from
# $_FRIJA_WS_PATH to the repo
#
# Second parameter is a version number that can be validated, or
# $NON_VERSION, or an empty string.
#
# Third parameter is only used when second parameter (version) is an
# empty string. When that is the case it is used to construct feature
# branch name to checkout.
function checkout_branch()
{
    print_debug_enter "${@}"
    print_debug "PWD='${PWD}'"

    local base="${1}"
    local version="${2}"
    local featureID="${3:-${_FRIJA_FEATURE_ID}}"

    local result=""

    print_debug "base: '${base}'"
    print_debug "version: '${version}'"
    print_debug "featureID: '${featureID}'"

    local message=""

    if [[ -n "${version}" ]] && \
           [[ "${version}" != "${NON_VERSION}" ]]; then
        # In this mode a specific commit is implicitly pointed
        # to via a tag with the same name as the version.

        # First validate that tag exists and that it points to
        # the correct commit
        print_debug "Validating tag '${version}'"
        validate_tag "${version}"

        # Checkout specific version
        if [[ "${WORDY}" == "y" ]]; then
            message="${BOLD}Switching${CLEAR} repo ${base} to version "
            message+="${BOLD}${version}${CLEAR}"
        else
            print_dot
        fi

        command=("${SINGLE}" "${message}" \
                             git -C "${_FRIJA_WS_PATH}/${base}" \
                             checkout "${version}")
        run "${command[@]}"

        print_debug "Setting result='${version}'"
        result="${version}"
    elif [[ -n "${featureID}" ]]; then
        # No specific version is given, this mean that user should
        # work on a feature branch for the repo (or develop or master
        # branches should be used, but they are lumped together with
        # feature-branches here)
        local featureBranch;
        featureBranch=$(git_find_feature_branch "${base}" "${featureID}")

        if [[ -n "${featureBranch}" ]]; then
            # Switch to feature branch
            if [[ "${WORDY}" = "y" ]]; then
                message="${BOLD}Switching${CLEAR} to branch "
                message+="${BOLD}${featureBranch}${CLEAR} in repo ${name}"
            else
                print_dot
            fi

            command=("${SINGLE}" "${message}" \
                                 git -C "${_FRIJA_WS_PATH}/${base}" \
                                 checkout "${featureBranch}")
            run "${command[@]}"
        else
            message="Non-conformant repo found (${base}); "
            message+="no branch to switch to."
            print_warning "${message}"
        fi

        print_debug "Setting result='${featureID}'"
        result="${featureID}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function checkout_worktree()
{
    print_debug_enter "${@}"

    local base="${1}"
    local version="${2}"
    local name="${3}"

    if [[ -n "${version}" ]]; then
        # Repo should already have been cloned when we reach
        # this point. When version is non-empty this means
        # that a Git worktree should be created from the
        # cloned repo.
        worktree=$(make_destination "" "${name}" "${version}")

        print_debug "worktree='${worktree}'"
        local message=""
        local worktreePath="${_FRIJA_WS_PATH}/${base%/*}/${worktree}"
        print_debug "worktreePath='${worktreePath}'"
        if [[ -e "${worktreePath}" ]]; then
            # Worktree has already been created
            print_newline_after_dot
            message="Git Worktree ${BOLD}'${worktree}'${CLEAR} already exist..."
            print_message "${message}"
        else
            if [[ ! -e "${_FRIJA_WS_PATH}/${base}" ]]; then
                message="Git Worktree base repo '${base}' does not exist, "
                message+="aborting."

                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi

            local foundTag=""
            foundTag=$(git -C "${_FRIJA_WS_PATH}/${base}" \
                           tag --list "${version}")
            print_debug "foundTag='${foundTag}'"

            if [[ "${foundTag}" == "${version}" ]]; then
                # Tag named as $version does exist; create a worktree!
                print_debug "worktree does not exist!"
                message="${BOLD}Creating${CLEAR} a Git Worktree for "
                message+="repo ${base} @ tag ${BOLD}${version}${CLEAR}..."

                command=("${SINGLE}" "${message}" \
                                     git -C "${_FRIJA_WS_PATH}/${base}" \
                                     worktree add --detach \
                                     "../${worktree}" "${version}")
                run "${command[@]}"
            else
                message="No tag named '${BOLD}${version}${CLEAR}' found in "
                message+="repo '${BOLD}${base}${CLEAR}'.\\n\\n"
                message+="${BOLD}Please fix problem and try again, "
                message+="aborting.${CLEAR}"

                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
        fi
    fi

    print_debug_exit
}


# source: Type of service to use when replicating, e.g. git
# uri: From where to obtain the data
# composite: Name of composite used for grouping related repos [optional]
# version: Version identifier to use, e.g. "x.y.z" [optional]
#
# NOTE: Name of destination folder is derived from uri, composite, and
# version using the function make_destination().
function replicate_data()
{
    print_debug_enter "${@}"

    local source="${1}"
    local uri="${2}"
    # Make $3 optional by having default value be an empty string
    local composite="${3:-}"
    # Make $4 optional by having default value be an empty string
    local version="${4:-}"
    # Make $5 optional by having default value be $_FRIJA_FEATURE_ID
    local featureID="${5:-${_FRIJA_FEATURE_ID}}"

    local destination=""
    local base=""
    local message=""
    local name=""

    local selectedBranch=""

    # Make command to be a local variable and an array
    declare -a command

    case "${source}" in
        git)
            if [[ "$uri" =~ $GIT_REPO_PATTERN ]]; then
                name="${BASH_REMATCH[2]:-${BASH_REMATCH[1]}}"
            else
                message="Unsupported ${BOLD}Git repo URI path${CLEAR}: "
                message+="URI is '${uri}' and pattern is "
                message+="'${GIT_REPO_PATTERN}', aborting."
                print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            fi

            base=$(make_destination "${composite}" "${name}")
            print_debug "base='${base}'"
            print_debug "composite='${composite}'"
            print_debug "name='${name}'"

            if [[ -e "${_FRIJA_WS_PATH}/${base}" ]]; then
                if [[ "${VERBOSE}" == "y" ]]; then
                    print_newline_after_dot
                    message="Git repo ${BOLD}'${base}'${CLEAR} already exist..."
                    print_message "${message}" 2
                fi
            else
                print_newline_after_dot
                message="${BOLD}Cloning${CLEAR} repo ${name} "
                message+="as ${BOLD}${base}${CLEAR}"
                print_message "${message}'" 2

                if [[ "${WORDY}" == "y" ]]; then
                    print_debug "Creating wordy command line"
                    command=("${NONE}" "" \
                                       git -C "${_FRIJA_WS_PATH}" \
                                       clone --progress "$uri" "$base")
                else
                    command=("${NONE}" "" \
                                       git -C "${_FRIJA_WS_PATH}" \
                                       clone "$uri" "$base")
                fi

                run "${command[@]}"

                # Checkout branch; feature, develop, or master in that
                # order of precedence
                selectedBranch=$(checkout_branch "${base}" "${NON_VERSION}")
                print_debug "selectedBranch='${selectedBranch}'"

                if [[ -z "${selectedBranch}" ]]; then
                    message="Could not select any branch in repo '${base}', "
                    message+="aborting."
                    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
                fi

                print_debug "version='${version}'"
                if [[ -n "${version}" ]] && \
                       [[ "${version}" != "${NON_VERSION}" ]]; then
                    checkout_worktree "${base}" "${version}" "${name}"
                fi
            fi
            ;;
        *)
            local message="Unsupported SOURCE: '${source}' for '${uri}', "
            message+="aborting."

            print_error "${message}" $_FRIJA_EXIT_INPUT_FILE_FORMAT_PROBLEMS
            ;;
    esac
    print_debug_exit
}


function git_find_feature_branch()
{
    print_debug_enter "${@}"

    local base="${1}"
    local featureID="${2:-${_FRIJA_FEATURE_ID}}"

    local result=""
    local branches=""

    if [[ -n "${_FRIJA_WS_PATH}" ]]; then
        base="${_FRIJA_WS_PATH}/${base}"
    fi

    ## Get all remote branches
    branches=$(git -C "${base}" branch --remotes | grep -v HEAD)

    # Find feature branch matching current Feature ID (signified by
    # folder name containing .frija folder). If no such feature branch
    # exist select develop, and if no such branch exist fall back to
    # develop.
    while read -r remoteBranch; do
        # Strip "origin/" prefix from each remote branch
        remoteBranch="${remoteBranch#*/}"

        # Order is not important here. What is important to note here
        # is that if we find a feature branch that starts with
        # $_FRIJA_FEATURE_ID then we break out from the while loop
        # after saving the branch name in $result.
        #
        # If we find develop branch while searching, then set $result
        # to it. Just in case we don't find any feature branch. And
        # continue searching. We overwrite $result regardless of what
        # it contain (remember: if we had found a feature branch
        # before we reach this point we would have already broken out
        # from the while). And if it contained "master" then it does
        # not matter since "develop" trumps "master" in this case.
        #
        # And finally, only overwrite $result with "master" when it is
        # an empty string; that is if we have found develop before
        # master then $result will not be left as it is.
        if [[ "${remoteBranch}" == "feature/${featureID}"* ]]; then
            result="${remoteBranch}"
            break
        elif [[ "${remoteBranch}" == "develop" ]]; then
            result="${remoteBranch}"
        elif [[ "${remoteBranch}" == "master" ]] && [[ -z "${result}" ]]; then
            result="${remoteBranch}"
        fi
    done <<< "${branches}"

    print_debug_exit "${result}"
    echo "${result}"
}


function update_git_repo()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local force="${2:-}"

    local -a command=()
    local message=""
    local remote=""
    local messagePrefix="${BOLD}${repopath}${CLEAR}"

    remote=$(git_remote_url "${repopath}")
    if [[ -z "${remote}" ]]; then
        message="No remote configured, skipping."
    fi

    if [[ -z "${message}" ]]; then
        if git_is_repo_empty "${repopath}"; then
            message="Empty repo, skipping."
        fi
    fi

    if [[ -z "${message}" ]]; then
        if git_is_repo_dirty "${repopath}"; then
            message="Dirty repo, skipping."
        fi
    fi

    if [[ -n "${message}" ]]; then
        print_newline_after_dot
        print_message "${messagePrefix}" 2
        print_message "${message}" 3

        print_debug_exit
        return
    fi

    # Fetch repo so we do not work on stale information
    command=("${NONE}" "${message}" git -C "${repopath}" fetch)
    run "${command[@]}"

    # Get all local branches that tracks remote branches
    #
    # The AWK expression below matches only the lines containing the
    # string "merges with remote" and for those line fields #5 and #1
    # are printed to stdout.
    local branches
    branches=$(git -C "${repopath}" remote show origin -n | \
                   awk '/merges with remote/{print $5" "$1}')

    local initialBranch=""
    initialBranch=$(git_current_branch "${repopath}")

    declare -i MAX_SUBJECT_WIDTH=45
    declare -i subjectWidth=31
    declare -i nameWidth=16

    # Rebalance $subjectWidth if terminal width is greater than 80
    # characters
    if (( WIDTH > 80 )); then
        declare -i delta=WIDTH-80

        # Do not go beyond $MAX_SUBJECT_WIDTH characters for subject
        if (( delta > (MAX_SUBJECT_WIDTH - subjectWidth) )); then
            (( subjectWidth=MAX_SUBJECT_WIDTH ))
        else
            (( subjectWidth+=delta))
        fi
    fi

    # Format string to use when listing commit log messages
    local logShaFormat="%C(auto)%h "
    local logFormat="%<(${subjectWidth},mtrunc)%s%Creset "
    logFormat+="(%<(${nameWidth},trunc)%cn: %cd)"

    if [[ "${VERBOSE}" == "y" ]]; then
        print_newline_after_dot
        print_message "${messagePrefix}" 2
        messagePrefix=""
    fi

    while read -r remoteBranch localBranch; do
        local aRemoteBranch=""
        local aLocalBranch=""

        # $behindCount must be able to contain both integer values or
        # an empty string due to error handling, hence it must not be
        # declared as an integer variable.
        local behindCount=""
        declare -i aheadCount=0

        print_debug "verbose='${VERBOSE}', " \
                    "debug='${DEBUG}', " \
                    "force='${force}'" \
                    "remoteBranch='${remoteBranch}', " \
                    "localBranch='${localBranch}'"

        # Use explicit names for remote and local branches
        aRemoteBranch="refs/remotes/origin/${remoteBranch}"
        aLocalBranch="refs/heads/${localBranch}"

        # Get number of commits $aLocalBranch is behind $aRemoteBranch
        ! behindCount=$(git -C "${repopath}" rev-list \
                            --count "${aLocalBranch}..${aRemoteBranch}" \
                            2>/dev/null)

        # If above command return an empty string this means that the
        # command failed which implicitly means that one of the
        # branches is missing, but we do not know which of them. Lets
        # find out.
        if [[ -z "${behindCount}" ]]; then
            if [[ -n "${messagePrefix}" ]]; then
                print_newline_after_dot
                print_message "${messagePrefix}" 2
                messagePrefix=""
            fi

            message="Missing "

            local branchname=""
            ! branchname=$(git -C "${repopath}" rev-parse \
                               --verify \
                               --quiet \
                               --abbrev-ref "${aLocalBranch}");

            if [[ -z "${branchname}" ]]; then
                # Local branch does not exist.
                message+="local "
                branchname="${localBranch}"
            else
                message+="remote "
                branchname="${remoteBranch}"
            fi

            message+="branch for '${branchname}', skipping."
            print_newline_only_after_dot
            print_message "${message}" 3
            continue
        fi

        # Get number of commits $aLocalBranch is ahead of $aRemoteBranch
        aheadCount=$(git -C "${repopath}" rev-list \
                         --count "${aRemoteBranch}..${aLocalBranch}" \
                         2>/dev/null)
        print_debug "aheadCount='${aheadCount}', behindCount='${behindCount}'"

        if [[ "${behindCount}" -gt 0 ]]; then
            if [[ -n "${messagePrefix}" ]]; then
                print_newline_after_dot
                print_message "${messagePrefix}" 2
                messagePrefix=""
            fi

            if [[ "${aheadCount}" -gt 0 ]]; then
                message="Branch ${localBranch} is ${behindCount} commit(s) "
                message+="behind and ${aheadCount} commit(s) ahead of "
                message+="origin/${remoteBranch}."
                print_message "${message}" 3
                print_message "${BOLD}Cannot be fast-forwarded!${CLEAR}" 3

                print_debug "force='${force}'"

                local overwriteMessage=""
                if [[ "${force}" == "y" ]]; then
                    message="${BOLD}Forcing overwrite of local commits "
                    message+="as requested${CLEAR}"
                    print_message "${message}" 3

                    overwriteMessage="Commits to be overwritten"
                else
                    overwriteMessage="Commits overwritten ${BOLD}"
                    overwriteMessage+="${UNDERLINE_ON}IF${UNDERLINE_OFF}"
                    overwriteMessage+="${CLEAR} repo is updated by Frija"
                fi

                print_double_separator
                print_message "${overwriteMessage}" 3
                print_separator
                git -C "${repopath}" log \
                    --date=format:'%y%m%d %H:%M.%S%z' \
                    --pretty="${logShaFormat}%Cred${logFormat}" \
                    "@{upstream}..HEAD" 1>&2
                print_separator

                print_message "Replacement" 3
                print_separator
                git -C "${repopath}" log \
                    --date=format:'%y%m%d %H:%M.%S%z' \
                    --pretty="${logShaFormat}%Cblue${logFormat}" \
                    "HEAD..@{upstream}" 1>&2
                print_separator

                if [[ "${force}" == "y" ]]; then
                    local head=""
                    head=$(get_short_sha "${repopath}" "HEAD")

                    # Set a save-point in case something went wrong
                    command=("${NONE}" "" git -C "${repopath}" tag \
                                       --force frija)
                    run "${command[@]}"

                    message="Current commit (${head} '${localBranch}') saved "
                    message+="as tag ${BOLD}frija${CLEAR}"
                    print_message "${message}" 3

                    message="Forcing local branch '${localBranch}' to match "
                    message+="remote branch."
                    print_message "${message}" 3

                    command=("${NONE}" "" git -C "${repopath}" reset \
                                         "--hard" \
                                         "@{upstream}")
                    run "${command[@]}"

                    head=$(get_short_sha "${repopath}" "HEAD")
                    message="Local branch '${localBranch}' now at "
                    message+="${BOLD}${head}${CLEAR}."
                    print_message "${message}" 3
                    message="You can always get back to old branch HEAD for "
                    message+="branch '${localBranch}' in repo "
                    message+="${BOLD}${repopath}${CLEAR} "
                    message+="via tag ${BOLD}frija${CLEAR}."
                    print_note "${message}" "y"
                fi
            elif [[ "${localBranch}" == "${initialBranch}" ]]; then
                message="Branch ${localBranch} is ${behindCount} commit(s) "
                message+="behind of origin/${remoteBranch}."
                print_message "${message}" 2
                print_message "Trying a Fast-forward merge" 3

                command=("${NONE}" "${repopath}" \
                                   git -C "${repopath}" merge \
                                   --ff-only \
                                   --quiet \
                                   "${aRemoteBranch}")
                run "${command[@]}"
            else
                message+="Branch ${localBranch} is ${behindCount} commit(s) "
                message+="behind of origin/${remoteBranch}."
                print_message "${message}"
                print_message "Trying a Fast-forward merge using 'git fetch'" 3
                command=("${NONE}" "${repopath}" \
                                   git -C "${repopath}" fetch origin \
                                   "${remoteBranch}:${localBranch}")
                run "${command[@]}"
            fi
        fi
    done <<< "${branches}"

    if [[ -n "${initialBranch}" ]]; then
        local currentBranch=""
        currentBranch=$(git_current_branch "${repopath}")

        if [[ "${currentBranch}" != "${initialBranch}" ]]; then
            message="Switching back to branch '${initialBranch}' "
            message+="for repo '${repopath}'..."

            command=("${LAST}" "${message}" \
                               git -C "${repopath}" \
                               checkout "${initialBranch}")
            run "${command[@]}"
        fi
    fi

    print_debug_exit
}


################################################################################
################################################################################


# Test if _BOOTSTRAP_PATH is set to any value
if [[ -v _BOOTSTRAP_PATH ]]; then
    # When we are sourced from the bootstrap script, it is here we
    # should return back to it.
    return
fi


# Dummy implementation of a cleanup function called from the main
# cleanup function. A command may override this implementation to get
# some extra cleanup done at exit.
function _frija_cleanup_function()
{
    echo "" > /dev/null
}


function cleanup()
{
    if [[ -n "${_FRIJA_WS_PATH}" ]]; then
        if [[ -d "${_FRIJA_CONFIG_CACHE_PATH}" ]]; then
            # Remove all files in cache; ensure that
            # $_FRIJA_CONFIG_CACHE_PATH is non-empty using ${foo:?}
            # expansion that displays an error message if $foo is null
            # or unset.
            rm -fr "${_FRIJA_CONFIG_CACHE_PATH:?}/*"
        fi
    fi

    _frija_cleanup_function
}

# Install exit trap function that will be called when script exits
trap cleanup EXIT
