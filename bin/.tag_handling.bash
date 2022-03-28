# Include core command line parsing support, common settings and
# utility functions.
#
# shellcheck source=./.core_preamble.bash
source "${METADATATOOLS_HOME}/.core_preamble.bash"


RC_SEPARATOR="-"
LOCATION_SEPARATOR="[+]"
SHA_SEPARATOR="__@"
DELTA_SEPARATOR="-"
DELTA_SHA_SEPARATOR="-@"
BRANCH_SEPARATOR="__%"
SUBBRANCH_SEPARATOR="@"

JIRA_ISSUE="([A-Z][A-Z][A-Z][A-Z]-[0-9]+)"
BRANCH_NAME="(.*)?"
BRANCH_PATTERN="(${BRANCH_SEPARATOR}${JIRA_ISSUE}"
BRANCH_PATTERN+="${SUBBRANCH_SEPARATOR}${BRANCH_NAME})?"

NATURAL_NUMBER="[1-9][0-9]*"
VERSION_FIELD="(0|${NATURAL_NUMBER})"
RC_FIELD="(${NATURAL_NUMBER})"

LOCATIION_FIELD_SEPARATOR="_"
COUNTRY_CODE="[A-Z][A-Z]"
SITE_CODE="[A-Z]+"
DOMAIN="[^${LOCATIION_FIELD_SEPARATOR}]+"

LOCATION="(${LOCATION_SEPARATOR}"
LOCATION+="(${COUNTRY_CODE}${LOCATIION_FIELD_SEPARATOR}"
LOCATION+="${SITE_CODE}${LOCATIION_FIELD_SEPARATOR}${DOMAIN}))"



# Release location using same format as a location expressed in a tag.
NREL="RL"
declare RELEASE_LOCATION="${LOCATION_SEPARATOR}"
RELEASE_LOCATION+="${RELEASE_COUNTRY:=${NREL}}${LOCATIION_FIELD_SEPARATOR}"
RELEASE_LOCATION+="${RELEASE_SITE:=${NREL}}${LOCATIION_FIELD_SEPARATOR}"
RELEASE_LOCATION+="${RELEASE_DOMAIN:=${NREL}}${LOCATIION_FIELD_SEPARATOR}"


# Current location as expressed in a tag.
#
# Note: If $CURRENT_LOCATION is equal to $RELEASE_LOCATION then the
#       location is suppressed in the tag.
NCUR="CL"
declare CURRENT_LOCATION="${LOCATION_SEPARATOR}"
CURRENT_LOCATION+="${DEVELOPMENT_COUNTRY:=${NCUR}}${LOCATIION_FIELD_SEPARATOR}"
CURRENT_LOCATION+="${DEVELOPMENT_SITE:=${NCUR}}${LOCATIION_FIELD_SEPARATOR}"
CURRENT_LOCATION+="${DEVELOPMENT_DOMAIN:=${NCUR}}${LOCATIION_FIELD_SEPARATOR}"



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


TAG_VERSION_PATTERN="(${VERSION_PATTERN}"
TAG_VERSION_PATTERN+="(${RC_SEPARATOR}${RC_FIELD}${LOCATION}?)?)"



TAG_SHA="${SHA_SEPARATOR}(${SHORT_SHA})"
TAG_VERSION_SHA_PATTERN="${TAG_VERSION_PATTERN}${TAG_SHA}"

DELTA_PATTERN="(${DELTA_SEPARATOR}([0-9]+)${DELTA_SHA_SEPARATOR}${PLAIN_SHA})"

# shellcheck disable=2034
TAG_OR_SHA_PATTERN="${TAG_VERSION_PATTERN}?${TAG_SHA}${DELTA_PATTERN}?"

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
STEP_MAJOR="Major"
STEP_MINOR="Minor"
STEP_PATCH="Patch"
STEP_RC="RC"
MAKE_RELEASE="Release"


function commit_committer_date()
{
    local commitSha="{1:-HEAD}"
    local result=""

    result=$(git show -s --format="%cd" \
                 --date=format:"%Y-%m-%dT%H:%M:%S%z" \
                 "${commitSha}")

    echo "${result}"
}


