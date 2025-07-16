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
# Furthermore as a general rule all functions found within this file
# (and any file it sources) should be prefixed with "frija_" or
# similar as they will be exported to the interactive Bash shell. This
# is to minimize the risk for name conflicts.
################################################################################
#  NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
################################################################################
#
# File is sourced by frija and .core_preamble.bash scripts.


# Guard against this script being sourced multiple times.
#
# Note: -v tests if variable name is set or not.
if [[ -v _CORE_CONFIG_IS_SOURCED ]]; then
    return
fi
_CORE_CONFIG_IS_SOURCED="y"


# TODO: Sort out which of all the defined variables are really needed
# to be exported to frija and fensalir commands.


# Get the very basic support functions and varibles like print_message
# and print_error as well as definition of bold, italic, etc. escape
# sequences and so on.
source "${_FENSALIR_HOME}/.basic_functions.bash"


# The environment variable that hold the user name differ between
# operating systems; in Linux it is $USER and in Windows it is
# $USERNAME. Simplify things by creating a common variable that is
# assigned either $USER or $USERNAME.
export _FRIJA_USER="${USER:-${USERNAME}}"

# Disable X11 forwarding for SSH to get rid of the annoying "X11
# forwarding request failed on channel 0" message in the terminal
# shellcheck disable=SC2034
export GIT_SSH_COMMAND="ssh -x"

# Version value to indicate that it is not a fixed version for a repo.
# shellcheck disable=SC2034
NON_VERSION="floating"

# Marker for print_error function to force it to not call exit and
# instead use return.
#
# shellcheck disable=SC2034
_FRIJA_NO_EXIT="exit"

# Marker indicating that a dependency is a variation point and thus
# must have a generic identifier. See transformVariationPoint() for
# more information.
#
# shellcheck disable=SC2034
VARIATION_POINT="vp"


# shellcheck disable=SC2034
DIRTY_REPO_STATE="dirty"

# shellcheck disable=SC2034
CLEAN_REPO_STATE="clean"


# Name of MSBuild property file carrying dependency information.
# Automatically included by project files provided that they include
# the Microsoft property files; project files created using Visual
# Studio will automatically do this.
#
# shellcheck disable=SC2034
MSBUILD_PROPERTY_FILE="Directory.Build.props"


# Name suffix used for JSON file generated for CMake dependency
# injection. Generated filename is the name of the repo combined with
# this suffix.
#
# shellcheck disable=SC2034
CMAKE_DEPENDENCY_FILE_SUFFIX="_dependencies.json"

# Folders used by generate, build, prepare, archive, and clean
# commands
#
# shellcheck disable=SC2034
BUILD_DIR="Build"

# shellcheck disable=SC2034
BUILD_DATE_FILE_SUFFIX=".builddate"

# shellcheck disable=SC2034
BUILD_METADATA_FILE_SUFFIX=".buildmetadata"

# shellcheck disable=SC2034
BUILD_TOOL_METADATA_FILE_SUFFIX=".buildtoolmetadata"

# $BUILD_RESULT_DIR is used solely for CMake and is due to how it
# works. It is not possible to compile against what is placed in
# Build, instead you must first do an install to get a copy of the
# content in Build restructured in a way that other repos can use when
# building. Alas this copy also contain for instance an include folder
# that should not be part of what is installed. Hence the $PREPARE_DIR
# folder should not contain such folders (if it is the binary
# installation).
#
# shellcheck disable=SC2034
BUILD_RESULT_DIR="Result"

# shellcheck disable=SC2034
PREPARE_DIR="Prepare"
# shellcheck disable=SC2034
ARCHIVE_DIR="Archive"

# $RELEASE_DIR is where release builds (i.e. without debug
# information) end up
#
# shellcheck disable=SC2034
RELEASE_DIR="Release"

# $DEBUG_DIR is where debug builds (i.e. with debug information) end
# up
#
# shellcheck disable=SC2034
DEBUG_DIR="Debug"


# $_FRIJA_BUILD_RELEASE and $_FRIJA_BUILD_DEBUG are used for instance
# on the command line when selecting the kind of build to start
#
# shellcheck disable=SC2034
_FRIJA_BUILD_RELEASE="${RELEASE_DIR^^}"
# shellcheck disable=SC2034
_FRIJA_BUILD_DEBUG="${DEBUG_DIR^^}"
# shellcheck disable=SC2034
_FRIJA_DEFAULT_BUILD_TYPE="${_FRIJA_BUILD_DEBUG}"


# Name of config file in $_VOLLA_HOME_FOLDER that define the execution
# environment for Frija and Volla CLI tools
#
# shellcheck disable=SC2034
_FENSALIR_INIT="fensalir-init.bash"


# Extension used for the data file used by most Frija commands WITHOUT
# any leading dot
#
# shellcheck disable=SC2034
REPO_LIST_EXTENSION_NO_DOT="repos"

# Extension used for the data file used by most Frija commands
# shellcheck disable=SC2034
REPO_LIST_EXTENSION=".${REPO_LIST_EXTENSION_NO_DOT}"



# Name of marker file branding the repo as a model repo, that is
# hosting a simulator model.
#
# shellcheck disable=SC2034
FRIJA_MODEL_REPO_ID=".modelrepo"


# Name of marker file branding a repo as a Fensalir environment repo.
# Such a repo points to
#
# - The Volla repo to use
#
# - The build environment to use (SECI implementation)
#
# - List of dependencies to other Fensalir environment repos the Volla
#   database depends on
#
# - Mapping file used when resolving inter Volla repo dependencies.
#   This file contain the mappings to use when there is an incoming
#   dependency to the linked Volla repo.
#
# shellcheck disable=SC2034
FENSALIR_ENV_REPO_ID=".fensalirenvironment"

# Name of marker file branding the repo as a Volla database repo.
#
# shellcheck disable=SC2034
VOLLA_REPO_ID=".volla"

