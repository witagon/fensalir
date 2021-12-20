# Include core command line parsing support, common settings and
# utility functions.
#
# shellcheck source=./.core_preamble.bash
source "${METADATATOOLS_HOME}/.core_preamble.bash"


RC_SEPARATOR="-"
LOCATION_SEPARATOR="[+]"
SHA_SEPARATOR="__@"

NATURAL_NUMBER="[1-9][0-9]*"
VERSION_FIELD="(0|${NATURAL_NUMBER})"
RC_FIELD="(${NATURAL_NUMBER})"

COUNTRY_CODE="[A-Z][A-Z]"
SITE_CODE="[A-Z]+"
DOMAIN="[^_]+"
LOCATION="(${LOCATION_SEPARATOR}(${COUNTRY_CODE}_${SITE_CODE}_${DOMAIN}))"


# Number of hex characters gives indirectly the probability of two
# commits sharing the same initial sequence of that number of hex
# characters in the hash.
#
# What value to choose? This in turn depends on A) number of expected
# commits between two versions and B) accepted probability for a
# collision after N commits.
#
# Assume we select M=5 hex digits which equals (4 bits per hex
# character) 4x5=20 bits and a probability of 0.1%, what number of
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
# Hence SHORT_SHA_LENGTH is set to 8
# NOTE: It _must_ be a multiple of $SHORT_SHA_SECTION_LENGTH.
SHORT_SHA_LENGTH=8

# $SHORT_SHA_LENGTH _must_ be a multiple of $SHORT_SHA_SECTION_LENGTH
SHORT_SHA_SECTION_LENGTH=4

HEX_DIGIT="[a-f0-9]"
SHORT_SHA_SECTION="${HEX_DIGIT}{${SHORT_SHA_SECTION_LENGTH}}"
SHORT_SHA_SEPARATOR_CHAR="."
SHORT_SHA_SEPARATOR="[${SHORT_SHA_SEPARATOR_CHAR}]"
SHORT_SHA="${SHORT_SHA_SECTION}(${SHORT_SHA_SEPARATOR}${SHORT_SHA_SECTION})*"
# shellcheck disable=2034
PLAIN_SHA="(${HEX_DIGIT}+)"

VSC="."
VS="[${VSC}]"
TAG_VERSION="(${VERSION_FIELD}${VS}${VERSION_FIELD}${VS}${VERSION_FIELD}(${RC_SEPARATOR}${RC_FIELD}${LOCATION}?)?)"
TAG_SHA="${SHA_SEPARATOR}(${SHORT_SHA})"
VERSION_PATTERN="${TAG_VERSION}${TAG_SHA}"
# shellcheck disable=2034
TAG_OR_SHA_PATTERN="${TAG_VERSION}?${TAG_SHA}"

# Indices for capture groups. Counting starts from left and increments
# for every left parentheses found, and index 0 (zero) represents
# everything matched.
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
RC_INDEX=6
# shellcheck disable=2034
LOCATION_INDEX=8
# shellcheck disable=2034
SHORT_SHA_INDEX=9
# shellcheck disable=2034
PLAIN_SHA_INDEX=1

NEW_VERSION=""
STEP_MAJOR="major"
STEP_MINOR="minor"
STEP_PATCH="patch"
STEP_RC="rc"
MAKE_RELEASE="release"

# shellcheck disable=2034
RELEASE_COUNTRY="SE"
# shellcheck disable=2034
RELEASE_SITE="TN"
# shellcheck disable=2034
RELEASE_DOMAIN="Gride"