function commit_relative_id()
{
    local commitSha="{1:-HEAD}"
    local result=""

    # git show -s --format="%ad" --date=format:"%Y-%m-%dT%H:%M:%S%z"
    #
    # FLTS-4452:2022-01-26T14:37:11+0100:@f560b4d(1.0.0-1_SE_TN_Gride@f0ab.401d-1)__lorum-ipsum-dolor-sit-amet-con

    local newestTag=""
    newestTag=$(find_newest_tag "y")

    print_debug "newestTag='${newestTag}'"
    if [[ "${newestTag}" =~ ^(.+${SHA_SEPARATOR}${SHORT_SHA})-(([0-9]+)-g([0-9a-f]+)(.*))$ ]]; then
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

    echo "${result}"
}


function create_location_field ()
{
    local result=""

    if [[ "${RELEASE_LOCATION}" != "${CURRENT_LOCATION}" ]]; then
        result="${CURRENT_LOCATION}"
    fi

    echo "${result}"
}


function create_version ()
{
    local stepCommand="${1}"
    declare -i major=${2}
    declare -i minor=${3}
    declare -i patch=${4}
    declare -i rc=${5:-0}

    local result=""

    print_debug "    Major=${major}"
    print_debug "    Minor=${minor}"
    print_debug "    Patch=${patch}"
    print_debug "       RC=${rc}"

    case "${stepCommand}" in
        "${NEW_VERSION}")
            result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}1"
            print_debug "result='${result}'"
            ;;
        "${STEP_MAJOR}")
            result="$(( major+1 ))${VSC}0${VSC}0${RC_SEPARATOR}1"
            print_debug "result='${result}'"
            ;;
        "${STEP_MINOR}")
            result="${major}${VSC}$(( minor+1 ))${VSC}0${RC_SEPARATOR}1"
            print_debug "result='${result}'"
            ;;
        "${STEP_PATCH}")
            result="${major}${VSC}${minor}${VSC}$(( patch+1 ))${RC_SEPARATOR}1"
            print_debug "result='${result}'"
            ;;
        "${STEP_RC}")
            result="${major}${VSC}${minor}${VSC}${patch}${RC_SEPARATOR}$(( rc+1 ))"
            print_debug "result='${result}'"
            ;;
        "${MAKE_RELEASE}")
            result="${major}${VSC}${minor}${VSC}${patch}"
            print_debug "result='${result}'"
            ;;
        *)
            local message="Internal error; unknown version stepping command version stepping command may only be one of NEW_VERSION, STEP_MAJOR, STEP_MINOR, or STEP_PATCH."
            print_error "${message}" 3
            ;;
    esac

    # Append location field to the result
    result+=$(create_location_field)

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


function get_short_sha()
{
    local gitObject="${1:-HEAD}"

    local sha=""
    sha=$(git rev-parse --short="${SHORT_SHA_LENGTH}" "${gitObject}")

    echo "${sha}"
}


# Ensure SHA in tag matches commit tag points to.
function validate_tag()
{
    local tag="${1}"
    local continueOnMismatch="${2-}"
    local sha=""
    declare -i result=0

    if [[ "${DEBUG}" == "y" ]]; then
        print_debug "Running command 'git rev-parse --short=\"${SHORT_SHA_LENGTH}\" \"${tag}\"'"
    fi
    #sha=$(git rev-parse --short="${SHORT_SHA_LENGTH}" "${tag}")
    sha=$(get_short_sha "${tag}")
    if [[ "${DEBUG}" == "y" ]]; then
        print_debug "sha='${sha}'"
    fi

    local extractedSha=""
    print_debug "Testing if '${tag}'"
    print_debug "matches '${TAG_VERSION_SHA_PATTERN}'"
    if [[ "${tag}" =~ ^${TAG_VERSION_SHA_PATTERN}$ ]]; then
        print_debug "'${tag}' matches"
        # SHA value is in last catch group in regex
        extractedSha="${BASH_REMATCH[${SHORT_SHA_INDEX}]}"
        print_debug "extractedSha='${extractedSha}'"
        extractedSha=$(unwrap_short_sha "${extractedSha}")

        if [[ "${extractedSha}" != "${sha}" ]]; then
            local message="Error: Tag '${tag}' points to wrong SHA: '${sha}'."
            print_error "${message}" 1
        fi
    elif [[ "${continueOnMismatch}" == "y" ]]; then
        print_debug "'${tag}' did NOT match, continue with error code"
        # Signal that something went wrong instead of printing an
        # error message and aborting the script.
        result=1
    else
        local message="Error: Can't extract SHA from tag '${tag}'."
        print_debug "'${tag}' did NOT match, error '${message}'"
        print_error "${message}" 1
    fi

    # This sets the exit status of the function which is different
    # from the returned value (via an echo). If we on the other hand
    # called the exit function then the whole script would have
    # terminated.
    return ${result}
}