# Name of marker file branding the repo as a Frija Build Environment
# repo.
#
# shellcheck disable=SC2034
FRIJA_BUILD_ENV_REPO_ID=".buildenvironment"

# File containing URI to Volla repo to use
#
# shellcheck disable=SC2034
FENSALIR_VOLLA_POINTER="VollaRepoPointer"

# File containing URI to Build environment repo to use. The name of
# this repo is expected to end with the suffix "-<country code>-<site
# name>-<domain name>" in lowercase, e.g. "_se_tn_gride-hs".
#
# shellcheck disable=SC2034
FRIJA_BUILD_POINTER="BuildEnvPointer"

# Optional file containing list of URIs to other Fensalir environment
# repos the Volla database depend on. The file format is line-based
# where fields are separated by at least one space. Each line contains
# the fields VCS-type (e.g. "git") followed by URI to use when cloning
# the repo. Empty lines or lines starting with '#' are ignored.
#
# shellcheck disable=SC2034
FENSALIR_DEPS_POINTER="DependencyPointers"



# Frija partitions the SECI concept in three separate categories
#
# 1. Paths to installations of software in the normal filesystem,
#    variable definitions, and so on that are used within a makefile.
#    In this category you also have tools such as GCC, Doxygen, dot,
#    PlantUML, and so on.
#
# 2. Paths to commands that are used for executing makefiles, for
#    instance GNU Make, CMake, Ninja, MSBuild, and so on.
#
# 3. Generic tools used in the development environment such as Bash,
#    Git, grep, tar, Emacs, and Vi as well as version of Fensalir repo
#    to use.
#
# 4. OS distribution and version
#
# 5. OS kernel version
#
# Frija only manages categories #1 och #2; categories #3 and above are
# thus out of scope and must be handled in some other way.

# Name of folder in locale repos that contain files with variable
# definition(s) to be used inside makefiles, for instance dependencies
# to folders outside of the Frija repo tree. These files can be
# referenced from the $REPO_LIST_EXTENSION-file and content is then
# transferred and included in files generated by frija-generate
# command.
#
# shellcheck disable=SC2034
BUILD_CONF="BuildConfiguration"


# Name of folder in locale repos that contain SECI definitions, that
# is paths to build tools used for executing the repo makefile (e.g.
# CMake, Ninja, MSBuild, etc.) as well as commands executed within
# makefile that are not stored outside of Frija controlled repos.
#
# shellcheck disable=SC2034
FENSALIR_SECI_FOLDER="SECI"

# Filename extension used for SECI-files that realize a SECI entry for
# a specific country, site, and domain.
#
# shellcheck disable=SC2034
FENSALIR_SECI_EXTENSION=".seci"

# File in $_FRIJA_CONFIG_FOLDER_NAME containing the branch strategy to
# use; specified when the workspace was created. That is either what
# to do when no explicit version is specified or Feature ID for
# workspace (expected branch prefix for feature branches).
#
# shellcheck disable=SC2034
_FRIJA_WS_BRANCH_STRATEGY_FILE="default-branch-strategy"


# File in $_FRIJA_CONFIG_FOLDER_NAME containing the configured
# Fensalir environment; specified when the workspace was created.
#
# See for instance also functions frija_retrieve_environment_name(),
# frija_retrieve_volla_name(), and
# frija_retrieve_build_environment_name().
#
# shellcheck disable=SC2034
_FRIJA_WS_CONFIG_FILE="configuration"

# Name of field containing configured locale in
# $_FRIJA_WS_CONFIG_FILE-file
#
# shellcheck disable=SC2034
_FRIJA_WS_ENVIRONMENT_FIELD="FensalirEnv"

# File in $_FRIJA_CONFIG_FOLDER_NAME containing composites used by the
# workspace. This file is automatically updated by the frija-clone
# command; when it encounters a composite in a .repos file that is new
# it is appended to this file. The content of the file is a
# space-separated list of composites.
_FRIJA_WS_COMPOSITES_FILE="composites"


# Prefix used for files containing exported data; for instance files
# that are in XML-coded format need to be exported to some other
# format that is parsable by a Bash script (usually line- and column
# based formats).
EXPORT_PREFIX="exported-"


# Value used for selecting matching against only release versions.
#
# shellcheck disable=SC2034
MATCH_RELEASE="RELEASE"

# Value used for selecting matching against release versions plus
# release candidate versions regardless of their locale.
#
# shellcheck disable=SC2034
MATCH_LENIENT="LENIENT"

# Value used for selecting matching against release versions plus
# release candidate versions with locale matching current locale.
#
# shellcheck disable=SC2034
MATCH_STRICT="STRICT"


# Function is lenient when it comes to checks and just prints a
# message to the terminal instead of aborting, or similar.
#
# shellcheck disable=SC2034
LENIENT_SENSITIVITY="Lenient"


# Function is strict when it comes to checks and aborts instead of
# just printing a message to the terminal.
#
# shellcheck disable=SC2034
STRICT_SENSITIVITY="Strict"


# Path to config folder in Fensalir repo
_FENSALIR_CONFIG_NAME="config"
# shellcheck disable=SC2034
_FENSALIR_CONFIG_PATH="${_FENSALIR_ROOT}/${_FENSALIR_CONFIG_NAME}"

# Path to config folder in Fensalir repo
_FENSALIR_SUPPORT_NAME="config"
# shellcheck disable=SC2034
_FENSALIR_SUPPORT_PATH="${_FENSALIR_ROOT}/${_FENSALIR_SUPPORT_NAME}"

_FRIJA_HOME_FOLDER="frija"
_FRIJA_PATH="${PWA}/${_FRIJA_HOME_FOLDER}"

# Marker folder signifying the home of Frija specific files
_FRIJA_CONFIG_FOLDER_NAME=".frija"

