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


# TODO: Sort out which of all the defined variables are really needed
# to be exported to frija and fensalir commands.


# Provide a common Bash option configuration function that set the
# following options
#
# errexit Bash exits if a command exits with a non-zero exit code
#
# pipefail Return value of a pipeline is the value of the last
#          (rightmost) command to exit with a non-zero status, or zero if all
#          commands in the pipeline exited successfully.
#
# noclobber Bash does not overwrite an existing file with the >, >&,
#           and <> redirection operators. May be overridden by using
#           >| instead of >.
#
# nounset Treat unset variables and parameters other than the special
#         parameters "@" and "*" as an error when performing parameter
#         expansion. If expansion is attempted on an unset variable or
#         parameter, the shell prints an error message, and, if not
#         interactive, exits with a non-zero status.
function _frija_configure_bash()
{
    # Ensure that all functions that call this function execute in an
    # environment where these Bash options are set
    set -o errexit -o pipefail -o noclobber -o nounset

    # NOTE: When Bash version 4.4+ is used this line can be
    # uncommented and ALL calls to this function from within other
    # functions can be safely removed.
    #
    # shopt -s inherit_errexit
}


# Get common exit code definitions
#
# shellcheck source=./.exit_codes.bash
source "${_FENSALIR_HOME}/.exit_codes.bash"


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
_FENSALIR_SETUP="fensalir-setup.bash"


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
# where fields are separated by spaced. Each line contains the fields
# VCS-type (e.g. "git") followed by URI to use when cloning the repo.
# Empty lines or lines starting with '#' are ignored.
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


# Terminal width
# shellcheck disable=SC2034
! WIDTH=$(tput cols)
WIDTH="${WIDTH:-80}"

BOLD=""
ITALIC=""
REVERSE=""
UNDERLINE_ON=""
UNDERLINE_OFF=""
CLEAR=""

if [[ -z "${_FRIJA_NO_ESCAPES:-}" ]]; then
    # Begin bold mode ON sequence
    # shellcheck disable=SC2034
    ! BOLD=$(tput bold)
    BOLD="${BOLD:-$(echo -e \\e[1m)}"

    # Begin italic mode ON sequence. In case tput reports terminal does
    # not support italic mode we use VT100 escape sequence as a fallback.
    # For instance termcap for xterm terminal in CentOS 7.9 does not
    # report that italic mode is supported by the terminal even though it
    # actually is...
    # shellcheck disable=SC2034
    ! ITALIC=$(tput sitm)
    ITALIC="${ITALIC:-$(echo -e \\e[3m)}"

    # Begin reverse video ON mode sequence
    # shellcheck disable=SC2034
    ! REVERSE=$(tput rev)
    REVERSE="${REVERSE:-$(echo -e \\e[7m)}"

    # Begin underline ON mode sequence
    # shellcheck disable=SC2034
    ! UNDERLINE_ON=$(tput smul)
    UNDERLINE_ON="${UNDERLINE_ON:-$(echo -e \\e[4m)}"

    # Begin underline OFF mode sequence
    # shellcheck disable=SC2034
    ! UNDERLINE_OFF=$(tput rmul)
    UNDERLINE_OFF="${UNDERLINE_OFF:-$(echo -e \\e[24m)}"

    # Clear all attributes
    # shellcheck disable=SC2034
    ! CLEAR=$(tput sgr0)
    CLEAR="${CLEAR:-$(echo -e \\e[0m)}"
fi

_VOLLA_HOME_FOLDER="volla"
_VOLLA_PATH="${PWA}/${_VOLLA_HOME_FOLDER}"

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


# Ensure $_FRIJA_PRINT_DEBUG exist as a variable and at the same time
# allow it to be set from the outside.
_FRIJA_PRINT_DEBUG="${_FRIJA_PRINT_DEBUG:-}"


# Very basic function that echoes a message to stderr provided that
# the GLOBAL variable $_FRIJA_PRINT_DEBUG is set to 'y'. This function
# is used when print_debug() can't be used. For instance,
# print_debug() calls _frija_fold() which means that _frija_fold()
# can't rely on print_debug() for debug printouts...
function _frija_echo()
{
    echo "${1}" 1>&2
}


# Very basic function that echoes a message to stderr provided that
# the GLOBAL variable $_FRIJA_PRINT_DEBUG is set to 'y'. This function
# is used when print_debug() can't be used. For instance,
# print_debug() calls _frija_fold() which means that _frija_fold()
# can't rely on print_debug() for debug printouts...
function _frija_dcho()
{
    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        echo "${1}" 1>&2
    fi
}


# Preferred minimum width of body text when folding a message. Highest
# priority is to try to preserve at least this width when folding
# text. This means that any outdents and indents go first before the
# body width is reduced beyond this value.
declare -i _FRIJA_MIN_WIDTH=30


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