# Iterate over ALL tags and check all that match $TAG_VERSION_SHA_PATTERN
# regex. For these validate that they
#
# * Are attached to the same commit as the short SHA embedded in the tag name
#
# * There are at most one such tag attached to each commit
#
# * Author dates are consecutive, that is a version tag for version
# * 1.2.3 is not allowed to be created AFTER version tag 2.3.4.
#
# Note: The consistency checks done in this function are susceptible
# to an attack where multiple tags are created within the same second.
# There could also be a false negative if the short SHA stored in the
# tag is not unique within the repo.
function check_tag_consistency ()
{
    local commit="${1}"
    declare -a tagList

    # Get all tags pointing at the given commit as a list that is
    # sorted (due to "v:refname") as if the tags are version numbers
    # (e.g. x.y.z version numbers) in a "single column" (one per row).
    # Also recognize that suffix $RC_SEPARATOR might occurr as well as
    # $LOCATION_SEPARATOR and sort on those to (in that order) if they
    # exist.
    mapfile -t tagList < <(git -c "versionsort.suffix=${RC_SEPARATOR}" \
                               -c "versionsort.suffix=${LOCATION_SEPARATOR}" \
                               tag --list \
                               --sort=v:refname \
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
    #
    # x.y.z__@<SHA>
    # x.y.z-r__@<SHA>
    # x.y.z-r__SE_TN_LKP__@<SHA>
    #
    # where SHA is assumed to be SHA for commit tag is pointing to.
    versionTag=""
    if [[ "${#tagList[@]}" -gt 0 ]]; then
        local extractedSha=""
        local extractedVersion=""
        local previousSha=""
        local previousVersion=""

        local previousDate=0

        for tag in "${tagList[@]}"; do
            if [[ "${tag}" =~ ^${TAG_VERSION_SHA_PATTERN}$ ]]; then
                # SHA value is in last catch group in regex
                extractedSha="${BASH_REMATCH[${SHORT_SHA_INDEX}]}"
                previousVersion="${extractedVersion}"
                extractedVersion="${BASH_REMATCH[${TAG_VERSION_INDEX}]}"
                print_debug "extractedSha='${extractedSha}'"
                extractedSha=$(unwrap_short_sha "${extractedSha}")

                # Ensure tag SHA metadata is consistent
                validate_tag "${tag}"

                # Ensure consecutive version numbers do not point to same SHA
                if [[ -n "${previousSha}" ]]; then
                    if [[ "${extractedSha}" == "${previousSha}" ]]; then
                        local message="'${previousVersion}' and '${extractedVersion}' both point to the same commit ('${extractedSha}')."
                        print_error "${message}" 7
                    fi
                fi

                previousSha="${extractedSha}"

                # Ensure dates for tags are consecutive. Since Git has
                # already sorted the tags by version number we just
                # check if the dates in UNIX timestamp format (seconds
                # since 00:00 1970-01-01) are also consecutive.
                #
                # Note: We use author date instead of committer date
                # since it is when the tag was created that is
                # interesting here.
                currentDate=$(git show -s --format="%at" "${tag}")
                if (( currentDate < previousDate )); then
                    local message="'${extractedVersion}' is created after'${previousVersion}' but the version numbers indicate the other way around."
                    print-error "${message}" 7
                fi

                previousDate=${currentDate}
                versionTag="${tag}"
            fi
        done
    fi
}


# Get version tag pointing to given commit. If multiple version tags
# points to the commit, select the one with the highest version.
function filter_tag()
{
    local commit="${1}"
    declare -a tagList

    # Get all tags pointing at the given commit as a list that is
    # sorted in REVERSE order (due to "-v:refname" instead of
    # "v:refname") as if the tags are version numbers (e.g. x.y.z
    # version numbers) in a "single column" (one per row). Also
    # recognize that suffix $RC_SEPARATOR might occurr as well as
    # $LOCATION_SEPARATOR and sort on those to (in that order) if they
    # exist.
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
    #
    # x.y.z__@<SHA>
    # x.y.z-r__@<SHA>
    # x.y.z-r__SE_TN_LKP__@<SHA>
    #
    # where SHA is assumed to be SHA for commit tag is pointing to.
    versionTag=""
    print_debug "Found ${#tagList[@]} tags."
    if [[ "${#tagList[@]}" -gt 0 ]]; then
        local extractedSha=""

        for tag in "${tagList[@]}"; do
            if [[ "${tag}" =~ ^${TAG_VERSION_SHA_PATTERN}$ ]]; then
                # SHA value is in last catch group in regex
                extractedSha="${BASH_REMATCH[${SHORT_SHA_INDEX}]}"
                print_debug "extractedSha='${extractedSha}'"
                extractedSha=$(unwrap_short_sha "${extractedSha}")

                validate_tag "${tag}"
                versionTag="${tag}"
                break
            fi
        done
    fi

    # Check if we could find a tag that matched our regex (and if
    # multiple tags where found pick the one with the highest version
    # number). Otherwise fallback to using just SHA of commit;.
    if [[ "${versionTag}" == "" ]]; then
        versionTag=$(git rev-parse --short="${SHORT_SHA_LENGTH}" HEAD)
        versionTag="@${versionTag}"
    fi

    echo "${versionTag}"
}


# Get latest tag for the given location; which might be an empty
# string means that tags containing a location field are excluded from
# the search.
function latest_tag()
{
    local location=""
    location=$(create_location_field)

    declare -a tagList

    # Get all tags as a list that is sorted in REVERSE order (due to
    # "-v:refname") as if the tags are version numbers (e.g. x.y.z
    # version numbers) in a "single column" (one per row). Also
    # recognize that prefix $RC_SEPARATOR might occurr as well as
    # $LOCATION_SEPARATOR and sort on those to (in that order) if they
    # exist.
    mapfile -t tagList < <(git -c "versionsort.suffix=${RC_SEPARATOR}" \
                               -c "versionsort.suffix=${LOCATION_SEPARATOR}" \
                               tag --list \
                               --sort=-v:refname \
                               --no-column)

    # Iterate over the returned list IN REVERSE ORDER and find the
    # first tag that matches our regexp, this is the version tag that
    # represent the highest version number closest to not being a
    # non-release candidate. If no non-release-candidate versions
    # exists for the highest version then the release-candidate with
    # the highest candidate number is selected.
    #
    # Recognized formats are
    #
    # x.y.z__@<SHA>
    # x.y.z-r__@<SHA>
    # x.y.z-r__SE_TN_LKP__@<SHA>
    #
    # where SHA is assumed to be SHA for commit tag is pointing to.
    versionTag=""
    print_debug "Found ${#tagList[@]} tags."
    if [[ "${#tagList[@]}" -gt 0 ]]; then
        for tag in "${tagList[@]}"; do
            if [[ "${tag}" =~ ^${TAG_VERSION_SHA_PATTERN}$ ]]; then
                validate_tag "${tag}"

                if [[ "${BASH_REMATCH[${LOCATION_INDEX}]}" == "${location}" ]]
                then
                    versionTag="${tag}"
                    break
                fi
            fi
        done
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
    local includeDelta="${1:-}"
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