# Subfolder in $_FRIJA_CONFIG_FOLDER_NAME containing cached data that
# can safely be removed when a command exits
#
# shellcheck disable=SC2034
_FRIJA_CONFIG_CACHE_FOLDER_NAME="cache"

# Path to $_FRIJA_CONFIG_FOLDER_NAME
#
# shellcheck disable=SC2034
_FRIJA_CONFIG_CACHE_PATH=""

# These variables are assigned a value when _frija_locate_workspace
# function defined in .preamble.bash is called
#
# shellcheck disable=SC2034
_FRIJA_CONFIG_FOLDER_PATH=""


################################################################################
# What to checkout after repo has been cloned; either a branch or a
# tag. This is defined using a tuple of two items defined in table
# below
#
# |   Commit Type   | What to checkout                                |
# +=================+=================================================+
# | $_FRIJA_FEATURE | Only Feature ID                                 |
# | $_FRIJA_DEVELOP | One of $VCS_HEAD, $VCS_VERSION, $VCS_RC_VERSION |
# | $_FRIJA_RELEASE | One of $VCS_HEAD and $VCS_VERSION               |
# | $_FRIJA_TAG     | A tag or short SHA                              |
# +-----------------+-------------------------------------------------+
#

# $_FRIJA_FEATURE map to a feature branch matching the given feature
# identifier (stored somewhere else)
#
# shellcheck disable=SC2034
_FRIJA_FEATURE="Feature"


# $_FRIJA_DEVELOP map to the development branch; what to checkout is
# stored somewhere else, which then can have one of the values
# $VCS_HEAD, $VCS_VERSION, or $VCS_RC_VERSION.
#
# shellcheck disable=SC2034
_FRIJA_DEVELOP="Develop"


# $_FRIJA_RELEASE map to the development branch; what to checkout is
# stored somewhere else, which then can have one of the values
# $VCS_HEAD or $VCS_VERSION.
#
# shellcheck disable=SC2034
_FRIJA_RELEASE="Release"


# $_FRIJA_TAG map to a specific (given) tag name; which tag is stored
# somewhere else.
#
# shellcheck disable=SC2034
_FRIJA_TAG="Tag"
################################################################################


################################################################################
# TODO Should these remain?
################################################################################
## What to checkout on a branch when $TAG nor $_FRIJA_FEATURE has been
## selected.
##
#
## $VCS_HEAD means the latest available commit (for instance "HEAD" on
## a Git branch)
##
## shellcheck disable=SC2034
#VCS_HEAD="HEAD"
#
#
## $VCS_VERSION means the commit with the latest valid version tag;
## release-candidate versions are excluded.
##
## shellcheck disable=SC2034
#VCS_VERSION="Released"
#
#
## $VCS_RC_VERSION means the commit with the latest valid version tag;
## release-candidate versions are included.
##
## shellcheck disable=SC2034
#VCS_RC_VERSION="RC or Released"
#################################################################################


# Used for indicating preference of latest available commit on a
# branch.
#
# shellcheck disable=SC2034
_FRIJA_LATEST="LATEST"


# Used for indicating preference of latest available version. Whether
# that is latest available version including or excluding release
# candidate versions depends on whether $_FRIJA_DEVELOP or
# $_FRIJA_RELEASE branch has been selected.
#
# shellcheck disable=SC2034
_FRIJA_VERSION="VERSION"


# Is one of $_FRIJA_FEATURE, $_FRIJA_DEVELOP, or $_FRIJA_RELEASE.
#
# This variable is assigned a value when the file
# $_FRIJA_WS_BRANCH_STRATEGY_FILE is read from the workspace
# configuration folder in function _frija_locate_workspace().
#
# shellcheck disable=SC2034
_FRIJA_DEFAULT_BRANCH=""


# Is one of the values $_FRIJA_LATEST, $_FRIJA_VERSION, or
# the empty string.
#
# when the file $_FRIJA_WS_BRANCH_STRATEGY_FILE is read from the workspace
# configuration folder. The former case is when
# $_FRIJA_BRANCH_STRATEGY is either $_FRIJA_DEVELOP or
# $_FRIJA_RELEASE, and the latter case is for all other cases.
#
# This variable is assigned a value when the file
# $_FRIJA_WS_BRANCH_STRATEGY_FILE is read from the workspace
# configuration folder in function _frija_locate_workspace().
#
# shellcheck disable=SC2034
_FRIJA_BRANCH_STRATEGY=""


# Is either Feature ID for a workspace or the empty string. The former
# case is when $_FRIJA_BRANCH_STRATEGY is $_FRIJA_FEATURE, and the
# latter case is for all other cases.
#
# This variable is assigned a value when the file
# $_FRIJA_WS_BRANCH_STRATEGY_FILE is read from the workspace
# configuration folder in function _frija_locate_workspace().
#
# shellcheck disable=SC2034
_FRIJA_FEATURE_ID=""


# Regexp pattern for feature branch names that extract the branch
# prefix and feature ID from the branch name.
#
# The pattern allows any branch prefix before the feature ID; both
# branch prefix and feature ID can be retrieved independently from
# each other, or as a group. The variables
# $_FRIJA_FEATURE_BRANCH_INDEX, $_FRIJA_FEATURE_BRANCH_PREFIX_INDEX,
# and $_FRIJA_BRANCH_FEATURE_ID_INDEX respectively contain the regexp
# indexes for these fields
#
# shellcheck disable=SC2034
_FRIJA_BRANCH_PATTERN="^((([^/]+/)+)?([A-Z]+-[0-9]+)).*$"


# Index into $BASH_REMATCH for combination of branch prefix and
# Feature ID
#
# shellcheck disable=SC2034
declare -i _FRIJA_BRANCH_INDEX=1


# Index into $BASH_REMATCH for branch prefix
#
# shellcheck disable=SC2034
declare -i _FRIJA_BRANCH_PREFIX_INDEX=2


# Index into $BASH_REMATCH for Feature ID in branch name
#
# shellcheck disable=SC2034
declare -i _FRIJA_BRANCH_FEATURE_ID_INDEX=4



