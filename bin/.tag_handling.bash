# Include core command line parsing support, common settings and
# utility functions.
#
# shellcheck source=./.core_preamble.bash
source "${REPO_TOOLS_HOME}/.core_preamble.bash"


# Generic pattern rule: All characters used in the pattern must be
# allowed to be used in filenames both in Linux *and* in Windows. Due
# to this the following characters must *not* be used (apart from
# rexexp and Glob pattern characters)
#
# Due to Windows:
# < (less than)
# > (greater than)
# : (colon - may work, intended for NTFS Alternate Data Streams; avoid!)
# / (forward slash)
# \ (backslash)
# | (vertical bar or pipe)
# ? (question mark)
# * (asterisk)




# -------------------------------------------------------------------
# Feature, locale, SHA, delta, branch, and sub-branch separator rules
# -------------------------------------------------------------------
#
# The initial character start a search tree with the property that all
# descendents must have single childs until it branches of.
#
# For instance, below variables define three search trees; they start
# with the '-', '_', and '+' characters respectively
#
#        ..'-'...           '_'       '+'
#      /  /  |   \           |
#    'r' '@' '%' '-'        '_'
#    /                     /  \
#  'c'                   '@' '%'
#
# This means that you may add for instance "-rd" or "-rdf" (bot not
# both) as additional patterns. However "-rca" is not allowed since
# "-rc" is already a pattern and it is a subset of "-rca". This means
# that it is not possible to differentiate between "-rcafool" and
# "-rcafool", i.e. "-rc" followed by "afool" and "-rca" followed by
# "fool". Thus the initial pattern sets the "rule of the land" for
# which variants may be created.
#
# NOTE: The initial '-' must be followed by at least one character
# which opens up for '-@' and '-%', but not '-@a' or '-%q' due to how
# the patterns are defined below.
RC_SEPARATOR="-rc"
LOCALE_SEPARATOR="--"
SHA_SEPARATOR="__@"
#DELTA_SEPARATOR="[+]"
#DELTA_SHA_SEPARATOR="-@"
#BRANCH_SEPARATOR="-%"
#SUBBRANCH_SEPARATOR="__%"


#FEATURE_PATTERN="([A-Z]+-[0-9]+)"
#BRANCH_NAME="(.*)?"
#BRANCH_PATTERN="(${BRANCH_SEPARATOR}${FEATURE_PATTERN}|"
#BRANCH_PATTERN+="${SUBBRANCH_SEPARATOR}${FEATURE_PATTERN}${BRANCH_NAME})?"


## For feature and sub-feature branches the corresponding tags uses the
## feature ID as a prefix for any tags created on such a branch. This
## makes them easy to single out and also to remove. To separate the
## feature ID from the rest it is enclosed by $FEATURE_BEGIN and
## $FEATURE_END.
#FEATURE_BEGIN="[(]"
## shellcheck disable=SC2034
#FEATURE_NUMBER_SEPARATOR="-"
#FEATURE_END="[)]__"

## For tags set on sub-feature branches the feature ID is prefixed with
## $SUB_FEATURE_INDICATOR.
#SUB_FEATURE_INDICATOR="[+]"

## Pattern for optional feature ID tag prefix.
#FEATURE_PREFIX_PATTERN="(${FEATURE_BEGIN}"
#FEATURE_PREFIX_PATTERN+="(${SUB_FEATURE_INDICATOR})${FEATURE_PATTERN}"
#FEATURE_PREFIX_PATTERN+="${FEATURE_END})?"


NATURAL_NUMBER="[1-9][0-9]*"


# Number of hex characters in a short-SHA gives indirectly the
# probability of two commits identified by such short-SHA values
# sharing the same initial sequence of that number of hex characters
# in the hash.
#
# What number of characters to choose for the short-SHA? The answer to
# this question in turn depend on A) number of expected commits
# between two versions and B) accepted probability for a collision
# after N commits.
#
# Assume we select M=5 hex digits which equals (4 bits per hex
# character) 4x5=20 bits and a probability of 0.1%; what number of
# random commit SHA-values need to be generated before the probability
# of 0.1% for a collision is reached?
#
# The answer is to evaluate this formula:
# (See https://en.wikipedia.org/wiki/Birthday_attack#Mathematics)
#
# SQRT(2*H*ln(1/(1-p))) where p=0.001 and H=2^20
#
# Which evaluates to 45 commit SHA-values, which is a bit low. On the
# other hand, increasing number of hex digits to 6 gives 259 commits
# which starts to feel a bit more comfortable.
#
# Increasing to 8 hex digits gives
#   2932 commits with a 0.100% collision probability
#    927 commits with a 0.010% collision probability
#    293 commits with a 0.001% collision probability
#
# which feels VERY comfortable. :)
#
# Hence SHORT_SHA_LENGTH is set to 8 which can be grouped as 4+4
# digits with a separator inbetween to enhance readability.
#
# NOTE: It _must_ be a multiple of $SHORT_SHA_SECTION_LENGTH.
SHORT_SHA_LENGTH=8

# $SHORT_SHA_LENGTH _must_ be a multiple of $SHORT_SHA_SECTION_LENGTH
SHORT_SHA_SECTION_LENGTH=4

HEX_DIGIT="[a-f0-9]"
SHORT_SHA_SECTION="${HEX_DIGIT}{${SHORT_SHA_SECTION_LENGTH}}"
SHORT_SHA_SEPARATOR_CHAR="."
SHORT_SHA_SEPARATOR="[${SHORT_SHA_SEPARATOR_CHAR}]"
SHORT_SHA="((${SHORT_SHA_SECTION})${SHORT_SHA_SEPARATOR}(${SHORT_SHA_SECTION}))"
# shellcheck disable=2034

# Used for checking if a string contain a hexadecimal value or not.
# That is outside of version tags that only use $SHORT_SHA format.
PLAIN_SHA="(${HEX_DIGIT}+)"

# Version Separator Character
VSC="."
# Version Separator
VS="[${VSC}]"

# A version field may be 0 (zero) but a version field may not start
# with any leading zeros. The only exception to this rule is when a
# version field contain zero which is represented by a single 0 (zero)
# digit. That is, both "0.0.0" and "1.0.0" are valid version numbers,
# but neither "00.000.0" nor "1.01.00".
VERSION_FIELD="(0|${NATURAL_NUMBER})"

# $VERSION_PATTERN is used for defining regexp matching version tags,
# but is also used for matching and extracting version fields outside
# of the tags. Hence the indices defined below.
VERSION_PATTERN="${VERSION_FIELD}${VS}${VERSION_FIELD}${VS}${VERSION_FIELD}"

# Indices for capture groups within just the $VERSION_PATTERN, used
# when there is a version outside of a tag.
#
# shellcheck disable=2034
MAJOR_VERSION_INDEX=1
# shellcheck disable=2034
MINOR_VERSION_INDEX=2
# shellcheck disable=2034
PATCH_VERSION_INDEX=3


################################################################################
# Main building blocks of a version tag. A generic version tag look like
#
# 11.22.33-rc44--AA_BBB_Cdef/ghij__@1a2b.3c4e
#
# And with regexp grouping parentheses added you get these capture groups
# with capture group ID numbers added below (for the most specific ones)
# ((11).(22).(33))(-rc(44)--((AA)_(BBB)_(Cdef/ghij)))__@((1a2b).(3c4e))
#   2    3    4        6      8    9     10               12     13
#                           \__________7___________/
# \______1_______/\________________5________________/   \_____11______/


# Indices for capture groups. Counting starts from left and increments
# for every left parentheses found, and index 0 (zero) represent
# everything matched. These numbers must be aligned with the indices
# above.
#
# shellcheck disable=2034
TAG_VERSION_INDEX=1
# shellcheck disable=2034
MAJOR_INDEX=2
# shellcheck disable=2034
MINOR_INDEX=3
# shellcheck disable=2034
PATCH_INDEX=4
# shellcheck disable=2034
RC_LOCALE_INDEX=5
# shellcheck disable=2034
RC_INDEX=6
# shellcheck disable=2034
LOCALE_INDEX=7
# shellcheck disable=2034
COUNTRY_INDET=8
# shellcheck disable=2034
SITE_INDEX=9
# shellcheck disable=2034
DOMAIN_INDEX=10
# shellcheck disable=2034
SHORT_SHA_INDEX=11
# shellcheck disable=2034
MOST_SIGNIFICANT_SHA=12
# shellcheck disable=2034
LEAST_SIGNIFICANT_SHA=13