# Fold a string so it either fits within a terminal window (provided
# that $WIDTH can be assigned a meaningful value) or to a specified
# width. Furthermore it is possible to indent the string given number
# of characters.
#
# Any VT100 escape sequences embedded in the string are ignored when
# calculating where to force linebreaks, and any embedded ANSI-C
# quoting sequences are passed through and their width is considered
# to be one character. Alas multicharacter sequences are not
# guaranteed to be unscathed by the folding logic; newlines may be
# inserted in the middle of them...
#
# First parameter is the message itself to fold
#
# Second (optional) parameter is the indent in number of characters to
# reserve space on the left hand side from the width of the terminal
# window. Default is 0 (zero) characters of indent.
#
# Third (optional) parameter is the width to use when folding. Default
# width is the terminal width, and if it couldn't be determined 80
# characters is the fallback value.
#
# Fourth (optional) value is hanging text for an outdent of the first
# line of the folded text. This is given as the text to use as the
# hanging outdent, for instance "Note:". A space is added to the end
# of the text and the number of charaacters in the given text plus one
# is added to the indent value. Default value is the empty string.
function _frija_fold()
{
    local message="${1}"

    # Indent of folded message
    declare -i indent="${2:-0}"

    # Indent of all lines after first line
    declare -i bodyIndent=${indent}

    # Width to use when folding
    declare -i width="${3:-${WIDTH:-80}}"

    # Optional outdent "heading", for instance "Note:" or "Warning:"
    local outdent="${4:-}"
    declare -i outdentWidth=0

    #_FRIJA_PRINT_DEBUG="y"
    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        _frija_dcho "outdent=${outdent}"
        _frija_dcho "indent=${indent}"
        _frija_dcho "width=${width}"
        _frija_dcho "--- Input ----"
        od -A x -t x1z -v <<< "${message}" 1>&2
        _frija_dcho "--------------"
    fi

    if [[ -n "${outdent}" ]]; then
        # A hanging text outdent has been provided, add a space at the
        # end to this text while ensuring that any spaces provided at
        # the start or end of $outdent are first removed.
        outdent="${outdent/#*( )/}"
        outdent="${outdent/%*( )/} "

        # Enable extended globbing support in Bash and restore its
        # state to whatever it was when function return. Extended
        # globbing means that you can write globbing expressions like
        # *(foo) that match zero or more occurrences of 'foo'.
        #
        # shellcheck disable=SC2064
        trap "$(frija_restore_extglob_expression)" RETURN
        shopt -s extglob

        # Remove all VT100 escape sequences from $outdent
        local plain="${outdent//$'\e'[\[(]*([0-9;])[@-n]/}"

        # Now we can calculate the real width (as shown in terminal)
        # of string
        declare -i outdentWidth=${#plain}
    fi

    _frija_dcho "outdent='${outdent}'"
    _frija_dcho "outdentWidth='${outdentWidth}'"

    local padding=""
    local bodyPadding=""

    _frija_dcho "width='${width}'"
    _frija_dcho "_FRIJA_MIN_WIDTH='${_FRIJA_MIN_WIDTH}'"

    # Adjust indent if necessary to ensure that the body text gets as
    # much space as possible
    if (( indent > 0 )); then
        if (( width < indent )); then
            if (( width > _FRIJA_MIN_WIDTH )); then
                indent=$(( width - _FRIJA_MIN_WIDTH ))
                _frija_dcho "A: indent='${indent}'"
            else
                indent=0
                _frija_dcho "B: indent='${indent}'"
            fi
        else
            if (( width > _FRIJA_MIN_WIDTH )); then
                if (( (indent+_FRIJA_MIN_WIDTH) > width )); then
                    indent=$(( width - _FRIJA_MIN_WIDTH ))
                    _frija_dcho "C: indent='${indent}'"
                else
                    #indent=0
                    _frija_dcho "D: indent='${indent}'"
                fi
            else
                indent=0
                _frija_dcho "E: indent='${indent}'"
            fi
        fi
    fi

    _frija_dcho "indent='${indent}'"

    if (( indent >= 0 )) && (( indent < width )); then
        # Assume it is possible to indent wrapped text by $indent +
        # $outdentWidth spaces, except for first line which is
        # controlled by just $indent
        declare -i preliminaryWidth=$(( width - indent - outdentWidth ))

        if (( preliminaryWidth < _FRIJA_MIN_WIDTH )); then
            if (( preliminaryWidth > 0 )); then
                # Make part of $outdent "glide" into message to
                # preserve $_FRIJA_MIN_WIDTH of body width in message

                declare -i overshoot=$(( _FRIJA_MIN_WIDTH - preliminaryWidth ))
                declare -i newOutdentWidth=0
                if (( overshoot < outdentWidth )); then
                    newOutdentWidth=$(( outdentWidth - overshoot ))
                elif (( (overshoot-outdentWidth) < indent )); then
                    # Possible to reduce indent to preserve a body
                    # width of at least $_FRIJA_MIN_WIDTH characters
                    indent=$(( indent - (overshoot-outdentWidth) ))
                else
                    indent=0
                fi

                _frija_dcho "overshoot=${overshoot}"
                _frija_dcho "newOutdentWidth=${newOutdentWidth}"

                # Prepend end of $outdent to $message, and strip any
                # leading spaces from $message when it is expanded
                local suffix="${outdent:newOutdentWidth}"
                message="${suffix}${CLEAR}${message/#*( )/}"
                _frija_dcho "####: Outdent ('${suffix}') prepended to message."
                outdent="${BOLD}${outdent:0:newOutdentWidth}"

                if [[ "${suffix}" == " " ]]; then
                    # Compensate for initial space stripping of
                    # $message in main loop below
                    outdent+=" "
                    _frija_dcho "Outdent space-suffix compensated."
                fi

                outdentWidth=$(( newOutdentWidth ))
            else
                # Make whole $outdent "glide" into message to
                # preserve $_FRIJA_MIN_WIDTH of body width in message
                outdentWidth=0
                preliminaryWidth=$(( width - indent ))

                if (( preliminaryWidth < _FRIJA_MIN_WIDTH )); then
                    # Also consume a part of $indent
                    indent=$(( indent - (_FRIJA_MIN_WIDTH-preliminaryWidth) ))
                    if (( indent < 0 )); then
                        # No, consume all of $indent as well!
                        indent=0
                    fi
                fi

                # Prepend $outdent to $message, and strip any leading
                # spaces from $message when it is expanded
                message="${BOLD}${outdent}${CLEAR}${message/#*( )/}"
                _frija_dcho "####: Outdent ('${outdent}') prepended to message."
                outdent=""
            fi
        else
            _frija_dcho "Whole outdent ('${outdent}') bolded"
            # Ensure the outdent is bolded
            outdent="${BOLD}${outdent}${CLEAR}"
        fi

        bodyIndent=$(( indent + outdentWidth ))

        # After any adjustments above we can re-calculate the new
        # width. Indent wrapped text by $indent + $outdentWidth
        # spaces, except for first line which is controlled by just
        # $indent
        width=$(( width - indent - outdentWidth ))
        _frija_dcho "####: Using width=${width}"
        _frija_dcho "      (indent=${indent}, outdentWidth=${outdentWidth})"

        # Padding for first line. Padding string is created using
        # printf built-in command where '*' is a computed repeated
        # sequence where the number of spaces precedes the string to
        # indent; here we indent the empty string to get the padding.
        padding=$(printf "%*s" "${indent}" "")
        _frija_dcho "####: Using padding='${padding}'"

        if (( bodyIndent > indent )); then
           bodyPadding=$(printf "%*s" "${bodyIndent}" "")
        else
            bodyPadding=${padding}
        fi
        _frija_dcho "####: Using bodyPadding='${bodyPadding}'"
    fi

    # $count is where the cursor is within the current line
    declare -i count=0

    # $escapeCount is where the cursor is within the current line when
    # an escape sequence has been found
    declare -i escapeCount=0

    # $buffer is what is to be sent to the terminal after folding is
    # done
    local buffer=""

    if [[ -n "${outdent}" ]]; then
        # Insert the padding plus the outdent for the first line
        buffer="${padding}${outdent}"
    else
        # Just insert the padding since no outdent has been provided
        buffer="${bodyPadding}"
    fi

    # Temporary buffer used when an escape sequence has been found
    local escapeBuffer=""

    # Current "word", that is a sequence delimited by spaces
    local word=""

    # Current "word", that is a sequence delimited by spaces, when an
    # escape sequence has been found
    local escapeWord=""

    # The escape sequence that has been found
    local escapeSequence=""

    # Read one character at a time from the given message and parse
    # the content, that is any VT100 escape sequences etc. When
    # appropriate insert forced newlines to wrap the text in the
    # terminal.
    while IFS="" read -r -N1 character; do
        case "${character}" in
            $'\e'|" ")
                _frija_dcho "Found Escape or SPACE"

                declare -i length=${#word}
                if (( count > width )); then
                    # Insert a forced line break

                    _frija_dcho "count > width  (${count}>${width})"
                    _frija_dcho "newline"
                    _frija_dcho "word='${word}' (${length} characters)"

                    if (( length > width )); then
                        _frija_dcho "length > width (${length}>${width})"

                        # Number of characters to add BEFORE forced
                        # line break; compensate also for SPACE
                        declare -i before=$(( width - (count-length) ))

                        # Number of characters to add AFTER forced
                        # line break
                        declare -i after=$(( (length) - before ))

                        local start="${word:0:before}"
                        local end="${word:before}"

                        _frija_dcho "start='${start}'"
                        _frija_dcho "end='${end}'"
                        _frija_dcho "after='${after}'"
                        buffer+="${escapeSequence}${start}\\n"
                        escapeSequence=""
                        # shellcheck disable=SC2028
                        _frija_dcho "'${start}\\\\n' added"

                        _frija_dcho "Looping over end ('${end}')"
                        # Iterate over the remainder of the overlong
                        # word. Note that the loop will only execute
                        # the body for all subparts that are exactly
                        # $width wide. If less than the requested
                        # number of characters are available to read
                        # then the body will not be executed for that
                        # portion. Hence the IF-statement AFTER the
                        # wile-loop...
                        local line=""
                        while read -r -N${width} line; do
                            # Decrement $after with what we just read
                            after=$(( after - width ))

                            buffer+="${bodyPadding}${line}\\n"
                            # shellcheck disable=SC2028
                            _frija_dcho "'${bodyPadding}${line}\\\\n' added"
                        done <<< "${end}"

                        if (( after > 0 )); then
                            # A newline character is appended to the
                            # end of the read remainder which has to
                            # be trimmed. This is done using a simple
                            # parameter expansion with string
                            # replacement that replaces all '\n'
                            # (expressed as $'\n' in Bash) with
                            # nothing.
                            line="${line%%*($'\n')}"
                            buffer+="${bodyPadding}${line}"
                            _frija_dcho "'${bodyPadding}${line}' added"
                        else
                            buffer+="${bodyPadding}"
                            _frija_dcho "'${bodyPadding}' added"
                        fi

                        count=$(( after ))
                        _frija_dcho "count=${count}"
                    else
                        _frija_dcho "length <= width (${length} <= ${width})"
                        buffer+="\\n${bodyPadding}${escapeSequence}${word}"
                        escapeSequence=""
                        count=${length}

                        # shellcheck disable=SC2028
                        _frija_dcho "'\\\\n${bodyPadding}${word}' added"
                    fi
                else
                    _frija_dcho "count <= width  (${count} <= ${width})"

                    # Safe to insert complete word in buffer + SPACE
                    _frija_dcho "add '${word}' (${count} <= ${width})"

                    buffer+="${escapeSequence}${word}"
                    escapeSequence=""
                    _frija_dcho "'${word}' inserted"
                fi

                # As $word has been inserted it must be reset to empty
                # string
                word=""

                if [[ "${character}" == " " ]]; then
                    _frija_dcho "Found SPACE"
                    if (( count == width )); then
                        _frija_dcho "At end of line, forcing line break"
                        buffer+="\\n${bodyPadding}"
                        count=0
                    elif (( count > 0 )); then
                        buffer+=" "
                        count+=1
                        _frija_dcho "count=${count} ('${character}', '${word}')"
                    else
                        _frija_dcho "Ignoring initial space"
                    fi
                else
                    _frija_dcho "Found ESC"
                    # Double bookkeeping; $escapeSequence contain what
                    # we hope is an acutal escape sequence, and
                    # $escapeBuffer in combination with $escapeCount
                    # and $escapeWord implement a shadow world where
                    # the escape seuence turn out to not be a valid
                    # sequence and is instead treated as a "word" that
                    # is brutally splitted whenever the terminal width
                    # is reached. It is also due to this that the
                    # escape character (0x1b) is not added to
                    # $escapeWord (to make the sequence visible).
                    escapeSequence="${character}"

                    # As $escapeBuffer is appended to $buffer in case
                    # the sequence turn out to not be a valid escape
                    # sequence there is no need to initialize it to
                    # anything else than the empty string; it
                    # piggybacks on whatever is in the buffer.
                    escapeBuffer=""
                    escapeWord=""
                    escapeCount=${count}

                    # Read assumed initial [ or (
                    IFS="" read -r -N1 character

                    escapeSequence+="${character}"

                    escapeCount+=1
                    if (( escapeCount > width )); then
                        # Insert a forced line break
                        escapeBuffer+="${escapeWord}"
                        escapeBuffer+="\\n${bodyPadding}"
                        escapeWord=""
                        escapeCount=1
                    fi
                    escapeWord+="${character}"

                    if [[ "${character}" == [\[\(] ]]; then
                        # We are still within a valid VT100 escape
                        # sequence found, copy optional digits
                        # separated with ';'
                        while IFS="" read -r -N1 character; do
                            case "${character}" in
                                [0-9\;] )
                                    escapeSequence+="${character}"

                                    escapeCount+=1
                                    if (( escapeCount > width )); then
                                        # Insert a forced line break
                                        escapeBuffer+="${escapeWord}"
                                        escapeBuffer+="\\n${bodyPadding}"
                                        escapeWord=""
                                        escapeCount=1
                                    fi
                                    escapeWord+="${character}"

                                    continue
                                    ;;
                                *)
                                    break
                                    ;;
                            esac
                        done

                        # Finally check that the character at the end
                        # of the sequence is within the range [@-n],
                        # otherwise it is not a valid VT100 escape
                        # sequence.
                        if [[ "${character}" == [@-n] ]]; then
                            # Escape sequence ended!
                            _frija_dcho "ESC-sequence ended (${escapeWord})"

                            # Insert whole escape sequence in the
                            # buffer and we are finished with it!
                            escapeSequence+="${character}"
                            #buffer+="${escapeSequence}"
                        else
                            _frija_dcho "Non-ESC-sequence ended (${escapeWord})"

                            escapeCount+=1
                            if (( escapeCount > width )); then
                                # Insert a forced line break
                                escapeBuffer+="${escapeWord}"
                                escapeBuffer+="\\n${bodyPadding}"
                                escapeWord=""
                                escapeCount=1
                            fi
                            escapeWord+="${character}"

                            buffer+="${escapeBuffer}"
                            word="${escapeWord}"
                            count=${escapeCount}
                        fi
                    fi
                fi
                ;;
            "\\")
                _frija_dcho "Found \\"
                _frija_dcho "count=${count} ('${character}', '${word}')"

                # NOTE: This code may break \nnn and similar escape
                # sequences that are longer than backslash plus one
                # character by inserting a "\n" sequence in the middle
                # of them.
                word+="${character}"
                IFS="" read -r -N1 character
                case "${character}" in
                    "n")
                        word+="${character}${bodyPadding}"
                        screenWord+="${character}${bodyPadding}"
                        count=0
                        ;;
                    "\\")
                        count+=1
                        ;;
                    *)
                        word+="${character}"
                        screenWord+="${character}"
                        count+=1
                        ;;
                esac

                _frija_dcho "\\-sequence ended"
                _frija_dcho "count=${count} ('${character}', '${word}')"
                ;;
            *)
                count+=1
                word+="${character}"

                _frija_dcho "count=${count} ('${character}', '${word}')"
                ;;
        esac
    done <<< "${message}"

    _frija_dcho "After main while loop"

    # Add any lingering escape sequence to the buffer
    buffer+="${escapeSequence}"
    escapeSequence=""

    # Strip any trailing newline character
    word="${word/%$'\n'/}"
    count=$((count-1))
    _frija_dcho "word='${word}'"
    _frija_dcho "count='${count}'"
    _frija_dcho "width='${width}'"

    # There might be a word left when end of file was reached. Borrow
    # from space character handling logic above to insert it into the
    # buffer.

    declare -i length=${#word}
    _frija_dcho "length of '${word}' is ${length} characters"
    declare -i after=0
    local line=""
    if (( count > width )); then
        _frija_dcho "count > width  ( ${count}>${width})"

        # Number of characters to add BEFORE forced
        # line break; compensate also for SPACE
        declare -i before=$(( width - (count-length) ))
        _frija_dcho "before='${before}'"

        # Number of characters to add AFTER forced
        # line break
        _frija_dcho "length='${length}'"
        _frija_dcho "before='${before}'"
        after=$(( length - before ))
        _frija_dcho "after='${after}'"

        local start="${word:0:before}"
        local end="${word:before}"
        end="${end/%$'\n'/}"

        # Strip any trailing newline characters
        end="${end%%*($'\n')}"

        _frija_dcho "start='${start}'"
        _frija_dcho "end='${end}'"
        _frija_dcho "after='${after}'"
        buffer+="${escapeSequence}${start}\\n"
        escapeSequence=""
        # shellcheck disable=SC2028
        _frija_dcho "'${start}\\\\n' added"

        _frija_dcho "Looping over end ('${end}'), after=${after}"
        # Iterate over the remainder of the overlong word. Note that
        # '-n${width}' means "up to $width" characters where as
        # '-N${width}' means "EXACTLY $width" characters or no
        # characters at all.
        _frija_dcho "width='${width}'"
        while read -r -n${width} line; do
            # Decrement $after with what we just read
            after=$(( after - width ))
            _frija_dcho "after=${after}"

            line="${line%%*($'\n')}"
            buffer+="${bodyPadding}${line}\\n"
            # shellcheck disable=SC2028
            _frija_dcho "'${bodyPadding}${line}\\\\n' added"
        done <<< "${end}"

        _frija_dcho "After loop, after=${after}"
    else
        _frija_dcho "count <= width  ( ${count}<=${width})"
        buffer+="${word}\\n"
        #buffer+="${word}"
        # shellcheck disable=SC2028
        _frija_dcho "'${word}\\\\n' added"
    fi

    if [[ "${_FRIJA_PRINT_DEBUG}" == "y" ]]; then
        _frija_dcho "--- Output ---" 1>&2
        od -A x -t x1z -v <<< "${buffer}" 1>&2
        _frija_dcho "--------------" 1>&2
    fi

    # shellcheck disable=SC2059
    printf '%b' "${buffer}" 1>&2

    if [[ -n "${_FRIJA_IS_SOURCED:-}" ]]; then
        # Force bash to redraw prompt when within TAB-completion
        _frija_redraw_current_line
    fi
}