# _frija_file_list places its return value (array of files) in this
# array. When Bash 4.3 or newer is available a nameref local variable
# should be used instead.
#
# That is, all uses of below variable should be removed.
declare -a _FRIJA_FILE_LIST
_FRIJA_FILE_LIST=()


# Get functions for handling of locales into the environment
#
# shellcheck source=./.locale_handling.bash
source "${_FENSALIR_HOME}/.locale_handling.bash"


# Resolve name of pager to use when showing the help text for a
# command. Behavior can be controlled via environment variables in the
# standard shell environment, precedence order is
#
#   1. $FRIJAPAGER
#   1. $MANPAGER
#   2. $PAGER
#   3. $GIT_PAGER
#   4. less --quit-if-one-screen --raw-control-chars
#   5. cat
#
# Return value is pager to use.
function _frija_pager()
{
    local pager="cat"

    # Use less command if it exist in case none of the environment
    # variables tested below configure a command to use
    type -t less &> /dev/null \
        && pager="less --quit-if-one-screen --raw-control-chars"

    if [[ -v FRIJAPAGER ]]; then
        pager="${FRIJAPAGER}"
    elif [[ -v MANPAGER ]]; then
        pager="${MANPAGER}"
    elif [[ -v PAGER ]]; then
        pager="${PAGER}"
    elif [[ -v GIT_PAGER ]]; then
        pager="${GIT_PAGER}"
    fi

    echo "${pager}"
}


function print_no_repo_match_error()
{
    local reponame="${1}"
    local inFile="${2}"
    local message="${3:-}"
    local tool="${4:-}"


    if [[ -n "${message}" ]]; then
        print_message
        print_double_separator
        #print_message "${BOLD}${message}${CLEAR}"
        print_message "'${message}'"
        print_double_separator
    fi

    print_message
    if [[ -z "${reponame}" ]]; then
        message="No repos found for OS "
        message+="${BOLD}${_FENSALIR_OS_ID}${CLEAR} "
        message+="in ${BOLD}${inFile}${CLEAR}."
    else
        message="Repo '${reponame}' for OS "
        message+="${BOLD}${_FENSALIR_OS_ID}${CLEAR} could not "
        message+="be found in ${BOLD}${inFile}${CLEAR}."
	if [[ "${tool}" == "${NONE}" ]]; then
	    message+="\n"
	    message+="${BOLD}Hint: Configured build tool for "
	    message+="'${reponame}' is '${tool}'; "
	    message+="is this intentional?${CLEAR}"
	fi
    fi
    print_message "${message}\\n"

    if [[ -z "${reponame}" ]]; then
        message="The repos file you are currently using is most likely not "
        message+="generated for the operating system you are currently using "
        message+="(${_FENSALIR_CURRENT_OS})."
    else
        message="Might current working directory be in a repo and version of "
        message+="this repo not referenced in input file?"
    fi
    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM

    print_debug_exit
}