TAG_SHA="${SHA_SEPARATOR}${SHORT_SHA}"


# A generic locale could look like
#
# ..._AA_BBB_Cdef/ghij_...
#
# Where
# 'AA' is the country code
# 'BBB' is site code
# 'Cdef/ghij' is domain.
#
# Note that the domain is terminated by '_' which incidently is also
# the first character of the $SHA_SEPARATOR. This is designed like
# this by intention.
LOCALE_FIELD_SEPARATOR="_"
COUNTRY_CODE="([A-Z][A-Z])"
SITE_CODE="([A-Z]+)"
DOMAIN="([^${LOCALE_FIELD_SEPARATOR}]+)"

# Locale field
LOCALE="${LOCALE_SEPARATOR}"
LOCALE+="(${COUNTRY_CODE}${LOCALE_FIELD_SEPARATOR}"
LOCALE+="${SITE_CODE}${LOCALE_FIELD_SEPARATOR}${DOMAIN})"

# Empty pattern used when there should explicitly not be any locale field,
# but still preserve parentheses index numbers.
EMPTY_LOCALE="(()()())"


# Release Candidate field; used as a building block when creating a
# regexp for matching explicit locales below, or a version without any
# locale or short-SHA
RC_FIELD="${RC_SEPARATOR}(${NATURAL_NUMBER})"

# Release Candidate field and locale
RC_AND_LOCALE="(${RC_FIELD}${LOCALE})"

# Empty pattern used when there should explicitly not be any RC field,
# but still preserve parentheses index numbers.
EMPTY_RC_AND_LOCALE="(()${EMPTY_LOCALE})"


# Add an extra capture group to $VERSION_PATTERN for the whole version
# consisting of all three fields as one big lump.
VERSION_NUMBER="(${VERSION_PATTERN})"

# Pattern useful for extracting the different components of a version
#
# shellcheck disable=SC2034
VERSION_RC_PATTERN="${VERSION_NUMBER}(${RC_FIELD})?"


# Regexp patterns for the different main cases where
#
# A) Version number is embellished with required release candidate and
#    locale; this is a development version in some generic locale
#
# B) Version number is NOT embellished with anything; this is a
#    released version by the information owner in its locale.
#
# Note: Both cases include SHA of commit tag is associated with.
TAG_VERSION_RC_LOCALE_SHA_PATTERN="${VERSION_NUMBER}${RC_AND_LOCALE}?${TAG_SHA}"
TAG_VERSION_SHA_PATTERN="${VERSION_NUMBER}${EMPTY_RC_AND_LOCALE}${TAG_SHA}"


# Building block used when constructing a regexp that matches an
# explicit locale field with a release candidate. Used together with
# $_SHA_PATTERN like this
#
# myPattern="${TAG_VERSION_RC_}${myLocaleRegexp}${_SHA_PATTERN}"
#
# Not that $myLocaleRegexp must follow some ground rules and that is
# that each of the three components must be single capture groups. The
# easiest way to ensure this is to use the function
# create_locale_regexp().
TAG_VERSION_RC_="${VERSION_NUMBER}(${RC_FIELD}${LOCALE_SEPARATOR}("


# Building block used when constructing a regexp that matches an
# explicit locale field. For how to use with $TAG_VERSION_RC, see
# comments for that variable.
_SHA_PATTERN="))?${TAG_SHA}"


################################################################################
# Main building blocks of a relative version tag. A generic version
# tag look like
#
# <tag>-55-g1a2b3c4-dirty
# or
# abcd1234-g1a2b3c4-dirty
#
# where the length of the short SHA following "-g" is dynamic just
# like in Git.
#
# And with regexp grouping parentheses added you get these capture groups
# with capture group ID numbers added below (for the most specific ones)
#
# ((<"version">)__@((1a2b).(3c4e)))((-(55))-g(g1a2b3c4)(-(dirty)))
#      2              4      5         9         10        12
#                  \______3_____/   \__8__/            \___11___/
# \_______________1_______________/\_____________7_______________/
#
# or
# (abcd1234)((-(55))-g(g1a2b3c4)(-(dirty)))
#      6        9         10        12
#            \__8__/            \___11___/
# \____1___/\_____________7_______________/
#
DELTA_COMMMIT_PATTERN="^((.+)${SHA_SEPARATOR}(${SHORT_SHA})|"
DELTA_COMMMIT_PATTERN+="(${HEX_DIGIT}+))"
DELTA_COMMMIT_PATTERN+="((-([0-9]+))?-g(${HEX_DIGIT}+)(-(.+))?)$"

# Indices for capture groups. Counting starts from left and increments
# for every left parentheses found, and index 0 (zero) represent
# everything matched. These numbers must be aligned with the indices
# above.
#
# shellcheck disable=2034
DELTA_COMMIT_TAG_INDEX=1
# shellcheck disable=2034
DELTA_COMMIT_VERSION_INDEX=2
# shellcheck disable=2034
DELTA_COMMIT_SHORT_SHA_INDEX=3
# shellcheck disable=2034
DELTA_COMMIT_MOST_SIGNIFICANT_SHA=4
# shellcheck disable=2034
DELTA_COMMIT_LEAST_SIGNIFICANT_SHA=5
# shellcheck disable=2034
DELTA_COMMIT_ANONYMOUS_SHA_INDEX=6
# shellcheck disable=2034
GIT_DELTA_DESCRIBE_INDEX=7
# shellcheck disable=2034
GIT_DELTA_INDEX=9
# shellcheck disable=2034
GIT_DELTA_SHORT_SHA_INDEX=10
# shellcheck disable=2034
GIT_DELTA_DIRTY_INDEX=12

## For tags set on feature and sub-feature branches they have a suffix
## detailing distance to a version tag (and which version tag the delta
## is against).
#TAG_VERSION_PATTERN="${VERSION_NUMBER}${RC_AND_LOCALE}?"
#DELTA_PATTERN="(${DELTA_SEPARATOR}([0-9]+)${DELTA_SHA_SEPARATOR}${PLAIN_SHA})?"
## shellcheck disable=2034
#TAG_FEATURE_PATTERN="${TAG_VERSION_PATTERN}${TAG_SHA}${DELTA_PATTERN}?"


# -----------------------------------------
# Feature, sub-feature, and non-feature tags
# -----------------------------------------
#
# This is a standard GLOB pattern that is used when listing tags to
# winnow down the set of tags to process. As it is a POSIX GLOB it is
# far from perfect; it will select all tags that basically starts
# three digits separated by anything followed by a '.'. The last digit
# can be followed by anything (for instance RC and locale) and ends
# with $SHA_SEPARATOR followed by eight lowercase hex-digits separated
# in two groups of four by a single '.'.
TAG_GLOB_PATTERN="[0-9]*.[0-9]*.[0-9]*${SHA_SEPARATOR}"
TAG_GLOB_PATTERN+="[0-9a-f][0-9a-f][0-9a-f][0-9a-f]."
TAG_GLOB_PATTERN+="[0-9a-f][0-9a-f][0-9a-f][0-9a-f]"


# shellcheck disable=2034
PLAIN_SHA_INDEX=1


NEW_VERSION=""
STEP_MAJOR="Major"
STEP_MINOR="Minor"
STEP_PATCH="Patch"
STEP_RC="RC"
MAKE_RELEASE="Release"
MAKE_INITIAL_VERSION="Initial"


# Supported VCS types
#
# shellcheck disable=SC2034
VCS_GIT="Git"

# Marker indicating if given argument is to be interpreted as a URI or
# a normal file path in the local file system
#
# shellcheck disable=SC2034
REMOTE="Remote"
# shellcheck disable=SC2034
LOCAL="Local"


# Used when selecting sorting order for listed tags
SORT_ASCENDING="ascending"
SORT_DESCENDING="descending"


function git_translate_branchType()
{
    print_debug_enter
    local commitType="${1}"

    local result=""

    case "${commitType}" in
        "${_FRIJA_FEATURE}")
            result="feature"
            ;;
        "${_FRIJA_DEVELOP}")
            result="develop"
            ;;
        "${_FRIJA_RELEASE}")
            result="master"
            ;;
        *)
            local message="Unknown commit type '${commitType}'"
            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
            ;;
    esac

    print_debug_exit "${result}"
    echo "${result}"
}