function create_version ()
{
    local stepCommand="${1}"
    declare -i major=${2}
    declare -i minor=${3}
    declare -i patch=${4}
    declare -i rc=${5-0}

    local result=""

    echo "    Major=${major}" >&2
    echo "    Minor=${minor}" >&2
    echo "    Patch=${patch}" >&2
    echo "       RC=${rc}" >&2

    case "${stepCommand}" in
        "${NEW_VERSION}")
            result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}1"
            echo "result='${result}'" >&2
            ;;
        "${STEP_MAJOR}")
            result="$(( major+1 ))${VSC}0${VSC}0${RC_SEPARATOR}1"
            echo "result='${result}'" >&2
            ;;
        "${STEP_MINOR}")
            result="${major}${VSC}$(( minor+1 ))${VSC}0${RC_SEPARATOR}1"
            echo "result='${result}'" >&2
            ;;
        "${STEP_PATCH}")
            result="${major}${VSC}${minor}${VSC}$(( patch+1 ))${RC_SEPARATOR}1"
            echo "result='${result}'" >&2
            ;;
        "${STEP_RC}")
            result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}$(( rc+1 ))"
            echo "result='${result}'" >&2
            ;;
        "${MAKE_RELEASE}")
            result="${major}${VSC}${minor}${VSC}${patch}"
            echo "result='${result}'" >&2
            ;;
        *)
            local message="Internal error, unknown version stepping command  version stepping command may only be one of NEW_VERSION, STEP_MAJOR, STEP_MINOR, or STEP_PATCH."
            print_error "${message}" 3
            ;;
    esac

    echo "${result}"
}


# Insert a $SHORT_SHA_SEPARATOR_CHAR after every $SHORT_SHA_SECTION in
# the given short SHA value.
function shrinkwrap_short_sha ()
{
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

    echo "${result}"
}


# Remove all occurrences of short SHA separator
function unwrap_short_sha ()
{
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

    echo "${result}"
}


# Ensure SHA in tag matches commit tag points to.
function validate_tag()
{
    local tag="${1}"
    local continueOnMismatch="${2-}"
    local sha=""
    declare -i result=0

    if [[ "${DEBUG}" == "y" ]]; then
        echo "*** $LINENO  Running command 'git rev-parse --short=\"${SHORT_SHA_LENGTH}\" \"${tag}\"'" >&2
    fi
    sha=$(git rev-parse --short="${SHORT_SHA_LENGTH}" "${tag}")
    if [[ "${DEBUG}" == "y" ]]; then
        echo "*** $LINENO  sha='${sha}'" >&2
    fi

    local extractedSha=""
    print_debug "Testing if '${tag}'" >&2
    print_debug "matches '${VERSION_PATTERN}'" >&2
    if [[ "${tag}" =~ ^${VERSION_PATTERN}$ ]]; then
        print_debug "'${tag}' matches" >&2
        # SHA value is in last catch group in regex
        extractedSha="${BASH_REMATCH[${SHORT_SHA_INDEX}]}"
        print_debug "extractedSha='${extractedSha}'" >&2
        extractedSha=$(unwrap_short_sha "${extractedSha}")

        if [[ "${extractedSha}" != "${sha}" ]]; then
            local message="Error: Tag '${tag}' points to wrong SHA: '${sha}'."
            print_error "${message}" 1
        fi
    elif [[ "${continueOnMismatch}" == "y" ]]; then
        echo "*** $LINENO '${tag}' did NOT match, continue with error code" >&2
        # Signal that something went wrong instead of printing an
        # error message and aborting the script.
        result=1
    else
        local message="Error: Can't extract SHA from tag '${tag}'."
        echo "*** $LINENO '${tag}' did NOT match, error '${message}'" >&2
        print_error "${message}" 1
    fi

    # This sets the exit status of the function which is different
    # from the returned value (via an echo). If we on the other hand
    # called the exit function then the whole script would have
    # terminated.
    return ${result}
}