function print_os_error()
{
    print_debug_enter "${@}"

    local itemArrayName="${1}"
    local inFile="${2}"
    local message="${3:-}"

    # Associative array used for filtering out unique elements from
    # the array with name $itemArrayName. This is done by iterating
    # over that array and adding element by elenment to $uniqueItems.
    # Bash will ensure that all duplicates are ignored. Once all items
    # has been processed you will have the unique ones left.
    declare -A uniqueItems=()

    # This can be made simpler when Bash 4.3 or later is used. For now
    # we have to stick with Bash 4.2. First an array reference
    # expression need to be constructed which is then used when
    # expanding the array. Indirect reference to array is used via
    # "${!itemArrayRef}" construct. See for instance
    # print_two_columns() for more information.
    local itemArrayRef="${itemArrayName}[@]"
    declare -i width=0
    local item=""
    for item in "${!itemArrayRef}"; do
        # Store a dummy value ('1') in the value part for key $item.
        uniqueItems["${item}"]=1

        # Get max width of all listed OS names
        if (( ${#item} > width )); then
            width=${#item}
        fi
    done

    if [[ -n "${message}" ]]; then
        print_message
        print_double_separator
        #print_message "${BOLD}${message}${CLEAR}"
        print_message "'${message}'"
        print_double_separator
    fi

    declare -i count=${#uniqueItems[@]}
    local splice=""
    if (( count == 1 )); then
        splice="${BOLD}${!uniqueItems[*]}."
    else
        splice="the following operating system$(plural ${count})${BOLD}"
    fi

    print_message
    message="Current OS is ${BOLD}${_FENSALIR_OS_ID}${CLEAR} and all "
    message+="entries in ${BOLD}${inFile}${CLEAR} require ${splice}"
    print_message "${message}"

    if (( count > 1 )); then
        # Print all keys in associative array $uniqueItems on separate
        # lines. Format string '%*s' means that first the field width is
        # given and then the value. The printf builtin will repeat the
        # format string for all given values.
        print_message ""
        local format="  %${width}s\\n"
        # shellcheck disable=SC2059
        printf "${format}" "${!uniqueItems[@]}"
    fi

    print_message "${CLEAR}"

    message="Are you sure you are using an input file designed for your OS?"
    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM

    print_debug_exit
}


function plural()
{
    local count="${1}"
    local result="s"

    if [[ "${count}" == "1" ]]; then
        result=""
    fi

    echo "${result}"
}


declare -i COLUMN_PADDING=3


function print_two_columns()
{
    local firstColumn="${1}"
    local secondColumn="${2}"

    local firstColumnRef="${firstColumn}[@]"
    local secondColumnRef="${secondColumn}[@]"

    # Calculate max string length for all items
    declare -i maxLength=0
    declare -i length=0
    local item=""
    # Note: The sequence '${!' introduces variable indirection, that
    #       is the value of the variable formed from the rest of
    #       parameter is used as the name of the actual variable. In
    #       this case, $firstColumnRef is expanded and then used as
    #       the actual value for the parameter expansion. That is if
    #       $firstColumn is "foobar" then firstColumnRef is
    #       "foobar[@]" which means that "${!firstColumnRef}" is
    #       expanded to ${foobar[@]}...
    for item in "${!firstColumnRef}"; do
        length="${#item}"
        if (( length > maxLength )); then
            maxLength=${length}
        fi
    done

    # Print two columns containing array values. Since the arrays are
    # passed as names this means that we must use indirect array
    # references. Due to limitations in Bash 4.2 (that are resolved in
    # 4.3) we have to first copy the elements into temporary arrays
    # before we can iterate over both of them at the same time.
    #
    # Create a copy of the arrays
    local secondArray=("${!secondColumnRef}")
    local firstArray=("${!firstColumnRef}")
    local description=""
    length=${#firstArray[@]}
    for (( index=0; index<length; index++ )); do
        item="${firstArray[${index}]}"
        padding=$(( maxLength - ${#item} + COLUMN_PADDING ))
        description="${secondArray[${index}]}"
        print_message "${item}${LINE:0:${padding}}${description}"
    done
}


function print_prefix()
{
    local value="${1}"

    if [[ "${VERBOSE}" == "n" ]]; then
        echo -n -e "${BOLD}${value}${CLEAR} "
    fi
}


# FIXME: Not currently used?!?!?
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
    result=$(git log --oneline --decorate=short HEAD^ | ${_FENSALIR_GREP} "^[a-z0-9]* ([^)]*\\(origin\\|develop\\|master\\)" | sed -e "s/[)].*/)/" -e "s/HEAD.*, //" -e "s/tag[:][^,]*, //" -e "s|origin/||" -e "s/[()]//g" -e "s/, /\\n/g" | head --lines=1)

    # Result now contain a short SHA plus corresponding branch name
    # separated by a single space, return it
    echo "${result}"
}


# Extract repo name from given URI and return it.
function frija_extract_repo_name()
{
    print_debug_enter "${@}"
    local uri="${1}"

    local result=""

    if [[ "${uri}" == "/"* ]]; then
        result=$(git_reponame "${uri}")
    else
        # Extract reponame from URI.
        #
        # NOTE: How to do this is highly dependent on the server hosting
        # the Git repos, for instance it differes wildly between Bitbucket
        # and ADO (Azure DevOps). However Bitbucket, GitHub, and GitLab
        # all share very similar URI formats.
        if [[ "${uri}" =~ ^[a-z][a-z]*://.*/([^/]+)[.]git$ ]]; then
            print_debug_array "BASH_REMATCH"
            result="${BASH_REMATCH[1]}"
        fi

        if [[ -z "${result}" ]]; then
            local message="Unknown repo URI format: '${uri}'"
            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
        fi
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Return first line of $_FRIJA_WS_COMPOSITES_FILE and return it as a
# string. It is assumed to be formatted as a comma-separated list of
# composite folder names.
function _frija_read_composites()
{
    local name="${1:-}"

    print_debug "name='${name}'"
    local inputFile=""
    if [[ -z "${name}" ]]; then
        # Assume current working directory ($PWD) is within Workspace
        # folder tree; ensure no error message if outside of Workspace
        # folder tree
        _frija_locate_workspace "${LENIENT_SENSITIVITY}"
        inputFile="${_FRIJA_CONFIG_FOLDER_PATH}"
    else
        # User gives an explicit Workspace name on the command line,
        # utilize it to locate the Workspace folder to operate on.
        inputFile="${_FRIJA_PATH}/${name}/${_FRIJA_CONFIG_FOLDER_NAME}"
    fi
    inputFile+="/${_FRIJA_WS_COMPOSITES_FILE}"
    print_debug "inputFile='${inputFile}'"

    local result=""
    if [[ -r "${inputFile}" ]]; then
        declare -a currentComposites=()

        # shellcheck disable=SC2162
        read -a currentComposites < "${inputFile}"

        result="${currentComposites[*]}"
    fi

    print_debug "result='${result}'"
    echo "${result}"
}


# To get the Volla repo name configured for a Workspace you must first
# create a path to the Fensalir environment repo, for instance by
# using the function frija_retrieve_environment_name() which reads it
# from the Workspace configuration file.
#
# Once you have this path you call this function with that path as an
# argument and it will return the name of the Volla repo for that
# Fensalir environment.
function frija_retrieve_volla_name()
{
    print_debug_enter "${1}"
    local repopath="${1}"

    local result=""

    local input="${repopath}/${EXPORT_PREFIX}${FENSALIR_VOLLA_POINTER}"

    if [[ -f "${input}" ]]; then
        # An exported $FENSALIR_VOLLA_POINTER file exist, extract repo
        # name from it.

        print_debug "Reading from '${input}'"
        local vollaVcs=""
        local vollaUri=""
        while read -r kind remote rest; do
            # Strip any carriage returns from the read values
            vollaVcs=${kind//$'\r'}
            vollaUri=${remote//$'\r'}

            print_debug "vollaVcs='${vollaVcs}'"
            print_debug "vollaUri='${vollaUri}'"

            local done=""
            if [[ "${vollaVcs}" == "#"* ]] \
                   || [[ -z "${vollaVcs}" ]]; then
                # Skip to next line if current line start with a
                # comment character or it is an empty line
                continue
            elif [[ -z "${done}" ]]; then
                # Set $done flag to check if there are multiple
                # uncommented lines. If so it is an error, since
                # the file is only supposed to contain one line.
                result=$(frija_extract_repo_name "${vollaUri}")
                done="y"
                print_debug "result='${result}'"
            else
                # Multiple uncommented and nonempty lines have been
                # found. This is ambigious and indicate that this
                # there is something fishy going on by printing a
                # warning message and exit loop.
                local message="Found multiple lines with repo URIs "
                message+="in '${input}'; "
                message+="either add comments so there is a single line "
                message+="with a URI to a repo or remove them from the "
                message+="file. For now the first repo URI found is used."
                print_warning "${message}"
                break
            fi
        done < "${input}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# To get the Frija build environment repo name configured for a
# Workspace you must first get the name of the Fensalir environment
# repo, for instance by using the function
# frija_retrieve_environment_name() which reads it from the Workspace
# configuration file.
#
# Once you have this name you call this function with that name as an
# argument and it will return the name of the Frija build environment
# repo for that Fensalir environment.
function frija_retrieve_build_environment_name()
{
    print_debug_enter "${1}"
    local reponame="${1}"

    local result=""

    local input="${_VOLLA_PATH}/${reponame}/"
    input+="${EXPORT_PREFIX}${FRIJA_BUILD_POINTER}"
    print_debug "input='${input}"

    if [[ -f "${input}" ]]; then
        # An exported $FRIJA_BUILD_POINTER file exist, extract repo
        # name from it.

        print_debug "Reading from '${input}'"
        local buildEnvVcs=""
        local buildEnvUri=""
        while read -r kind remote rest; do
            # Strip any carriage returns from the read values
            buildEnvVcs=${kind//$'\r'}
            buildEnvUri=${remote//$'\r'}

            print_debug "buildEnvVcs='${buildEnvVcs}'"
            print_debug "buildEnvUri='${buildEnvUri}'"

            local done=""
            if [[ "${buildEnvVcs}" == "#"* ]] \
                   || [[ -z "${buildEnvVcs}" ]]; then
                # Skip to next line if current line start with a
                # comment character or it is an empty line
                continue
            elif [[ -z "${done}" ]]; then
                # Set $done flag to check if there are multiple
                # uncommented lines. If so it is an error, since
                # the file is only supposed to contain one line.
                result=$(frija_extract_repo_name "${buildEnvUri}")
                done="y"
                print_debug "result='${result}'"
            else
                # Multiple uncommented and nonempty lines have been
                # found. This is ambigious and indicate that this
                # there is something fishy going on by printing a
                # warning message and exit loop.
                local message="Found multiple lines with repo URIs "
                message+="in '${input}'; "
                message+="either add comments so there is a single line "
                message+="with a URI to a repo or remove them from the "
                message+="file. For now the first repo URI found is used."
                print_warning "${message}"
                break
            fi
        done < "${input}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Return configured Fensalir environment repo name for either given
# Workspace (path to Workspace) or Workspace found from current
# working directory.
function frija_retrieve_environment_name()
{
    local name="${1:-}"

    print_debug "name='${name}'"
    local inputFile=""
    if [[ -z "${name}" ]]; then
        # Assume current working directory ($PWD) is within Workspace
        # folder tree; ensure no error message if outside of Workspace
        # folder tree
        _frija_locate_workspace "${LENIENT_SENSITIVITY}"
        inputFile="${_FRIJA_CONFIG_FOLDER_PATH}"
    else
        # User gives an explicit Workspace name on the command line,
        # utilize it to locate the Workspace folder to operate on.
        inputFile="${_FRIJA_PATH}/${name}/${_FRIJA_CONFIG_FOLDER_NAME}"
    fi
    inputFile+="/${_FRIJA_WS_CONFIG_FILE}"

    local result=""
    if [[ -r "${inputFile}" ]]; then
        local field=""
        local value=""
        local rest=""
        while read -r field value rest; do
            field="${field//$'\r'}"
            value="${value//$'\r'}"
            rest="${rest//$'\r'}"

            if [[ "${field}" == "${_FRIJA_WS_ENVIRONMENT_FIELD}" ]]; then
                # Pick first available value matching the field name
                # we are looking for
                result="${value}"
                break;
            fi
        done < "${inputFile}"
    fi

    echo "${result}"
}


# List all Fensalir Environments found in $_VOLLA_PATH which are
# identified by the $FENSALIR_ENV_REPO_ID file that each such repo
# must have in order to be a Fensalir Environment repo.
function frija_list_environments()
{
    print_debug_enter

    # Use nameref for indirection, that is $array hold a reference to
    # the variable used as the first (in this case) parameter of this
    # function. That is, it behaves in the same way as a reference in
    # Java, C#, or C++
    #
    # When Bash 4.3 or newer is used the nameref variable files could
    # be used instead.
    #local -n files="${1}"
    local -a files

    print_debug "_VOLLA_PATH=${_VOLLA_PATH}"
    if [[ -d "${_VOLLA_PATH}" ]]; then
        print_debug "${_VOLLA_PATH} exist"
        # Glob pattern for all workspace folders. That is all folders
        # in $_VOLLA_PATH that have a $FENSALIR_ENV_REPO_ID
        # marker file is a Fensalir Environment repo.
        local globPattern="${_VOLLA_PATH}/*/${FENSALIR_ENV_REPO_ID}"

        print_debug "globPattern=${globPattern}"

        # In order to trigger the glob-expansion the variable
        # expansion must be done outside of a string.
        #
        # shellcheck disable=SC2206
        files=(${globPattern})
        print_debug_array "files" "Fensalir Environments found: "

        # Here we intentionally expand the same variable expression
        # within a string since if the glob expansion did not match
        # any files it simply returns the literal string and thus we
        # have to check for that to catch this case.
        if [[ "${files[0]}" == "${globPattern}" ]];
        then
            # There were no files matching the glob
            files=()
            print_debug "files array set to empty array"
        else
            # Remove $_VOLLA_PATH prefix from each element in the
            # $files array
            files=("${files[@]##${_VOLLA_PATH}/}")
            print_debug "${files[*]}"

            # Remove $FENSALIR_ENV_REPO_ID suffix from each
            # element in the $files array
            files=("${files[@]%/${FENSALIR_ENV_REPO_ID}}")
            print_debug "${files[*]}"
        fi
    else
        print_debug "${_VOLLA_PATH} does NOT exist!"
    fi

    print_debug "${files[*]}"
    # Remove line below when Bash 4.3 or newer is used.
    _FRIJA_FILE_LIST=("${files[@]}")
    print_debug "${_FRIJA_FILE_LIST[*]}"

    print_debug_array "_FRIJA_FILE_LIST"
    print_debug_exit
}


# List all workspaces found in $_FRIJA_PATH. Workspaces are identified
# by the $_FRIJA_CONFIG_FOLDER_NAME subfolder that each workspace must
# have in order to be a workspace.
function frija_list_workspaces
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

    if [[ -d "${_FRIJA_PATH}" ]]; then
        # Glob pattern for all workspace folders. That is all folders
        # in $_FRIJA_PATH that have a $_FRIJA_CONFIG_FOLDER_NAME
        # subfolder are workspaces.
        local globPattern="${_FRIJA_PATH}/*/${_FRIJA_CONFIG_FOLDER_NAME}"

        # In order to trigger the glob-expansion the variable
        # expansion must be done outside of a string.
        #
        # shellcheck disable=SC2206
        files=(${globPattern})
        print_debug_array "files" "Workspaces found: "

        # Here we intentionally expand the same variable expression
        # within a string since if the glob expansion did not match
        # any files it simply returns the literal string and thus we
        # have to check for that to catch this case.
        if [[ "${files[0]}" == "${globPattern}" ]];
        then
            # There were no files matching the glob
            files=()
        else
            # Remove $_FRIJA_PATH prefix from each element in the
            # $files array
            files=("${files[@]##${_FRIJA_PATH}/}")

            # Remove $_FRIJA_CONFIG_FOLDER_NAME suffix from each
            # element in the $files array
            files=("${files[@]%/${_FRIJA_CONFIG_FOLDER_NAME}}")
        fi
    fi

    # Remove line below when Bash 4.3 or newer is used.
    _FRIJA_FILE_LIST=("${files[@]}")
}


# shellcheck disable=SC2034
DIR_FILTER="d"
# shellcheck disable=SC2034
FILE_FILTER="f"

# $1 is a placeholder for a nameref variable: Bash 4.3 or newer support it
# $2   (basePath): Base path to use
# $3    (subPath):
# $4 (filePrefix): Glob for beginning of file name (can be empty)
# $5 (fileSuffix): Glob for end of file name (can be empty)
# $6 (globIgnore): Optional glob for files to ignore (default empty)
# $7     (filter): Optional filter (default empty);
#                  One of $DIR_FILTER or $FILE_FILTER (or empty)
#
# NOTE: that globs containing whitespace characters must be treated
#       with extreme care! Ensure such characters are properly quoted
#       as the corresponding variables are expanded outside of strings
#       and are thus susceptible to word splitting!
function frija_list_files()
{
    local trapRestoreExpr=""
    trapRestoreExpr+="$(_frija_restore_globignore_expression)"
    trapRestoreExpr+="; $(shopt -p nullglob)"
    trapRestoreExpr+="; $(shopt -p -o braceexpand)"
    trapRestoreExpr+="; $(shopt -p extglob)"

    print_debug "trapRestoreExpr='${trapRestoreExpr}'"

    # We want the expansion to expand before trap executes to be able
    # to restore it to its original value.
    #
    # TODO: Add more generic handling of cleanup hooks so we can have
    # multiple of them within a function but also in function chains
    # as well.
    #
    # shellcheck disable=SC2064
    trap "${trapRestoreExpr}" RETURN

    # Turn on nullglob option, that is glob expressions that do not
    # match result in an empty string being returned instead of the
    # glob expression.
    shopt -s nullglob

    # Turn on brace expansion option
    shopt -s -o braceexpand

    # Turn on extended glob option
    shopt -s extglob

    # Use nameref for indirection, that is $array hold a reference to
    # the variable used as the first (in this case) parameter of this
    # function. That is, it behaves in the same way as a reference in
    # Java, C#, or C++
    #
    # When Bash 4.3 or newer is used the nameref variable files could
    # be used instead.
    #local -n files="${1}"
    local -a files=()

    local basePath="${2}"
    local subPath="${3}"
    local filePrefix="${4:-}"
    local fileSuffix="${5:-}"
    local globIgnore="${6:-}"
    local fileTypeFilter="${7:-}"

    if [[ -n "${globIgnore}" ]]; then
        globIgnore+=":"
    fi

    # Exclude all files with file names matching the GLOBIGNORE glob
    # when doing globbing file name expansion. Furthermore also
    # exclude Emacs backup files.
    #
    # TODO: Can extended globs be used here?
    GLOBIGNORE="${globIgnore}*~*"

    print_debug "basePath='${basePath}'"
    print_debug "subPath='${subPath}'"
    print_debug "filePrefix='${filePrefix}'"
    print_debug "fileSuffix='${fileSuffix}'"
    print_debug "globIgnore='${globIgnore}'"
    print_debug "fileTypeFilter='${fileTypeFilter}'"

    # Pattern used for generating list of files and/or directories.
    local globPattern="${basePath}"
    print_debug "A: Glob expand pattern: '${globPattern}'"

    # Ensure $globPattern ends with a slash before appending the other
    # variables to it. Glob pattern is built up from five components,
    # where the fifth is '*' which might be inserted at a specific
    # point based on the values of two of the other four components.
    #
    # Basically you have one of
    #   1) ${basePath}/${subPath}/${filePrefix}${fileSuffix}
    #   2) ${basePath}/${subPath}/${filePrefix}*${fileSuffix}
    #   3) ${basePath}/${filePrefix}${fileSuffix}
    #   4) ${basePath}/${filePrefix}*${fileSuffix}
    #
    # The star is inserted when either $filePrefix is a non-empty
    # string OR $subPath does NOT end with slash.
    if [[ "${globPattern: -1:1}" != "/" ]]; then
        globPattern+="/"
    fi
    print_debug "B: Glob expand pattern: '${globPattern}'"

    globPattern+="${subPath}"
    print_debug "C: Glob expand pattern: '${globPattern}'"
    print_debug "C: Glob expand pattern:-1:1 : '${globPattern: -1:1}'"

    if [[ "${globPattern: -1:1}" != "/" ]]; then
        globPattern+="/"
    fi
    print_debug "D: Glob expand pattern: '${globPattern}'"

    globPattern+="${filePrefix}"
    print_debug "E: Glob expand pattern: '${globPattern}'"

    # If $filePrefix IS a non-empty string OR $subPath does NOT end
    # with '/' then the heuristics is that a star should be inserted
    # between $filePrefix and $fileSuffix in $globPattern.
    if [[ -n "${filePrefix}" ]] || [[ "${subPath: -1:1}" != "/" ]]
    then
        globPattern+="*"
    fi
    print_debug "F: Glob expand pattern: '${globPattern}'"

    globPattern+="${fileSuffix}"
    print_debug "G: Glob expand pattern: '${globPattern}'"

    # Ensure all spaces are correctly quoted in $globPattern by first
    # replacing all spaces with '\ ' and then all sequneces of one or
    # more backslash followed by space with '\ '. That is
    #
    # First ' ' => '\ ' which may produce '\\ ' in case the space was
    # already properly quoted.
    #
    # Then replace as below
    # '\ ' => '\ '
    # '\\ ' => '\ '
    # '\\\ ' => '\ '
    # ...
    globPattern="${globPattern// /\\ }"
    print_debug "H: Glob expand pattern: '${globPattern}'"
    globPattern="${globPattern//+(\\) /\\ }"

    print_debug "Glob expand pattern: '${globPattern}'"
    print_debug "basePath='${basePath}'"

    print_debug "Expanding glob..."
    # Glob-expand $globPattern to get a list of files and/or
    # directories. In order to be able to trigger globbing the
    # variable *must* expanded outside of a string. Otherwise the
    # special glob characters would be interpreted literally by
    # Bash and that is not what we want. The drawback is that the
    # variable is susceptible to word splitting and thus all
    # spaces must be quoted in the correct way so that the quotes
    # survives the expansion and no word splitting occur.
    #
    # shellcheck disable=SC2206
    declare -a files=( ${globPattern} )

    print_debug_array "files"

    if (( ${#files[@]} == 0 )); then
        print_debug "Setting _FRIJA_FILE_LIST to empty array"
        _FRIJA_FILE_LIST=()
    else
        # The filter mechanism is very crude, it can only discern
        # between files and folders.
        if [[ -n "${fileTypeFilter}" ]]; then
            for i in "${!files[@]}"; do
                if [[ "${fileTypeFilter}" == "${FILE_FILTER}" ]] \
                       && [[ -d "${files[i]}" ]]; then
                    print_debug "Removed directory '${files[i]}' from list"
                    unset 'files[i]'
                elif [[ "${fileTypeFilter}" == "${DIR_FILTER}" ]] \
                         && [[ ! -d "${files[i]}" ]]; then
                    print_debug "Removed file '${files[i]}' from list"
                    unset 'files[i]'
                fi
            done
        fi

        print_debug "Removing prefix basePath='${basePath}/'"
        # Remove $basePath from each element in the $files array
        files=( "${files[@]#${basePath}/}" )

        print_debug "Returning: '${files[*]}'"

        # Remove 2 lines below when Bash 4.3 or newer is used.
        # shellcheck disable=SC2034
        _FRIJA_FILE_LIST=( "${files[@]}" )
    fi
}


function ensure_input_file()
{
#    DEBUG="y"
    print_debug_enter "${@}"

    local inputFile="${1}"

    if [[ -z "${inputFile}" ]]; then
        print_debug "Trying to auto-locate an input file..."
        # Try to automatically find an input file using same function
        # as is used when completing the input file
        inputFile=$(auto_locate_repo_file)
        print_debug "Found '${inputFile}'"
    fi

    if [[ -z "${inputFile}" ]]; then
        local message=""
        local inputFileList=""
        print_debug "Could not auto-locate an input file"
        inputFileList=$(_frija_subcommand_repo_file_list)
        print_debug "Candidates are {${inputFileList[*]}}"

        if [[ -n "${inputFileList}" ]]; then
            message="No input file specified; please specify one of "
            # We DO want word splitting to occur in order to be able to
            # create an array. And we assume here that no file with a
            # $REPO_LIST_EXTENSION contain a space in their file names.
            # Naming rules of systems, sub-systems, and repos forbid that.
            #
            # shellcheck disable=SC2206
            declare -a fileList=(${inputFileList})
            declare -i length=${#fileList[@]}

            if (( length > 2 )); then
                local subList="${fileList[*]:0:length-1}"
                message+="${BOLD}${subList// /${CLEAR}, ${BOLD}}${CLEAR}, "
                message+="and ${BOLD}${fileList[*]:length-1}${CLEAR}"
            elif (( length > 1 )); then
                local list="${fileList[*]}"
                message+="${BOLD}${list/ /${CLEAR} and ${BOLD}}${CLEAR}"
            fi
        else
            message="Workspace corrupt; no input files available to choose from"
        fi

        if [[ -n "${message}" ]]; then
            print_error "${message}, aborting." $_FRIJA_EXIT_CMD_LINE_PROBLEMS
        fi
    fi

    if [[ "${inputFile}" != *"${REPO_LIST_EXTENSION}" ]]; then
        # Ensure input file ends with $REPO_LIST_EXTENSION
        print_debug "Appending ${REPO_LIST_EXTENSION} to '${inputFile}'"
        inputFile="${inputFile}${REPO_LIST_EXTENSION}"
    fi

    print_debug_exit "${inputFile}"
    echo "${inputFile}"
}