# Translate from $_FRIJA_FEATURE/$_FRIJA_DEVELOP/$_FRIJA_RELEASE/$TAG
# to something that can be used within the referenced Git repo.
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is type, i.e. $_FRIJA_FEATURE/...
#
# Third parameter is the "commit identifier" and valid value range
# depend on type; see description for $_FRIJA_FEATURE/... above.
#
# Returns a commitish, for instance branch name. How to interpret the
# returned value depend on the given type (parameter two).
function git_translate_commitType()
{
    print_debug_enter
    local repopath="${1}"
    local commitType="${2}"
    local commitIdentifier="${3:-}"

    local message=""
    local result=""

    case "${commitType}" in
        "${_FRIJA_FEATURE}")
            if [[ -z "${commitIdentifier}" ]]; then
                message="Commit type '${commitType}' need to be combined "
                message+="with a commit identifier (e.g. branch prefix), but "
                message+="none was given."
                print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
            fi

            result=$(git_find_feature_branch "${repopath}" \
                                             "${commitIdentifier}")
            if [[ "${result}" == "feature/"* ]]; then
                message="${repopath}: Found branch\\n"
                message+="  ${BOLD}${result}${CLEAR}"
            else
                # No feature branch was found, fall back to either develop
                # or master. However $commitIdentifier is no longer valid
                # and thus HEAD on the branch will be selected below.
                message="${repopath}: No feature branch for feature "
                message+="${commitIdentifier} found; "
                message+="using '${result}' instead"
            fi
            print_message "${message}"
        ;;
        "${_FRIJA_DEVELOP}")
            local branch="develop"

            # Ensure target branch 'develop' exist in repo. If it does
            # not exist fall back to 'master', and if that branch does
            # not exist abort with an error.
            message=""
            if ! git -C "${repopath}" show-ref "${branch}" --quiet; then
                if ! git -C "${repopath}" show-ref "master" --quiet; then
                    message="Neither requested branch '${branch}' nor fallback "
                    message+="branch 'master' exist in '${reponame}', aborting."
                    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
                else
                    message="Requested branch '${branch}' does not exist, "
                    message+="falling back to branch 'master'."
                    print_warning "${message}"
                    branch="master"
                fi
            fi

            if [[ "${commitIdentifier}" == "${_FRIJA_LATEST}" ]]; then
                # Track HEAD on develop branch, i.e. "normal" branch checkout
                message="${repopath}: Switching to branch '${branch}'"
            elif [[ "${commitIdentifier}" == "${_FRIJA_VERSION}" ]]; then
                # Include release candidate versions; include also
                # locale specific versions and use strict locale
                # matching when searching for a valid tag reachable
                # from develop branch.
                result=$(latest_tag "${repopath}" "${branch}" "${MATCH_STRICT}")

                if [[ -z "${result}" ]]; then
                    result="${branch}"
                    message="${repopath}: Switching to branch '${result}' "
                    message+="since no valid version tag was found."
                else
                    message="${repopath}: Switching to tag '${result}' "
                    message+="on branch '${branch}'"
                fi
            fi
            ;;
        "${_FRIJA_RELEASE}")
            local branch="master"

            # Ensure target branch 'develop' exist in repo. If it does
            # not exist fall back to 'master', and if that branch does
            # not exist abort with an error.
            message=""
            if ! git -C "${repopath}" show-ref "${branch}" --quiet; then
                if ! git -C "${repopath}" show-ref "develop" --quiet; then
                    message="Neither requested branch '${branch}' nor fallback "
                    message+="branch 'develop' exist in '${reponame}', "
                    message+="aborting."
                    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
                else
                    message="Requested branch '${branch}' does not exist, "
                    message+="falling back to branch 'develop'."
                    print_warning "${message}"
                    branch="develop"
                fi
            fi

            if [[ "${commitIdentifier}" == "${_FRIJA_LATEST}" ]]; then
                # Track HEAD on master branch, i.e. "normal" branch checkout
                message="${repopath}: Switching to branch '${branch}'"
            elif [[ "${commitIdentifier}" == "${_FRIJA_VERSION}" ]]; then
                # Include NO release candidate versions in search;
                # only release versions when searching for a valid tag
                # reachable from master branch.
                result=$(latest_tag "${repopath}" \
                                    "${branch}" \
                                    "${MATCH_RELEASE}")

                if [[ -z "${result}" ]]; then
                    result="${branch}"
                    message="${repopath}: Switching to branch '${result}' "
                    message+="since no valid version tag was found."
                else
                    message="${repopath}: Switching to tag '${result}' "
                    message+="on branch '${branch}'"
                fi
            fi
            ;;
        "${_FRIJA_TAG}")
            result="${commitIdentifier}"
            if ! git -C "${repopath}" show-ref "${result}" --quiet; then
                message="Requested commitish '${result}' does not exist in "
                message+="'${reponame}', aborting."
                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
            ;;
        *)
            local message="Unknown commit type '${commitType}'"
            print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
            ;;
    esac

    print_debug_exit "${result}"
    echo "${result}"
}


# Return committer date for a given tag
function commit_committer_date()
{
    print_debug_enter
    local commitSha="{1:-HEAD}"
    local result=""

    result=$(git show -s --format="%cd" \
                 --date=format:"%Y-%m-%dT%H:%M:%S%z" \
                 "${commitSha}")

    print_debug_exit "${result}"
    echo "${result}"
}