# Get version tag pointing to given commit. If multiple version tags
# points to the commit, select the one with the highest version.
function filter_tag()
{
    local commit="${1}"
    declare -a tagList

    # Get all tags pointing at the given commit as a list that is
    # sorted in REVERSE order (due to "-v:refname") as if the tags are
    # version numbers (e.g. x.y.z version numbers) in a "single
    # column" (one per row). Also recognize that prefix $RC_SEPARATOR
    # might occurr as well as $LOCATION_SEPARATOR and sort on those to
    # (in that order) if they exist.
    mapfile -t tagList < <(git -c "versionsort.suffix=${RC_SEPARATOR}" \
                               -c "versionsort.suffix=${LOCATION_SEPARATOR}" \
                               tag --list \
                               --sort=-v:refname \
                               --no-column \
                               --points-at \
                               "${commit}")

    # Iterate over the returned list and find the first tag that
    # matches our regexp, this is the version tag that represent the
    # highest version number closest to not being a non-release
    # candidate. If no non-release-candidate versions exists for the
    # highest version then the release-candidate with the highest
    # candidate number is selected.
    #
    # Recognized formats are
    # x.y.z__@<SHA for commit tag is pointing at>
    # x.y.z-r__@<SHA for commit tag is pointing at>
    # x.y.z-r__SE_TN_LKP__@<SHA for commit tag is pointing at>
    versionTag=""
    if [[ "${#tagList[@]}" -gt 0 ]]; then
        for tag in "${tagList[@]}"; do
            if [[ "${tag}" =~ ^${VERSION_PATTERN}$ ]]; then
                versionTag="${tag}"
                validate_tag "${tag}"
                break
            fi
        done
    fi

    # If no tag was found (that matched our search criteria) fallback
    # to using just SHA of commit.
    if [[ "${versionTag}" == "" ]]; then
        versionTag=$(git rev-parse --short="${SHORT_SHA_LENGTH}" HEAD)
        versionTag="@${versionTag}"
    fi

    echo "${versionTag}"
}



################################################################################
# Find first parent-or-self with a matching tag and if the commit has
# multiple tags version tags, select the one with the highest version
# number.

VERSION_GLOB="[0-9]*.[0-9]*.[0-9]*"
RC_GLOB="${RC_SEPARATOR}[1-9]*"
LOCATION_GLOB="${LOCATION_SEPARATOR}[A-Z][A-Z]_[A-Z]*_[-A-Za-z0-9._]*"
SHORT_SHA_GLOB="${SHA_SEPARATOR}[0-9a-z.]*"

# Return newest (in the sense of nearest commit with a tag) with
# highest version number.
#
# If no such tag exists, then the short SHA for the current commit is
# used instead.
#
# When first argument is set to "y" this means that in case of a match
# any delta to the tag is included in the returned value.
function find_newest_tag()
{
    local includeDelta="${1-}"
    local newestTag=""

    newestTag=$(git describe --long --first-parent --tags \
                    --match "${VERSION_GLOB}${SHORT_SHA_GLOB}" \
                    --match "${VERSION_GLOB}${RC_GLOB}${SHORT_SHA_GLOB}" \
                    --match "${VERSION_GLOB}${RC_GLOB}${LOCATION_GLOB}${SHORT_SHA_GLOB}" \
                    --candidates=1000 --always --dirty)

    # Git describe reports back a string (if tag matching any of the globs
    # is found) following the format
    #
    # TAG-SEQUENCE-SHA
    #
    # Where TAG is the content of the tag, SEQUENCE is number of commits
    # between a commit and tag, and SHA is the short SHA of a commit
    # (default commit is HEAD).
    if [[ "${newestTag}" =~ ^(.+${SHA_SEPARATOR}(${SHORT_SHA}))-([0-9]+-g[0-9a-f]+.*)$ ]]; then
        newestTag="${BASH_REMATCH[1]}"
        local sha=""
        local delta="${BASH_REMATCH[3]}"

        sha=$(unwrap_short_sha "${BASH_REMATCH[2]}")

        validate_tag "${newestTag}" "y"
        if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
            newestTag=$(filter_tag "${newestTag}")

            if [[ "${includeDelta}" == "y" ]]; then
                newestTag="${newestTag}-${delta}"
            fi
        else
            # Found tag is not valid, fall back to plain SHA for commit
            newestTag=$(git rev-parse --short="${SHORT_SHA_LENGTH}" HEAD)
        fi
    else
        # No tag found
        if [[ -n "${includeDelta}" ]]; then
            newestTag="@${newestTag}"
        else
            # Fall back to short-sha for HEAD
            newestTag=$(git rev-parse --short="${SHORT_SHA_LENGTH}" HEAD)
        fi
    fi

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