# Note: Indentation does is NOT aware of any difference between escape
# sequences and ordinary text. That is, escape sequence characters are
# counted as normal characters and thus affect where line breakes are
# inserted...
#
# First parameter is message to print.
#
# Second (optional) parameter is indentation
#
# Third (optional) parameter is width; when no width is specified the
# value of $WIDTH is used (usually set by shell) and if no value is
# assigned to $WIDTH then the fallback of 80 characters is used.
function print_message()
{
    local message="${1:-}"
    declare -i indent="${2:-0}"
    declare -i width="${3:-${WIDTH:-80}}"

    #echo "Q" 1>&2
    _frija_fold "${message}" "${indent}" "${width}"
    #echo "Q" 1>&2

#    if (( indent > 0 )) && (( indent < width )); then
#        # Indent wrapped text by $indent spaces provided that $indent
#        # is not greater than the terminal width. This is done first
#        # by reducing $WIDTH by $indent and then piping the result
#        # through sed that inserts the padding.
#        width=$(( width - indent ))
#        echo "####: Using width='${width}'"
#
#        # Padding string is created using printf built-in command
#        # where '*' is a computed repeated sequence where the number
#        # of spaces precedes the string to indent; here we indent the
#        # empty string to get the padding.
#        local padding=""
#        padding=$(printf "%*s" "${indent}" "")
#        echo "####: Using padding='${padding}'"
#
#        # Replace all line starts ('^') with the padding using sed
#        fold --spaces --width="${width}"<<<"${message}" | \
#            sed -e "s/^/${padding}/" >&2
#    else
#        # Ensure formatted text wraps nicely to terminal width and
#        # redirect to stderr
#        fold --spaces --width="${width}"<<<"${message}" >&2
#    fi
}