# TODO: Update regexp; most likely not OK. Use already defined
# "constant" variables instead.
#
# FIXME: Not used
function commit_relative_id()
{
    print_debug_enter
    local commitSha="{1:-HEAD}"
    local result=""

    # git show -s --format="%ad" --date=format:"%Y-%m-%dT%H:%M:%S%z"
    #
    # FLTS-4452:2022-01-26T14:37:11+0100:@f560b4d(1.0.0-1_SE_TN_Gride@f0ab.401d-1)__lorum-ipsum-dolor-sit-amet-con

    local newestTag=""
    newestTag=$(find_newest_tag "y")

    print_debug "newestTag='${newestTag}'"
    local regex="^(.+${SHA_SEPARATOR}${SHORT_SHA})-(([0-9]+)-g([0-9a-f]+)(.*))$"
    if [[ "${newestTag}" =~ ${regex} ]]; then
        print_debug "Field #1='${BASH_REMATCH[1]}'"
        print_debug "Field #2='${BASH_REMATCH[2]}'"
        print_debug "Field #3='${BASH_REMATCH[3]}'"
        print_debug "Field #4='${BASH_REMATCH[4]}'"
        print_debug "Field #5='${BASH_REMATCH[5]}'"

        result="@${BASH_REMATCH[4]}(${BASH_REMATCH[1]}-${BASH_REMATCH[3]})"
        print_debug "result='${result}'"
    else
        result="@${newestTag}()"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Return a locale string for the release locale as used in a tag.
#
# NOTE: Any slashes used in the domain are removed from the resulting
# string. The reason is that slashes are not allowed in tag names.
function get_release_locale()
{
    print_debug_enter
    local result="${RELEASE_COUNTRY}"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="${RELEASE_SITE}"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="${RELEASE_DOMAIN////}"

    print_debug_exit "${result}"
    echo "${result}"
}


# Return a locale string for the development locale as used in a tag.
#
# NOTE: Any slashes used in the domain are removed from the resulting
# string. The reason is that slashes are not allowed in tag names.
function create_development_locale()
{
    print_debug_enter
    local result="${_FRIJA_DEVELOPMENT_COUNTRY}"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="${_FRIJA_DEVELOPMENT_SITE}"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="${_FRIJA_DEVELOPMENT_DOMAIN////}"

    print_debug_exit "${result}"
    echo "${result}"
}


# Create a regexp matching current development locale, used when
# searching for tags
function create_locale_regexp()
{
    print_debug_enter
    local result="(${_FRIJA_DEVELOPMENT_COUNTRY})"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="(${_FRIJA_DEVELOPMENT_SITE})"
    result+="${LOCALE_FIELD_SEPARATOR}"
    result+="(${_FRIJA_DEVELOPMENT_DOMAIN////})"

    print_debug_exit "${result}"
    echo "${result}"
}


# Used when creating a new tag
function create_locale_field()
{
    print_debug_enter
    local result=""

    if [[ "${RELEASE_COUNTRY}" == "${_FRIJA_DEVELOPMENT_COUNTRY}" ]] \
           && [[ "${RELEASE_SITE}" == "${_FRIJA_DEVELOPMENT_SITE}" ]] \
           && [[ "${RELEASE_DOMAIN}" == "${_FRIJA_DEVELOPMENT_DOMAIN}" ]];
    then
        result=""
    else
        result="${LOCALE_SEPARATOR}"
        result+=$(create_development_locale)
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Create a version for use in a tag. When given version is x.y.z.0
# then it represents a released version and an initial release
# candidate version should be created stepping RC-field from 0 (zero)
# to 1 (one). Furhtermore $stepCommand should tell which of the major,
# minor, or patch fields to step at the same time.
#
# After release candidate has reached 1 (one) then there are only two
# stepping commands available; $NEW_VERSION and $STEP_RC, the other
# commands $STEP_MAJOR, $STEP_MINOR, and $STEP_PATCH will cause an
# error since you are not allowed to use a release candidate as a
# baseline for a new release candidate.
function create_version()
{
    print_debug_enter
    local stepCommand="${1}"
    declare -i major=${2}
    declare -i minor=${3}
    declare -i patch=${4}
    declare -i rc=${5:-0}

    local result=""

    print_debug "Major=${major}"
    print_debug "Minor=${minor}"
    print_debug "Patch=${patch}"
    print_debug "RC=${rc}"

    local message=""
    declare -i exitCode=$_FRIJA_EXIT_OK

    case "${stepCommand}" in
        "${NEW_VERSION}")
            if (( rc > 0 )); then
                result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}1"
                print_debug "result='${result}'"
            else
                message="A new release version may only be based on an "
                message+="existing release candidate version. It is not "
                message+="possible to create a new release version from "
                message+="${major}${VSC}${minor}${VSC}${patch}, aborting."
                exitCode=$_FRIJA_EXIT_CMD_LINE_PROBLEMS
            fi
            ;;
        "${STEP_MAJOR}")
            declare -i nMajor=$((major+1))
            if (( rc == 0 )); then
                result="${nMajor}${VSC}0${VSC}0${RC_SEPARATOR}1"
            else
                message="Illegal operation to create new version\\n"
                message+="${BOLD}${UNDERLINE_ON}${nMajor}${CLEAR}${VSC}${minor}"
                message+="${VSC}${patch}${RC_SEPARATOR}"
                message+="${BOLD}${UNDERLINE_ON}1${CLEAR}\\n"
                message+="when\\n"
                message+="${BOLD}${UNDERLINE_ON}${major}${CLEAR}"
                message+="${VSC}${minor}${VSC}${patch}"
                message+="${RC_SEPARATOR}${BOLD}${UNDERLINE_ON}${rc}${CLEAR}\\n"
                message+="already exist, aborting."
                exitCode=$_FRIJA_EXIT_OTHER_PROBLEM
            fi
            ;;
        "${STEP_MINOR}")
            declare -i nMinor=$((minor+1))
            if (( rc == 0 )); then
                result="${major}${VSC}${nMinor}${VSC}0${RC_SEPARATOR}1"
            else
                message="Illegal operation to create new version\\n"
                message+="${major}${VSC}${BOLD}${UNDERLINE_ON}${nMinor}${CLEAR}"
                message+="${VSC}${patch}${RC_SEPARATOR}"
                message+="${BOLD}${UNDERLINE_ON}1${CLEAR}\\n"
                message+="when\\n"
                message+="${major}${VSC}${BOLD}${UNDERLINE_ON}${minor}${CLEAR}"
                message+="${VSC}${patch}"
                message+="${RC_SEPARATOR}${BOLD}${UNDERLINE_ON}${rc}${CLEAR}\\n"
                message+="already exist, aborting."
                exitCode=$_FRIJA_EXIT_OTHER_PROBLEM
            fi
            ;;
        "${STEP_PATCH}")
            declare -i nPatch=$((patch+1))
            if (( rc == 0 )); then
                result="${major}${VSC}${minor}${VSC}${nPatch}${RC_SEPARATOR}1"
            else
                message="Illegal operation to create new version\\n"
                message+="${major}${VSC}${minor}${VSC}"
                message+="${BOLD}${UNDERLINE_ON}${nPatch}${CLEAR}"
                message+="${RC_SEPARATOR}${BOLD}${UNDERLINE_ON}1${CLEAR}\\n"
                message+="when\\n"
                message+="${major}${VSC}${minor}${VSC}"
                message+="${BOLD}${UNDERLINE_ON}${patch}${CLEAR}"
                message+="${RC_SEPARATOR}${BOLD}${UNDERLINE_ON}${rc}${CLEAR}\\n"
                message+="already exist, aborting."
                exitCode=$_FRIJA_EXIT_OTHER_PROBLEM
            fi
            ;;
        "${STEP_RC}")
            declare -i nRc=$((rc+1))
            result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}${nRc}"
            ;;
        "${MAKE_RELEASE}")
            if (( rc > 0 )); then
                result="${major}${VSC}${minor}${VSC}${patch}"
            else
                message="Illegal operation to create a new release version "
                message+="from ${BOLD}an already existing${CLEAR} release "
                message+="version ${major}${VSC}${minor}${VSC}${patch}, "
                message+="aborting."
                exitCode=$_FRIJA_EXIT_OTHER_PROBLEM
            fi
            ;;
        "${MAKE_INITIAL_VERSION}")
            # Can not validate anything here, trust the caller knows
            # what it is doing
            result="${major}${VSC}${minor}${VSC}${patch}"
            ;;
        *)
            message="Unknown version stepping command '${stepCommand}'; "
            message+="allowed value is one of { NEW_VERSION, STEP_MAJOR, "
            message+="STEP_MINOR, STEP_PATCH, MAKE_RELEASE }, aborting."
            exitCode=$_FRIJA_EXIT_INTERNAL_ERROR
            ;;
    esac

    if (( exitCode != _FRIJA_EXIT_OK )); then
        print_error "${message}" $exitCode
    else
        print_debug "result='${result}'"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Create a tag name with appropriate separators from the given fields.
# That is a version field, a SHA value, and an optional locale.
#
#
# First parameter is path to repo where the tag is supposed to end up.
# SHA value used in crated tag name is obtained from this repo.
#
# Second parameter is a version field is assumed to be preformatted
# using function create_version().
#
# Third (optional) parameter if given is assumed to be preformatted
# and prefixed with the apropriate separator. This is the case if the
# function create_locale_field() or create_development_locale() is
# used.
function create_tag_name()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local version="${2}"
    local locale="${3:-}"

    local result="${version}"
    if [[ -n "${locale}" ]]; then
        print_debug "Appending '${locale}' to '${version}'"
        result+="${LOCALE_SEPARATOR}${locale}"
    fi

    local shortSha=""
    shortSha=$(get_short_sha "${repopath}")
    shortSha=$(shrinkwrap_short_sha "${shortSha}")

    result+="${SHA_SEPARATOR}${shortSha}"

    print_debug_exit "'${result}'"
    echo "${result}"
}


# Insert a $SHORT_SHA_SEPARATOR_CHAR after every $SHORT_SHA_SECTION in
# the given short SHA value.
function shrinkwrap_short_sha()
{
    print_debug_enter
    local shortSha="${1}"
    local result=""

    # Match a string starting with $SHORT_SHA_SECTION followed by zero
    # or more sequences of $SHORT_SHA_SEPARATOR_CHAR followed by
    # $SHORT_SHA_SECTION.
    #
    # For instance if
    #  $SHORT_SHA_SECTION matches 4 hex digits
    # then
    #  abcd
    #  abcdabcd
    #  abcdabcdabcd
    #  ...
    # matches the regex below
    if [[ "${shortSha}" =~ ^(${SHORT_SHA_SECTION})((${SHORT_SHA_SECTION})*)$ ]]; then
        result="${BASH_REMATCH[1]}"
        shortSha="${BASH_REMATCH[2]}"

        while [[ -n "${shortSha}" ]]; do
            [[ "${shortSha}" =~ ^(${SHORT_SHA_SECTION})((${SHORT_SHA_SECTION})*)$ ]]
            result="${result}${SHORT_SHA_SEPARATOR_CHAR}${BASH_REMATCH[1]}"
            shortSha="${BASH_REMATCH[2]-}"
        done
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Remove all occurrences of short SHA separator
function unwrap_short_sha()
{
    print_debug_enter
    local shortSha="${1}"
    local result=""

    # Ensure given short SHA value is in the correct format, that is if
    #  $SHORT_SHA_SECTION matches 4 hex digits
    #  $SHORT_SHA_SEPARATOR_CHAR is '.'
    # then
    #  abcd
    #  abcd.abcd
    #  abcd.abcd.abcd
    #  ...
    # matches the regex below
    if [[ "${shortSha}" =~ ^${SHORT_SHA}$ ]]; then
        # Remove all occurrences of $SHORT_SHA_SEPARATOR
        result="${shortSha/${SHORT_SHA_SEPARATOR_CHAR}/}"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


function get_short_sha()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local gitObject="${2:-HEAD}"

    print_debug "Running command 'git -C \"${repopath}\" rev-parse --short=\"${SHORT_SHA_LENGTH}\" \"${gitObject}\"'"

    local sha=""
    sha=$(git -C "${repopath}" \
              rev-parse --short="${SHORT_SHA_LENGTH}" "${gitObject}")

    print_debug_exit "${sha}"
    echo "${sha}"
}


# Ensure SHA in tag matches commit tag points to.
function validate_tag()
{
    print_debug_enter "${@}"
    local repopath="${1}"
    local tag="${2}"
    local continueOnMismatch="${3-}"

    local sha=""
    declare -i result=0

    sha=$(get_short_sha "${repopath}" "${tag}")
    if [[ "${DEBUG}" == "y" ]]; then
        print_debug "sha='${sha}'"
    fi

    local extractedSha=""
    print_debug "Testing if '${tag}'"
    print_debug "matches '${TAG_VERSION_RC_LOCALE_SHA_PATTERN}'"
    if [[ "${tag}" =~ ^${TAG_VERSION_RC_LOCALE_SHA_PATTERN}$ ]]; then
        print_debug "'${tag}' matches"
        # SHA value is in last catch group in regex
        extractedSha="${BASH_REMATCH[${SHORT_SHA_INDEX}]}"
        print_debug "extractedSha='${extractedSha}'"
        extractedSha=$(unwrap_short_sha "${extractedSha}")

        if [[ "${extractedSha}" != "${sha}" ]]; then
            local message="Error: Tag '${tag}' points to wrong SHA: '${sha}'."
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    elif [[ "${continueOnMismatch}" == "y" ]]; then
        print_debug "'${tag}' did NOT match '${sha}', continue with error code"
        # Signal that something went wrong instead of printing an
        # error message and aborting the script.
        result=$_FRIJA_EXIT_OTHER_PROBLEM
    else
        local message="Error: Can't extract SHA from tag '${tag}'."
        print_debug "'${tag}' did NOT match, error '${message}'"
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug_exit "${result}"
    # This sets the exit status of the function which is different
    # from the returned value (via an echo). If we on the other hand
    # called the exit function then the whole script would have
    # terminated.
    return ${result}
}


# Determine what a commitish is within a repo.
function git_determine_ref_type()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local ref="${2}"

    local result="unknown"

    # Precedence in Git when resolving what a ref is seems to be first
    # check if it is a branch, then tag, and finally SHA. Use same
    # order here.
    if git -C "${repopath}" show-ref --quiet \
           --verify "refs/heads/${ref}" 2>/dev/null; then
        result="branch"
    elif git -C "${repopath}" show-ref --quiet \
           --verify "refs/tags/${ref}" 2>/dev/null; then
        result="tag"
    elif git -C "${repopath}" show-ref --quiet \
           --verify "refs/remote/${ref}" 2>/dev/null; then
        result="remote"
    elif git -C "${repopath}" show-ref \
           --verify "${ref}^{commit}" >/dev/null 2>&1; then
        result="hash"
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


# Get version tag pointing to given commit. If multiple version tags
# points to the commit, select the one with the highest version.
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is commitish (branch or commit) to start search from
#
# Third parameter control what is included in search; $MATCH_RELEASE,
# $MATCH_LENIENT, or $MATCH_STRICT; (default $MATCH_LENIENT)
#
# Return either a tag or an empty string if no tag could be found.
#
# TODO: Expand MATCH_RELEASE, MATCH_STRICT, and MATCH_LENIENT to
#       MATCH_RELEASE, MATCH_STRICT, MATCH_LENIENT, and MATCH_ALL.
#       Where MATCH_STRICT selects only release versions and locale
#       versions matching current locale, MATCH_LENIENT also include
#       the locale of the owner of the repo, and finally MATCH_ALL
#       includes all locales.
function git_filter_tag()
{
    print_debug_enter ""

    local repopath="${1}"
    local commitish="${2}"
    local matchingType="${3:-}"
    local noFallback="${4:-}"

    print_debug "repopath='${repopath}'"
    print_debug "commitish='${commitish}'"
    print_debug "matchingType='${matchingType}'"
    print_debug "noFallback='${noFallback}'"

    if [[ -n "${matchingType}" ]]; then
        ensure_value_in_enum "${matchingType}" \
                             ${_FRIJA_EXIT_INTERNAL_ERROR} \
                             $MATCH_RELEASE \
                             $MATCH_LENIENT \
                             $MATCH_STRICT
    fi

    # Get version tags sorted IN REVERSE ORDER, that is highest version first
    declare -a tagList
    git_version_tags "${repopath}" "tagList" \
                     "${commitish}" \
                     "${SORT_DESCENDING}" \
                     "${commitish}"
    print_debug_array "tagList"

    # Get a regexp expression used for filtering tags when iterating
    # over the $tagList array
    local regexpFilter=""
    regexpFilter=$(get_version_tag_regexp "${matchingType}")

    print_debug "Using regexpFilter='${regexpFilter}'"

    # Iterate over the returned list (that is sorted IN REVERSE ORDER
    # due to $SORT_DESCENDING) and find the first tag that matches
    # $regexpFilter. When a match is found, this is the version tag
    # that represent the highest version number closest to the
    # requirements, for instance may neither contain a release
    # candidate version nor a locale.
    #
    # If we on the other hand allow release candidate versions, then
    # if no non-release-candidate versions exists for the highest
    # version then the release-candidate with the highest candidate
    # number is selected.
    #
    # This behavior is due to the reverse sorting of the list.
    local versionTag=""
    print_debug "Found ${#tagList[@]} tags."
    if [[ "${#tagList[@]}" -gt 0 ]]; then
        local extractedSha=""

        for tag in "${tagList[@]}"; do
            if [[ "${tag}" =~ ^${TAG_VERSION_RC_LOCALE_SHA_PATTERN}$ ]]; then
                validate_tag "${repopath}" "${tag}"
                versionTag="${tag}"
                break
            fi
        done
    fi

    print_debug_exit "${versionTag}"
    echo "${versionTag}"
}


# Internal helper function to get tags sorted correctly. Git is
# unfortunately unable to sort on subgroups when sorting the tags.
# Fortunately it is relatively easy to add an extra layer that does
# the needed rearrangement to achive this.
#
# This function takes no arguments and reads from standard in and
# sends the rearranged lines to stdout.
#
#
# That is, go from below     -->     to below
#
# 1.2.3                              1.2.3
# 1.2.4-rc1--AA_AAA_Abcde            1.2.4-rc1--AA_AAA_Abcde
# 1.2.4-rc1--BB_BBB_Fghij            1.2.4-rc2--AA_AAA_Abcde
# 1.2.4-rc1--CC_CCC_Klmno            1.2.4-rc3--AA_AAA_Abcde
# 1.2.4-rc2--AA_AAA_Abcde            1.2.4-rc1--BB_BBB_Fghij
# 1.2.4-rc2--BB_BBB_Fghij            1.2.4-rc2--BB_BBB_Fghij
# 1.2.4-rc3--AA_AAA_Abcde            1.2.4-rc1--CC_CCC_Klmno
# 1.2.4                              1.2.4
# 1.3.0-rc1--AA_AAA_Abcde            1.3.0-rc1--AA_AAA_Abcde
# 1.3.0-rc1--BB_BBB_Fghij            1.3.0-rc2--AA_AAA_Abcde
# 1.3.0-rc2--AA_AAA_Abcde            1.3.0-rc1--BB_BBB_Fghij
# 1.3.0                              1.3.0
# ...                                ...
#
function __frija_sort_on_locale()
{
    declare -a sortedLocales=()

    local localeArray=""
    local localeRef=""

    # The array $sortedLocales keep all different locales we have
    # found between two release tags. The different locales appears in
    # sorted order for each indiviudal version. What we have to do is
    # store them in separate buckets and then empty those buckets in
    # the correct order (which happens to be the same order they were
    # found).
    #
    while read -r line; do
        # Ensure that read tag matches our regexp and at the same time
        # set up capture groups for the different parts of the tag
        if [[ "${line}" =~ ^${TAG_VERSION_RC_LOCALE_SHA_PATTERN} ]]; then
            # Extract the locale field from the tag and ensure that it
            # can be used as a Bash variable name (replacing any '-'
            # with '_'); Git tag names themselves are pretty
            # restricted with what characters are allowed thus we are
            # on the safe side here.
            local foundLocale="${BASH_REMATCH[${LOCALE_INDEX}]//-/_}"

            if [[ -z "${foundLocale}" ]]; then
                # Tag did NOT contain a locale portion which means
                # that it is a release tag

                # First print any release candidates
                if (( ${#sortedLocales[@]} > 0 )); then
                    # If we have found any release candidates before
                    # reaching this point iterate over them
                    local array=""
                    for array in "${sortedLocales[@]}"; do
                        local arrayRef="${array}[@]"
                        for item in "${!arrayRef}"; do
                            echo "${item}"
                        done

                        # Remove array so it can be recreated if needed
                        unset "${array}"
                    done
                    # Empty $sortedLocales so we can fill it with new
                    # locales
                    sortedLocales=()
                fi

                # And then print the released version
                echo "${line}"
            else
                # Due to how Bash 4.2 is implemented it is not
                # possible to use indirect array references in
                # combination with for instance calculating number of
                # items in the array, the only way is to go via eval.
                # In Bash 4.3 or newever this workaround is no longer
                # needed.
                localeArray="${foundLocale}_sorting"
                localeRef="${localeArray}[@]"
                local expression="(( \${#${localeRef}} > 0 ))"
                if [[ -v "${localeArray}" ]] && eval "${expression}" ; then
                    # The array already exist, so there is nothing to
                    # do. It is clearer to do it this way then trying
                    # to negate above if-expression.
                    :
                else
                    # Crate a new local array named after the locale...
                    declare -a "${localeArray}"

                    # ...and add it to $sortedLocales so we can get
                    # back to it later when either a release version
                    # is found or there is nothing more to read from
                    # stdin.
                    sortedLocales+=( "${localeArray}" )
                fi

                # Append $line to the locale array. In Bash 4.2 we
                # have to do it like this. In Bash 4.3 or newer it is
                # no longer needed to use this eval-based workaround.
                expression="${localeArray}+=( '${line}' )"
                eval "${expression}"
            fi
        fi
    done

    # If there are any remaining release candidates (last version was
    # not a release version) print them
    if (( ${#sortedLocales[@]} > 0 )); then
        local array=""
        for array in "${sortedLocales[@]}"; do
            local arrayRef="${array}[@]"
            for item in "${!arrayRef}"; do
                echo "${item}"
            done
        done
        sortedLocales=()
    fi
}


# Get all tags in a repo that matches the version tag formats
#
# 1.3.2__@1ad4.23f5
# 1.3.2--SE_TN_LKP__@1ad4.23f5
# 1.3.2-rc4711__@1ad4.23f5
# 1.3.2-rc4711--SE_TN_LKP__@1ad4.23f5
#
# where
# - "1.3.2" is an x.y.z version number
# - "1ad4.23f5" represent the short SHA 1ad423f5 for the commit tag point to
# - "SE_TN_LKP" is an example of Country, Site, and Domain
# - "rc4711" represent Release Candidate 4711 for version 1.3.2
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is name of local array variable to store result in
#
# Third parameter is commitish (branch or commit) to start search from
#
# Fourth parameter is sorting order; either $SORT_ASCENDING or $SORT_DESCENDING
#
# Fifth parameter is commit to focus on; Optional, empty string or no
# string means "consider all tags and not only those on a specific
# commit".
function git_version_tags()
{
    print_debug_enter

    local repopath="${1}"
    local array="${2}"
    local commitish="${3}"
    local order="${4}"
    local commit="${5:-}"

    if [[ -z "${array}" ]]; then
        message="Array name (second parameter) must not be an empty string"
        print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
    fi

    if [[ -z "${commitish}" ]]; then
        message="Commitish (third parameter) must not be an empty string"
        print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
    fi

    print_debug "repopath='${repopath}'"
    print_debug "array='${array}'"
    print_debug "commitish='${commitish}'"
    print_debug "commit='${commit}'"

    if [[ "${order}" == "${SORT_DESCENDING}" ]]; then
        # Set order to '-' as this indicates reverse sort order
        order="-"
    elif [[ "${order}" == "${SORT_ASCENDING}" ]]; then
        # Forward sorting order is default, thus set to empty string
        order=""
    else
        local message="Unsupported sorting order argument, '${order}'."
        print_error "${message}" $_FRIJA_EXIT_INTERNAL_ERROR
    fi

    local pointsAt=""
    if [[ -n "${commit}" ]]; then
        # Ensure we select only commit given in $commit
        pointsAt="--points-at ${commit}"
        print_debug "pointsAt='${pointsAt}'"
    fi

    if [[ -z "${repopath}" ]]; then
        repopath="."
    else
        # Instruct Git to change directory before executing the
        # command.
        repopath="${repopath}"
    fi
    print_debug "repopath='${repopath}'"


    # IF $pointsAt is non-empty then only operate on that commit,
    # otherwise operate on ALL commits.
    #
    # IF repopath is non-empty then switch to the folder before
    # executing the command.
    #
    # Get all tags that match $TAG_GLOB_PATTERN as a list that is
    # sorted in order (due to "v:refname") as if the tags are version
    # numbers (e.g. x.y.z version numbers) in a "single column" (one
    # per row). Also recognize that suffix $RC_SEPARATOR might occurr
    # as well as $LOCALE_SEPARATOR and $DELTA_SEPARATOR, and sort on
    # those to (in that order) if they exist.
    #
    # Tag names returned by Git command are stored in the named array $array.
    mapfile -t "${array}" < <(git -C "${repopath}" \
                                  -c "versionsort.suffix=${RC_SEPARATOR}" \
                                  -c "versionsort.suffix=${LOCALE_SEPARATOR}" \
                                  tag --merged "${commitish}" \
                                  --sort="${order}"v:refname \
                                  --no-column \
                                  "${pointsAt}" \
                                  "${TAG_GLOB_PATTERN}" | \
                                  __frija_sort_on_locale)
    print_debug_array "array"
    print_debug_exit
}


# This is a helper function for creation of regexp filter to use when
# iterating over version tags. The returned regexp is used for both
# selecting which tag formats to include as well as for extracting
# different fields of the version tag.
#
# The supported formats are
#
#   - $MATCH_RELEASE which matches only "release" versions; that is
#     versions with neither release candidate value nor locale, for
#     instance "1.2.3__@1a2b.3c4d"
#
#   - $MATCH_LENIENT which matches *both* "release" and "develop"
#     versions regardless of locale; that is any valid locale is
#     accepted but it must be in conjunction with a release candidate,
#     for instance "1.2.3-rc4--AA_BB_Cdef/ghij__@1a2b.3c4d" but not
#     "1.2.3-rc4__@1a2b.3c4d"
#
#   - $MATCH_STRICT which is a variant of $LENIENT where the locale
#     part of the regexp is replaced with something that matches
#     exactly the current $_FRIJA_DEVELOPMENT_LOCALE
#
#
# First parameter control kind of regexp pattern returned; (default
# $MATCH_LENIENT)
#
# Return value: A regular expression filter to be used when filtering
# version tags.
function get_version_tag_regexp()
{
    print_debug_enter "${@}"

    local matchingType="${1:-${MATCH_LENIENT}}"
    print_debug "matchingType='${matchingType}'"

    local regexpFilter=""

    case "${matchingType}" in
        "${MATCH_RELEASE}")
            print_debug "Include only version; *NO* RC nor locale."
            regexpFilter="${TAG_VERSION_SHA_PATTERN}"
            ;;
        "${MATCH_LENIENT}")
            print_debug "Include RC combined with generic match for locale."
            regexpFilter="${TAG_VERSION_RC_LOCALE_SHA_PATTERN}"
            ;;
        "${MATCH_STRICT}")
            local localeRegexp=""
            localeRegexp=$(create_locale_regexp)

            print_debug "Include RC combined with STRICT match for locale."
            print_debug "localeRegexp='${localeRegexp}'"

            regexpFilter="${TAG_VERSION_RC_}${localeRegexp}${_SHA_PATTERN}"
            ;;
        *)
        ;;
    esac


    print_debug_exit "Returning regexpFilter='${regexpFilter}'"
    echo "${regexpFilter}"
}


# Get latest tag (highest version tag) in a repo that matches the
# version tag formats
#
# 1.3.2__@1ad4.23f5
# 1.3.2-rc4711__SE_TN_LKP__@1ad4.23f5
#
# where
# - "1.3.2" is an x.y.z version number
# - "1ad4.23f5" represent the short SHA 1ad423f5 for the commit tag point to
# - "SE_TN_LKP" is an example of Country, Site, and Domain
# - "rc4711" represent Release Candidate 4711 for version 1.3.2
#
# It is possible to restrict the search to tags that does not include
# Release Candidate (RC) numbers and locale. Furthermore it is also
# possible to request a strict or lenient (non-strict) match for the
# locale.
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is commitish (branch or commit) to start search from
#
# Third parameter control what is included in search; $MATCH_RELEASE,
# $MATCH_LENIENT, or $MATCH_STRICT; (default $MATCH_LENIENT)
#
# Fourth parameter is commit to get tags for. If not given than all
# reachable commits are searched for tags.
#
# Return value: If a tag is found then it is returned.
function latest_tag()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local commitish="${2}"
    local matchingType="${3:-}"
    local commit="${4:-}"

    print_debug "repopath='${repopath}'"
    print_debug "commitish='${commitish}'"
    print_debug "matchingType='${matchingType}'"
    print_debug "commit='${commit}'"

    # Get version tags sorted IN REVERSE ORDER
    declare -a tagList
    git_version_tags "${repopath}" "tagList" "${commitish}" \
                     "${SORT_DESCENDING}" \
                     "${commit}"
    print_debug_array "tagList"

    # Get a regexp expression used for filtering tags when iterating
    # over the $tagList array
    local regexpFilter=""
    regexpFilter=$(get_version_tag_regexp "${matchingType}")

    print_debug "Using regexpFilter='${regexpFilter}'"

    # Iterate over the returned list (that is sorted IN REVERSE ORDER)
    # and find the first tag that matches $regexpFilter. When a match
    # is found, this is the version tag that represent the highest
    # version number closest to the requirements, for instance may
    # neither contain a release candidate version nor a locale.
    #
    # If we on the other hand allow release candidate versions, then
    # if no non-release-candidate versions exists for the highest
    # version then the release-candidate with the highest candidate
    # number is selected.
    #
    # This behavior is due to the reverse sorting of the list.
    local versionTag=""
    print_debug "Found ${#tagList[@]} tags."
    if (( "${#tagList[@]}" > 0 )); then
        for tag in "${tagList[@]}"; do
            print_debug "Checking tag '${tag}'"
            if [[ "${tag}" =~ ^${regexpFilter}$ ]]; then
                print_debug "Tag '${tag}' matches, validating it..."
                validate_tag "${repopath}" "${tag}"
                print_debug "Tag '${tag}' is valid"

                versionTag="${tag}"
                break
            fi
        done
    fi

    print_debug_exit "'${versionTag}'"
    echo "${versionTag}"
}


# Extract version part of a version tag and return it to caller. If
# tag does not follow expected format an empty string is returned,
# otherwise the version part of the tag.
#
# For instance, if given tag is
# "11.22.33-rc44--AA_BBB_Cdef/ghij__@1a2b.3c4e" then the returned
# value is "11.22.23-rc44".
#
# On the other hand, if given tag is "11.22.33__@1a2b.3c4e" then the
# returned value is "11.22.23".
#
#
# First parameter is the tag to extract a version from
function extract_version()
{
    print_debug_enter "${@}"

    local tag="${1}"

    local result=""

    # Use predefined regexp to extract version part from a tag,
    # provided that it matches the regexp. Thus we also validate the
    # format of the tag at the same time as we extract the version
    # number.
    if [[ "${tag}" =~ ^${TAG_VERSION_RC_LOCALE_SHA_PATTERN}$ ]]; then
        result="${BASH_REMATCH[${TAG_VERSION_INDEX}]}"
        local rcValue="${BASH_REMATCH[${RC_INDEX}]}"
        if [[ -n "${rcValue}" ]]; then
            # Reconstruct what an RC field would look like in a tag
            # and append it to $result
            result+="${RC_SEPARATOR}${rcValue}"
        fi
    fi

    print_debug_exit "${result}"
    echo "${result}"
}


_FRIJA_NEWEST="newest"
_FRIJA_INHIBIT_PRINTOUTS="inhibit"

# List tags in a repo that matches the version tag formats
#
# 1.3.2__@1ad4.23f5
# 1.3.2-rc4711__SE_TN_LKP__@1ad4.23f5
#
# where
# - "1.3.2" is an x.y.z version number
# - "1ad4.23f5" represent the short SHA 1ad423f5 for the commit tag point to
# - "SE_TN_LKP" is an example of Country, Site, and Domain
# - "rc4711" represent Release Candidate 4711 for version 1.3.2
#
# It is possible to restrict the search to tags that does not include
# Release Candidate (RC) numbers and locale. Furthermore it is also
# possible to request a strict or lenient (non-strict) match for the
# locale.
#
# First parameter is path to repo; empty string assumes CWD is within Git repo
#
# Second parameter is commitish (branch or commit) to start search from
#
# Third parameter control what is included in search; $MATCH_RELEASE,
# $MATCH_LENIENT, or $MATCH_STRICT
#
# Fourth parameter is the sort order; $SORT_ASCENDING or $SORT_DESCENDING
#
# Fifth parameter is commit to get tags for. If not given than all
# reachable commits are searched for tags.
#
# Sixth parameter controls whether only the tag with highest version
# number should be returned or all tags for commit. If $_FRIJA_NEWEST
# is not given all matching tags for given commit are returned.
#
# Seventh parameter control if printouts are inhibited or not; if
# $_FRIJA_INHIBIT_PRINTOUTS is given printouts are inhibited.
function git_list_tags()
{
    print_debug_enter "${@}"

    local repopath="${1}"
    local commitish="${2}"
    local matchingType="${3}"
    local sortOrder="${4}"
    local commit="${5:-}"
    local newestOnly="${6:-}"
    local inhibitPrintouts="${7:-}"

    print_debug "repopath='${repopath}'"
    print_debug "commitish='${commitish}'"
    print_debug "matchingType='${matchingType}'"
    print_debug "commit='${commit}'"
    print_debug "newestOnly='${newestOnly}'"

    ensure_value_in_enum "${matchingType}" \
                         ${_FRIJA_EXIT_INTERNAL_ERROR} \
                         $MATCH_RELEASE \
                         $MATCH_LENIENT \
                         $MATCH_STRICT

    ensure_value_in_enum "${sortOrder}" \
                         ${_FRIJA_EXIT_INTERNAL_ERROR} \
                         "${SORT_ASCENDING}" \
                         "${SORT_DESCENDING}"

    if [[ -n "${newestOnly}" ]]; then
        ensure_value_in_enum "${newestOnly}" \
                             ${_FRIJA_EXIT_INTERNAL_ERROR} \
                             "${_FRIJA_NEWEST}"
    fi

    if [[ -n "${inhibitPrintouts}" ]]; then
        ensure_value_in_enum "${inhibitPrintouts}" \
                             ${_FRIJA_EXIT_INTERNAL_ERROR} \
                             "${_FRIJA_INHIBIT_PRINTOUTS}"
    fi


    # Get version tags sorted in either REVERSE ORDER or IN ORDER. In
    # the former case the highest version first comes first.
    declare -a tagList
    git_version_tags "${repopath}" "tagList" "${commitish}" "${sortOrder}" \
                     "${commit}"
    print_debug_array "tagList"

    # Get a regexp expression used for filtering tags when iterating
    # over the $tagList array
    local regexpFilter=""
    regexpFilter=$(get_version_tag_regexp "${matchingType}")

    print_debug "Using regexpFilter='${regexpFilter}'"

    local heading=""
    if [[ -z "${commit}" ]]; then
        heading="Tags reachable from '${commitish}' (${sortOrder} order)"
    else
        heading="Tags set on '${commit}' (${sortOrder} order)"
    fi

    if [[ -z "${inhibitPrintouts}" ]]; then
        print_separator "${heading}" "${BOLD}"
    fi

    # Iterate over the returned list (that is sorted in EITHER reverse
    # order OR in order) and find the first tag that matches
    # $regexpFilter. When a match is found, this is the version tag
    # that represent the highest (or lowest) version number closest to
    # the requirements, for instance may neither contain a release
    # candidate version nor a locale.
    #
    # If we on the other hand allow release candidate versions, then
    # if no non-release-candidate versions exists for the highest
    # version then the release-candidate with the highest candidate
    # number is selected.
    #
    # This behavior is due to the sorting of the list.
    print_debug "Found ${#tagList[@]} tags."
    if (( "${#tagList[@]}" > 0 )); then
        declare -a list=()
        if [[ -z "${newestOnly}" ]]; then
            # Copy all elements to array $list
            list=("${tagList[@]}")
        else
            # Copy only first element to array $list
            list=("${tagList[0]}")
        fi

        for tag in "${list[@]}"; do
            print_debug "Checking tag '${tag}'"
            if [[ "${tag}" =~ ^${regexpFilter}$ ]]; then
                print_debug "Tag '${tag}' matches, validating it..."
                validate_tag "${repopath}" "${tag}"
                print_debug "Tag '${tag}' is valid"

                if [[ -z "${inhibitPrintouts}" ]]; then
                    print_message "${tag}"
                fi
            fi
        done
    fi

    if [[ -z "${inhibitPrintouts}" ]]; then
        print_separator "${heading}" "${BOLD}"
    fi

    print_debug_exit
}


################################################################################
# Find first parent-or-self with a matching tag and if the commit has
# multiple tags version tags, select the one with the highest version
# number.

VERSION_GLOB="[0-9]*.[0-9]*.[0-9]*"
RC_GLOB="${RC_SEPARATOR}[1-9]*"
LOCALE_GLOB="${LOCALE_SEPARATOR}[A-Z][A-Z]_[A-Z]*_[-A-Za-z0-9._]*"
SHORT_SHA_GLOB="${SHA_SEPARATOR}"
SHORT_SHA_GLOB+="[0-9a-z][0-9a-z][0-9a-z][0-9a-z]."
SHORT_SHA_GLOB+="[0-9a-z][0-9a-z][0-9a-z][0-9a-z]"

# Return newest (in the sense of nearest commit with a tag) with
# highest version number.
#
# If no such tag exists, then the short SHA for the current commit is
# used instead.
#
# When first argument is set to "y" this means that in case of a match
# any delta to the tag is included in the returned value.
#
# FIXME: Not used
function git_find_newest_tag()
{
    print_debug_enter "${@}"
    local repopath="${1}"
    local includeDelta="${2:-}"
    local newestTag=""

    newestTag=$(git -C "${repopath}" \
                    describe --long --first-parent --tags \
                    --match "${VERSION_GLOB}${SHORT_SHA_GLOB}" \
                    --match "${VERSION_GLOB}${RC_GLOB}${SHORT_SHA_GLOB}" \
                    --match "${VERSION_GLOB}${RC_GLOB}${LOCALE_GLOB}${SHORT_SHA_GLOB}" \
                    --candidates=1000 --always --dirty)

    # Git describe reports back a string (if tag matching any of the globs
    # is found) following the format
    #
    # <TAG>-<SEQUENCE>-g<SHA>
    #
    # Where TAG is the content of the tag, SEQUENCE is number of commits
    # between a commit and tag, and SHA is the short SHA of a commit
    # (default commit is HEAD).
    local sha=""
    if [[ "${newestTag}" =~ ${DELTA_COMMMIT_PATTERN} ]]; then
        newestTag="${BASH_REMATCH[${DELTA_COMMIT_TAG_INDEX}]}"
        sha="${BASH_REMATCH[DELTA_COMMIT_SHORT_SHA_INDEX]}"
        local delta="${BASH_REMATCH[GIT_DELTA_SHORT_SHA_INDEX]}"

        if [[ -n "${sha}" ]]; then
            sha=$(unwrap_short_sha "${sha}")

            validate_tag "${repopath}" "${newestTag}" "y"
            if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
                newestTag=$(git_filter_tag "${newestTag}")

                if [[ -z "${newestTag}" ]]; then
                    newestTag=$(get_short_sha "${repopath}" HEAD)
                fi
                if [[ "${includeDelta}" == "y" ]]; then
                    newestTag="${newestTag}-${delta}"
                fi
            else
                # Found tag is not valid, fall back to plain SHA for commit
                newestTag=$(git -C "${repopath}" \
                                rev-parse --short="${SHORT_SHA_LENGTH}" HEAD)
            fi
        else
            # Restore $newestTag back to its value since no tag was found
            newestTag="${BASH_REMATCH[0]}"
        fi
    fi

    if [[ -z "${sha}" ]]; then
        # No tag found
        if [[ -n "${includeDelta}" ]]; then
            newestTag="@${newestTag}"
        else
            # Fall back to short-sha for HEAD
            newestTag=$(get_short_sha "${repopath}" HEAD)
        fi
    fi

    print_debug_exit "${newestTag}"
    echo "${newestTag}"
}


#  ################################################################################
#  # Get name of current branch (if it exists), otherwise we will just
#  # get "HEAD"
#  currentBranch=$(git rev-parse --abbrev-ref HEAD)
#
#  # Extract branch prefix and minimal part of label. That is, if it is
#  # the main issue branch it has a format similar to
#  #
#  # feature/ABCD-0123_issue_title
#  #
#  # And if it is a sub-branch it has a format similar to
#  #
#  # ABCD-0123/some_label_assigned_by_developer
#  #
#  # The idea here is to in the former case transform the branch name to
#  # something similar to "feature+ABCD-0123" and "ABCD-0123+some_label"
#  ISSUE_TAG="[A-Z]+-[0-9]+"
#  LABEL="[^/]+"
#  PREFIX="${LABEL}"
#  BRANCH_PATTERN="^(${PREFIX})/(${ISSUE_TAG}).*$"
#  SUB_BRANCH_PATTERN="^(${ISSUE_TAG})/(${LABEL}).*$"
#
#  if [[ "${currentBranch}" =~ ${BRANCH_PATTERN} ]]; then
#      prefix="${BASH_REMATCH[1]}"
#      label="${BASH_REMATCH[2]}"
#      currentBranch="${prefix}/${label}"
#  elif [[ "${currentBranch}" =~ ${SUB_BRANCH_PATTERN} ]]; then
#      prefix="${BASH_REMATCH[1]}"
#      label="${BASH_REMATCH[2]}"
#      currentBranch="${prefix}/${label}"
#  fi
#
#
#  ################################################################################
#  #Now get name of repo
#  reponame=""
#  reponame=$(git remote get-url origin)
#  reponame=$(basename "${reponame}" .git)
#
#
#  ################################################################################
#  # Timestamp is in UTC with difference to local time (instead of local
#  # time with difference to UTC). That is if you add the difference to
#  # the timestamp then you get local time.
#
#  secondsSinceEpoch=$(date +"%s")
#
#  # Finally create a timestamp
#  # -u : Use UTC
#  # %g : Last two digits of year of ISO week number
#  # %m : Month of year
#  # %d : Day of month
#  # %H : Hour (00..24)
#  # %M : Minute (00..59)
#  # %S : Second (00..59)
#  timestamp=""
#  timestamp=$(date --utc "--date=@${secondsSinceEpoch}" +"%g-%m-%d %H:%M.%S")
#
#  tzDelta=$(date "--date=@${secondsSinceEpoch}" +"%z")
#
#  # Create final timestamp
#  timestamp="${timestamp}Z${tzDelta}"
#
#
#  ################################################################################
#  # Finally create repo version ID string
#  repoId="${reponame} ${currentBranch} ${newestTag} ${timestamp}"
#
#  if [[ "${1:-}" == "" ]]; then
#      echo "${repoId}"
#  else
#      if hash cygpath 2>/dev/null; then
#          outputPath=$(cygpath --unix "{$1}")
#      else
#          outputPath="${1}"
#      fi
#
#      # Override noclobber option, that is when noclobber is on then
#      # Bash will refuse to overwrite a file during redirection unless
#      # you append a '|' to the redirection operator '>'.
#      echo "${repoId}" >| "${outputPath}"
#  fi