function _frija_print_stack_trace()
{
    local exitcode="${1}"

    declare -i extraIndent=0

    local message=""

    if  (( BASH_SUBSHELL < 2 )); then
        print_double_separator
        message="Command "
    else
        print_separator
        extraIndent=2
        message="Subshell "
    fi

    message+="exited with exit code ${exitcode}: Stack trace"
    print_message "${message}" "${extraIndent}"

    # Renumber the arrays if they were sparse (which they might be)
    local sourcetrace=("${BASH_SOURCE[@]}")
    local functrace=("${FUNCNAME[@]}")
    local linetrace=("${BASH_LINENO[@]}")

    declare -i lastFuncIndex=$(( ${#functrace[@]} - 1 ))
    declare -i lastLineIndex=$(( ${#linetrace[@]} - 1 ))
    # Heuristics to make stack trace sane
    if (( lastFuncIndex == lastLineIndex )) \
           && (( lastFuncIndex > 0 )) \
           && (( linetrace[lastLineIndex] == 0 )) \
           && [[ "${functrace[${lastFuncIndex}]}" == "main" ]]
    then
        functrace=("${functrace[@]}::${lastFuncIndex}")
        linetrace=("${linetrace[@]}::${lastLineIndex}")

        # Remove second last source item
        declare -i lastSourceIndex=$(( ${#sourcetrace[@]} - 1 ))
        unset "sourcetrace[$((lastSourceIndex-1))]"

        # Renumber elements after deletion to get consecutive
        # numbering
        sourcetrace=("${sourcetrace[@]}")
    else
        print_message "FJUK: linetrace[0]=${linetrace[0]}  functrace[0]=${functrace[0]}"
        declare -p functrace 1>&2
        declare -p linetrace 1>&2
    fi

    declare -i indent=2
    if (( BASH_SUBSHELL > 1 )); then
        (( indent+=extraIndent))
    fi

    declare -i index=0
    for (( index=${#sourcetrace[@]}-1 ; index>=0 ; index-- ));
    do
        if (( index > 0 )); then
            local func="${BOLD}${functrace[$index]}${CLEAR}"
            local linenumber="${linetrace[$index]}"
            local sourcefile=""
            sourcefile=$(relative_path_to "${sourcetrace[$index]}")
            print_message "at ${func}(${sourcefile}:${linenumber})" "${indent}"
        fi
    done

    if  (( BASH_SUBSHELL < 2 )); then
        print_separator
    fi
}


# If TAB completion is active force Bash prompt to be redrawn
function _frija_redraw_current_line()
{
    if [[ -v COMP_TYPE ]]; then
        # Force Bash to redraw the command line prompt by signaling a
        # (terminal) window size change that causes readline to redraw
        # the prompt.
        kill -WINCH "$$"
    fi
}


function _frija_print_error()
{
    local message="${1}"
    declare -i exitcode=${2}
    local noExit="${3:-}"

    if [[ -n "${message}" ]]; then
        declare -i extraIndent=0

        if  (( BASH_SUBSHELL < 2 )); then
            _frija_print_stack_trace "${2:-}"
            print_separator ""
        else
            extraIndent=2
            print_double_separator
        fi

        if [[ $exitcode -eq 3 ]]; then
            _frija_fold "${message}" "${extraIndent}" "" "INTERNAL ERROR:"
        else
            _frija_fold "${message}" "${extraIndent}" "" "Error:"
        fi

        if  (( BASH_SUBSHELL < 2 )); then
            print_separator
            print_message
            message="Try '${BOLD}${_FRIJA_USAGE_NAME} --help${CLEAR}' "
            message+="for more information."
            print_message "${message}"
            print_message
        else
            _frija_print_stack_trace "${2:-}"
        fi
    else
        _frija_print_stack_trace "${2:-}"
    fi

    if [[ -z "${_FRIJA_IS_SOURCED:-}" ]] && [[ -z "${noExit}" ]]; then
        #print_message "Calling exit..."
        #local message="${BOLD}*** ${BASH_SOURCE[1]}  "
        #message+="${FUNCNAME[2]}():${BASH_LINENO[1]}"
        #message+="-->${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"
        #print_message "${message}"
        #local array_data=""
        #array_data=$(declare -p "BASH_SOURCE")
        #print_message "${array_data}"
        #array_data=$(declare -p "FUNCNAME")
        #print_message "${array_data}"
        #array_data=$(declare -p "BASH_LINENO")
        #print_message "${array_data}"

        # Only exit when top level script is NOT sourced
        exit "${exitcode}"
    else
        #print_message "Calling return..."
        # Force a stack trace to be printed to the terminal
        _frija_print_stack_trace "${exitcode}"
        _frija_redraw_current_line

        return "${exitcode}"
    fi
}


function print_error()
{
    #print_message "\$BASH_SOURCE[0]='${BASH_SOURCE[0]}'"
    #print_message "\$0='${0}'"
    #print_message "\${0##*/}='${0##*/}'"
    #print_message "\${BASH##*/}='${BASH##*/}'"
    #print_message "_FRIJA_IS_SOURCED='${_FRIJA_IS_SOURCED}'"

    if [[ "${0##*/}" == "${BASH##*/}" ]]; then
        # Sourced from outside of a frija-command/TAB-completion
        # context; print error message as a "help-message" instead.
        #
        # Furthermore
        #   - Strip any trailing ", aborting." from the help message
        #   - Ignore exit code
        _frija_completion_help_mesage "${1%, aborting.}"
    else
        #print_message "Frija command"
        print_newline_only_after_dot
        _frija_print_error "${@}"
    fi
}


function print_warning()
{
    warning="${1}"
    message="${2:-}"
    print_separator
    print_message "${BOLD}WARNING:${CLEAR} ${warning}"
    if [[ -n "${message}" ]]; then
        print_message ""
        print_message "${message}"
    fi
    print_separator
}


function print_note()
{
    local message="${1:-}"
    local border="${2:-}"

    declare -i indent="${3:-0}"
    declare -i width="${4:-${WIDTH:-80}}"

    if [[ "${border}" == "y" ]]; then
        print_separator
    fi

    _frija_fold "${message}" "0" "${width}" "Note:"

    if [[ "${border}" == "y" ]]; then
        print_separator
    fi
}


function print_no_repo_match_error()
{
    local reponame="${1}"
    local inFile="${2}"
    local message="${3:-}"


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


# Create a variable $LINES containing $COLUMNS spaces (or if not set
# use instead terminal width). This variable is then used for creating
# two other variables; $SINGLE_LINE and $DOUBLE_LINE respectively.
COLUMNS=${COLUMNS:-$(tput cols)}
printf -v LINE "%${COLUMNS}s" ' '

# Initialize $SINGLE_LINE by replacing all spaces in $LINE with '-'
# characters
SINGLE_LINE="${LINE// /-}"

# Initialize $DOUBLE_LINE by replacing all spaces in $LINE with '='
# characters
DOUBLE_LINE="${LINE// /=}"


# Number of characters to use before message when splicing a message into a line
declare -i PREFIX_LENGTH=5

function print_separator()
{
    local message="${1:-}"
    local isBold="${2:-}"

    if [[ -z "${message}" ]]; then
        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${SINGLE_LINE}${CLEAR}"
        else
            message="${SINGLE_LINE}"
        fi
    else
        # Enable extended globbing support in Bash and restore its
        # state to whatever it was when function return. Extended
        # globbing means that you can write globbing expressions like
        # *(foo) that match zero or more occurrences of 'foo'.
        #
        # shellcheck disable=SC2064
        trap "$(frija_restore_extglob_expression)" RETURN
        shopt -s extglob

        # We have to strip any ANSI escape sequences from the message
        # before we calculate the message length. This is done using
        # Bash builtin regexp string replacement.
        #
        # We are using Bash built in Parameter Expansion replacement
        # function that uses a globbing pattern where $'\e' is
        # expanded to the escape character (0x1b).
        #
        # [\[(] define a character class, i.e. matches one of [ and (
        #
        # *([0-9;]) matches zero or more occurrences of the character
        # class [0-9;]
        #
        # [@-n] finally define a character class that matches all
        # ASCII characters between '@' and 'n' in the ASCII table.
        # Note that all uppercase characters comes before the
        # lowercase characters in the ASCII table.
        local plain="${message//$'\e'[\[(]*([0-9;])[@-n]/}"
        declare -i length="${#plain}"

        # We want a line that looks like this
        # 0         1         2         3
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ----- Foobar --------------------...
        #
        # In above example $PREFIX_LENGTH is 5 as there are 5 '-' from
        # the start of the line to the string " Foobar ". Idea is to
        # splice string in two parts and insert the message " Foobar "
        # in such a way that the total length of the line is equal to
        # the length of the line without any message.
        #
        # This is done by first picking $PREFIX_LENGTH characters from
        # $SINGLE_LINE. Then append the message with the ' ' before
        # and after the message. And finally start from the
        # corresponding index in the line and print everything till
        # the end.
        # 0         1         2         3
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ----- Foobar --------------------...
        #     *        *
        #     |        |
        #     |        $PREFIX_LENGTH+1+${#message}+1
        #     |
        # $PREFIX_LENGTH
        local prefix="${SINGLE_LINE:0:${PREFIX_LENGTH}}"
        local suffix="${SINGLE_LINE:${PREFIX_LENGTH}+2+${length}}"

        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${message}${CLEAR}"
        fi

        message="${prefix} ${message} ${suffix}"
    fi

    echo -e "${message}" >&2
}


function print_double_separator()
{
    local message="${1:-}"
    local isBold="${2:-}"

    if [[ -z "${message}" ]]; then
        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${DOUBLE_LINE}${CLEAR}"
        else
            message="${DOUBLE_LINE}"
        fi
    else
        # We want a line that looks like this
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ===== Foobar ====================...
        #
        # In above example $PREFIX_LENGTH is 5 as there are 5 '=' from
        # the start of the line to the string " Foobar ". Idea is to
        # splice string in two parts and insert the message " Foobar "
        # in such a way that the total length of the line is equal to
        # the length of the line without any message.
        #
        # This is done by first picking $PREFIX_LENGTH characters from
        # $DOUBLE_LINE. Then append the message with the ' ' before
        # and after the message. And finally start from the
        # corresponding index in the line and print everything till
        # the end.
        # 0 2 4 6 8 0 2 4 6 8 0 2 4 6 8 0 2 ...
        # ===== Foobar ====================...
        #     *        *
        #     |        |
        #     |        $PREFIX_LENGTH+1${#message}
        #     |
        # $PREFIX_LENGTH
        local prefix="${DOUBLE_LINE:0:${PREFIX_LENGTH}}"
        local suffix="${DOUBLE_LINE:${PREFIX_LENGTH}+2+${#message}}"

        if [[ "${isBold}" == "${BOLD}" ]]; then
            message="${BOLD}${message}${CLEAR}"
        fi

        message="${prefix} ${message} ${suffix}"
    fi

    echo -e "${message}" >&2
}


function print_dot()
{
    if [[ ! -v dotPrinted ]]; then
        # Create a new global variable named 'dotPrinted'. In Bash 4.2
        # there is a bug that causes 'decalre -g' to not create a
        # global variable. Instead use export as a workaround, it
        # should have benign side effects.
        export dotPrinted=""
    fi
    dotPrinted="y"
    echo -n "${BOLD}.${CLEAR}" 1>&2
}


# If wordy mode enabled, always print a newline
#
# If wordy mode is NOT enabled and a dot has been printed, then print
# a newline.
#
# Otherwise do not print any newline.
function print_newline_after_dot()
{
    if [[ "${WORDY:-}" == "y" ]]; then
        print_message
    else
        if [[ -v dotPrinted ]] && [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            print_message
        fi
    fi
}


# ONLY print a newline when wordy mode is NOT enabled and a dot has
# been printed.
function print_newline_only_after_dot()
{
    if [[ "${WORDY:-}" != "y" ]]; then
        if [[ -v dotPrinted ]] && [[ -n "${dotPrinted}" ]]; then
            dotPrinted=""
            print_message
        fi
    fi
}


# shellcheck disable=SC2120
function print_debug_enter()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[2]:-}():${BASH_LINENO[1]}"
        message+="-->${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


# shellcheck disable=SC2120
function print_debug_exit()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="<--${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug()
{
    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  ${*}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug_array()
{
    local arrayName="${1}"
    local prefix="${2:-}"

    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  "
        if [[ -n "${prefix}" ]]; then
            message+="${prefix}: "
        fi

        local arrayData=""
        arrayData=$(declare -p "${arrayName}")
        message+="${arrayData}"

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
    fi
}


function print_debug_indirect_array()
{
    local arrayName="${1}"
    local prefix="${2:-}"

    if [[ "${DEBUG:-}" == "y" ]]; then
        print_newline_only_after_dot

        local sourcefile=""
        if (( ${#BASH_SOURCE[@]} > 1 )); then
            sourcefile="${BASH_SOURCE[1]}"
        else
            sourcefile="(Shell environment)"
        fi

        local message="${BOLD}*** ${sourcefile}  "
        message+="${FUNCNAME[1]}():${BASH_LINENO[0]}${CLEAR}  "
        if [[ -n "${prefix}" ]]; then
            message+="${prefix}: "
        fi

        local arrayRef="${arrayName}[@]"
        local item=""
        for item in "${!arrayRef}"; do
            message+="${item}='${!item}'  "
        done

        if [[ -v COMP_TYPE ]]; then
            # Called from within TAB-completion engine; assumed name
            # is name of script file this function is called from
            # appended with '.txt' (extracted from $BASH_SOURCE[1]).
            # If that is not set, for instance when called from
            # completion function default name is
            # 'tab-completion.txt'.

            # Strip everything up to the last '/' in ${BASH_SOURCE[1]}
            local sourcefile="${sourcefile##*/}"

            # Create log-file name
            local logfile="${sourcefile:-tab-completion}.txt"

            # Default behavior is to append to file
            # "/tmp/${USER}/${logfile}"
            logfile="/tmp/${USER}/${logfile}"

            if [[ ! -d "/tmp/${USER}" ]]; then
                if [[ -f "/tmp/${USER}" ]]; then
                    # There already exist a file (not a directory)
                    # called $USER, in this case use $USER as a prefix
                    # for the log-file instead.
                    logfile="/tmp/${USER}_${logfile}"
                else
                    # Ensure log-file folder exist
                    mkdir -p "/tmp/${USER}"
                fi
            fi

            echo "${message}" >> "${logfile}"
        else
            # Ensure formatted text wraps nicely to terminal width and
            # redirect to stderr
            _frija_fold "${message}"

            #fold --spaces --width="${WIDTH:-80}"<<<"${message}" >&2
        fi
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


# This function return an expression that can be evaluated to reset
# GLOBIGNORE to its current value. That is, first call this function
# and save the result. Change GLOBIGNORE to whatever you want. And
# then evaluate the returned expression to reset GLOBIGNORE back to
# whatever it was before you changed it.
#
# This is a perfect match for a trap expression, where the trap will
# execute an expression when a certain event happens. For instance
# when a function call returns.
#
# Thus you can do
#
# function foo()
# {
#     trap "$(frija_restore_globignore_expression)" RETURN
#     GLOBIGNORE="foobar*"
#     # Do something
# }
#
# This will first save the current state of GLOBIGNORE via the trap,
# then change GLOBIGNORE and do something. When the function returns
# (for whatever reason) the value of GLOBIGNORE will be restored to
# its saved value.
function frija_restore_globignore_expression()
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


# This function return an expression that can be evaluated to reset
# extended globbing expression to its current value. That is, first
# call this function and save the result. Change extended globbing
# state to whatever you want. And then evaluate the returned
# expression to reset extended globbing state back to whatever it was
# before you changed it.
function frija_restore_extglob_expression()
{
    if shopt -q extglob; then
        # Set extended globbing in returned expression, since it was
        # set when this function was called
        echo shopt -s extglob
    else
        # Unset extended globbing in returned expression, since it was
        # unset when this function was called
        echo shopt -u extglob
    fi
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
        [[ "${uri}" =~ ^[a-z][a-z]*://.*/([^/]+)[.]git$ ]]

        print_debug_array "BASH_REMATCH"
        result="${BASH_REMATCH[1]}"
        if [[ -z "${result}" ]]; then
            local message="Unknown repo URI format: '${uri}'"
            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
        fi
    fi

    print_debug_exit "${result}"
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
# $2 (pathPrefix): Base path to use
# $3 (filePrefix): Glob for beginning of file name (can be empty)
# $4 (fileSuffix): Glob for end of file name (can be empty)
# $5 (globIgnore): Optional glob for files to ignore (default empty)
# $6 (filter): Optional filter (default empty);
#              One of $DIR_FILTER or $FILE_FILTER (or empty)
#
# NOTE: that globs containing whitespace characters must be treated
#       with extreme care! Ensure such characters are properly quoted
#       as the corresponding variables are expanded outside of strings
#       and are thus susceptible to word splitting!
function frija_list_files()
{
    # We want the expansion to expand before trap executes to be able
    # to restore it to its original value.
    #
    # TODO: Add more generic handling of cleanup hooks so we can have
    # multiple of them within a function but also in function chains
    # as well.
    #
    # shellcheck disable=SC2064
    trap "$(frija_restore_globignore_expression)" RETURN

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
    local filter="${6:-}"

    if [[ -n "${globIgnore}" ]]; then
        globIgnore+=":"
    fi

    # Exclude all files with file names matching the GLOBIGNORE glob
    # when doing globbing file name expansion. Furthermore also
    # exclude Emacs backup files.
    #
    # TODO: Can extended globs be used here?
    GLOBIGNORE="${globIgnore}*~*"

    print_debug "pathPrefix='${pathPrefix}'"
    print_debug "filePrefix='${filePrefix}'"
    print_debug "fileSuffix='${fileSuffix}'"

    if [[ -d "${pathPrefix}" ]]; then
        # Glob-expand path to get all files located in $pathPrefix and
        # that starts with $filePrefix and store result in $files
        print_debug "Glob expand pattern: '${pathPrefix}/${filePrefix}*${fileSuffix}'"

        # In order to be able to have glob patterns in $filePrefix and
        # $fileSuffix we *must* expand them outside of a string.
        # Otherwise the glob patterns would be interpreted literally
        # and that is not what we want. The drawback is that the
        # variables are susceptible for word splitting and thus must
        # quote spaces in the correct way so that the quotes survives
        # the expansion.
        #
        # shellcheck disable=SC2206
        files=("${pathPrefix}"/${filePrefix}*${fileSuffix})
        print_debug "Found: '${files[*]}'"

        # Here we intentionally expand $filePrefix and $fileSuffix
        # within a string since if the glob expansion did not match
        # any files it simply returns the literal string and thus we
        # have to check for that to catch this case.
        if [[ "${files[0]}" == "${pathPrefix}/${filePrefix}*${fileSuffix}" ]];
        then
            # There were no files matching the glob
            files=()
        else
            if [[ -n "${filter}" ]]; then
                for i in "${!files[@]}"; do
                    if [[ "${filter}" == "${FILE_FILTER}" ]] \
                           && [[ -d "${files[i]}" ]]; then
                        print_debug "Removed directory '${files[i]}' from list"
                        unset 'files[i]'
                    elif [[ "${filter}" == "${DIR_FILTER}" ]] \
                             && [[ ! -d "${files[i]}" ]]; then
                        print_debug "Removed file '${files[i]}' from list"
                        unset 'files[i]'
                    fi
                done
            fi

            # Remove $pathPrefix from each element in the $files array
            # TODO: Double '#' really needed here?
            files=("${files[@]##${pathPrefix}/}")
        fi
    fi

    # Remove 2 lines below when Bash 4.3 or newer is used.
    # shellcheck disable=SC2034
    _FRIJA_FILE_LIST=("${files[@]}")
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
