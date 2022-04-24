# This file is sourced by .core_config.bash.

# This will not guard for someone assigning a string value to a
# variable named _FRIJA_EXIT_OK before this section is executed. But
# most other "normal" cases are covered.
#
# shellcheck source=./.exit_codes.bash
if ! [[ -v _FRIJA_EXIT_OK ]] || [[ -z "${_FRIJA_EXIT_OK}" ]]; then
   source "${REPO_TOOLS_HOME}/.exit_codes.bash"
fi


# Name of locale file holding repo-local locale information. That is
# the "owner" locale of the repo.
#
# To get the locale into the script just use a direct read from the
# file like (but you need a while loop to handle commented lines)
#
# read country site domain rest < "${repopath}/${META_LOCALE_FILENAME}"
#
# Where $repopath is the path to the folder holding the locale file
# (usually the root of a repo). The reason for the $rest variable is
# to guard against additional fields added to the file at a later
# point; any such data ends up in $rest instead of bungling up $domain
# with extra unexpected information.
#
# shellcheck disable=SC2034
META_LOCALE_NAME="meta-locale"


# Values used to control what happens during validation.
LOCALE_VALIDATE_ONLY="validate"
LOCALE_PRINT="print"
LOCALE_LIST="list"


_FRIJA_COUNTRIES_FILE="countries"
_FRIJA_SITES_SUFFIX="sites"
_FRIJA_DOMAINS_SUFFIX="domains"

_FRIJA_DESCRIPTION_SUFFIX="description"


# Read a data file organized in two columns (item name and description
# for item) where space is used as the column separator. This means
# that everything (including any spaces between non-space characters)
# are assumed to belong to the second column.
#
# First argument is name of array to store items in
#
# Second argument is name of array to store descriptions for item in
#
# Third argument is path to file to read from
function locale_read_data()
{
    local itemArray="${1}"
    local itemDescArray="${2}"
    local dataPath="${3}"

    # Ensure the fields data is read into are local variables,
    # otherwise we might end up modifying variables with the same name
    # that is found in the call stack since Bash uses call by name
    # semantics and not call by value/call by reference as in
    # C/C++/Java/C#/...
    local item=""
    local description=""
    while read -r item description; do
        if [[ "${item}" == "#"* ]]; then
            # Skip comment line
            continue
        fi

        # Strip any carriage returns from the read values
        item=${item//$'\r'}
        description=${description//$'\r'}

        print_debug "    item='${item}'  description='${description}'"
        # Append fields to the corresponding arrays using indirect
        # references. The only way to do this until Bash 4.3 is
        # installed in Gride is to use eval to evaluate a string
        # expression...
        eval "${itemArray}+=( '${item}' )"
        eval "${itemDescArray}+=( '${description}' )"
    done < "${dataPath}"
}


# Return name of array storing known locale countries. Note there is
# no guarantee that such an array actually exist, it is just the name
# it is supposed to have if it existed.
#
# This function does not accept any arguments.
function locale_countries_array_name()
{
    echo "${_FRIJA_COUNTRIES_FILE}"
}


# Return name of array storing known locale countries. Note there is
# no guarantee that such an array actually exist, it is just the name
# it is supposed to have if it existed.
#
# This function does not accept any arguments.
function locale_countries_description_array_name()
{
    echo "${_FRIJA_COUNTRIES_FILE}_${_FRIJA_DESCRIPTION_SUFFIX}"
}


# Return name of file storing known locale countries. Note there is no
# guarantee that such a file actually exist, it is just the name it is
# supposed to have if it existed.
#
# This function does not accept any arguments.
function locale_countries_path()
{
    echo "${REPO_TOOLS_CONFIG_PATH}/${_FRIJA_COUNTRIES_FILE}"
}


# Return name of array storing known sites for a given locale country.
# Note there is no guarantee that such an array actually exist, it is
# just the name it is supposed to have if it existed.
#
# The first argument is the country name to use for the returned array
# name.
function locale_sites_array_name()
{
    local country="${1}"

    local arrayName="${country}_${_FRIJA_SITES_SUFFIX}"

    echo "${arrayName}"
}


# Return name of array storing descriptions for known sites for a
# given locale country. Note there is no guarantee that such an array
# actually exist, it is just the name it is supposed to have if it
# existed.
#
# The first argument is the country name to use for the returned array
# name.
function locale_sites_description_array_name()
{
    local country="${1}"

    local arrayName="${country}_${_FRIJA_DESCRIPTION_SUFFIX}"

    echo "${arrayName}"
}


# Return name of file storing known sites for a given country. Note
# there is no guarantee that such a file actually exist, it is just
# the name it is supposed to have if it existed.
#
# The first argument is the country name to use for the returned file
# name.
function locale_sites_path()
{
    local country="${1}"

    echo "${REPO_TOOLS_CONFIG_PATH}/${country}_${_FRIJA_SITES_SUFFIX}"
}


# Return name of array storing known domains for a given locale
# country and site. Note there is no guarantee that such an array
# actually exist, it is just the name it is supposed to have if it
# existed.
#
# The first argument is the country name to use for the returned array
# name.
#
# The second argument is the site name to use for the returned array
# name.
function locale_domains_array_name()
{
    local country="${1}"
    local site="${2}"

    local arrayName="${country}_${site}_${_FRIJA_DOMAINS_SUFFIX}"

    echo "${arrayName}"
}


# Return name of array storing descriptions for known domains for a
# given locale country and site. Note there is no guarantee that such
# an array actually exist, it is just the name it is supposed to have
# if it existed.
#
# The first argument is the country name to use for the returned array
# name.
#
# The second argument is the site name to use for the returned array
# name.
function locale_domains_description_array_name()
{
    local country="${1}"
    local site="${2}"

    local arrayName="${country}_${site}_${_FRIJA_DESCRIPTION_SUFFIX}"

    echo "${arrayName}"
}


# Return name of file storing known domains for a given locale country
# and site. Note there is no guarantee that such a file actually
# exist, it is just the name it is supposed to have if it existed.
#
# The first argument is the country name to use for the returned file
# name.
#
# The second argument is the site name to use for the returned file
# name.
function locale_domains_path()
{
    local country="${1}"
    local site="${2}"

    local domainsPath="${REPO_TOOLS_CONFIG_PATH}"
    domainsPath+="/${country}_${site}_${_FRIJA_DOMAINS_SUFFIX}"

    echo "${domainsPath}"
}


# Read supported locale definition data (countries, their
# corresponding sites, and finally their domains) from files in
# $REPO_TOOLS_CONFIG_PATH. Read data is stored in arrays that are
# dynamically created.
#
# All generated arrays are named using generated names obtained from
# the corresponding functions (listed below)
#
# locale_countries_array_name
# locale_sites_array_name
# locale_sites_description_array_name
# locale_domains_array_name
# locale_domains_description_array_name
#
# This function does not accept any arguments.
function populate_locale_configuration_data()
{
    print_debug_enter

    local countryArray=""
    countryArray=$(locale_countries_array_name)

    local countryRef="${countryArray}[@]"

    # Indirect reference to array is tricky in Bash 4.2, especially if
    # using 'set -u' to detect unset variables. With nameref in Bash
    # 4.3 this would be a bit more straight forward.
    #
    # What we have to do is first to construct a test expression where
    # the variable holding the name of the array ($siteref) is
    # expanded and stored in $expression, and then this expression is
    # used via the eval function (that evaluates the string) in the
    # if-statement. Reason is that Bash does not allow constructs like
    #
    # ${#${foobar}[@]}
    #
    # That is the sequence '#$' is not allowed.
    #
    # This is not the prettiest piece of code, but it
    # works in Bash 4.2. Note that Git Bash in Windows environment
    # uses Bash 4.3 or newer, alas due to what is installed in CentOS 7
    # we have to use Bash 4.2...
    expression="(( \${#${countryRef}} > 0 ))"
    if [[ -v "${countryArray}" ]] && eval "${expression}" ; then
        # Check if $countryArray already exist and contain values. If
        # so just return.
        #
        # Note: Might have to add a "force" option to force a reload.
        print_debug "Array '${countryArray}' exist, returning."
        return
    fi

    # Declare global array with name stored in $countryArray; this
    # array will hold list of known countries
    print_debug "Creating '${countryArray}'."
    declare -a -g "${countryArray}"

    # Populate array with name stored in $countryArray from content of
    # file $countriesPath.
    local countriesPath=""
    countriesPath=$(locale_countries_path)
    print_debug "countriesPath='${countriesPath}'"
    if [[ -f "${countriesPath}" ]]; then
        local countryDescArray=""
        countryDescArray=$(locale_countries_description_array_name)

        # Declare global array with name stored in $countryDescArray; this
        # array will hold list of descriptions of known countries
        declare -a -g "${countryDescArray}"

        print_debug "Reading countries into ${countryArray}"

        locale_read_data "${countryArray}" \
                         "${countryDescArray}" \
                         "${countriesPath}"

        print_debug_array "countryArray"

        # Iterate over $countryArray by expanding its content to a
        # list; this is done by first creating a reference expression
        # stored in $countryRef which is then expanded using
        # ${!countryRef} notation
        local countryRef="${countryArray}[@]"
        local country
        for country in "${!countryRef}"; do
            print_debug "country='${country}'"
            local siteArray=""
            siteArray=$(locale_sites_array_name "${country}")
            local siteDescArray=""
            siteDescArray=$(locale_sites_description_array_name "${country}")
            print_debug "siteArray='${siteArray}'"
            print_debug "siteDescArray='${siteDescArray}'"

            declare -a -g "${siteArray}"
            declare -a -g "${siteDescArray}"

            local sitePath=""
            sitePath=$(locale_sites_path "${country}")
            print_debug "sitePath='${sitePath}'"
            if [[ -f "${sitePath}" ]]; then
                print_debug "  sitePath '${sitePath}' exist"

                locale_read_data "${siteArray}" "${siteDescArray}" "${sitePath}"

                print_debug_array "siteArray"
            else
                # No sites defined for current country, skip to next
                # country
                continue
            fi

            print_debug "  Reading domains for ${siteArray}"
            local siteRef="${siteArray}[@]"
            local site
            for site in "${!siteRef}"; do
                print_debug "    site=${site}"
                local domainArray=""
                domainArray=$(locale_domains_array_name "${country}" "${site}")
                local domainDescArray=""
                domainDescArray=$(locale_domains_description_array_name \
                                      "${country}" \
                                      "${site}")

                print_debug "    domainArray='${domainArray}'"
                print_debug "    domainDescArray='${domainDescArray}'"

                declare -a -g "${domainArray}"
                declare -a -g "${domainDescArray}"

                local domainPath=""
                domainPath=$(locale_domains_path "${country}" "${site}")
                print_debug "domainPath='${domainPath}'"
                if [[ -f "${domainPath}" ]]; then
                    print_debug "    domainPath '${domainPath}' exist"

                    locale_read_data "${domainArray}" \
                                     "${domainDescArray}" \
                                     "${domainPath}"

                    print_debug_array "domainArray"
                fi
            done
        done
    fi

    print_debug_exit
}


# Write to stdout all known locale countries.
function get_locale_countries()
{
    local countryRef=""
    countryRef=$(locale_countries_array_name)"[@]"

    echo "${!countryRef}"
}


# Write to stdout all known locale sites for given country.
#
# First argument is name of the country to use when listing sites.
function get_locale_sites()
{
    local country="${1}"
    local siteRef=""
    siteRef=$(locale_sites_array_name "${country}")"[*]"

    echo "${!siteRef}"
}


# Write to stdout all known locale domains for given country and site.
#
# First argument is name of the country to use when listing domains.
#
# Second argument is name of site to use when listing domains.
function get_locale_domains()
{
    local country="${1}"
    local site="${2}"

    local siteList=""
    siteList=$(get_locale_sites "${country}")

    if [[ -n "${siteList}" ]]; then
        # Here we actually want a literal match and not a regex-match,
        # thus disable check SC2076
        #
        # shellcheck disable=SC2076
        if [[ " ${siteList} " =~ " ${site} " ]]; then
            local domainRef=""
            domainRef=$(locale_domains_array_name "${country}" "${site}")"[@]"
            echo "${!domainRef}"
        else
            echo ""
        fi
    else
        echo ""
    fi
}


function locale_validate_country()
{
    print_debug "--> locale_validate_country()"
    local validateCommand="${1}"
    local country="${2:-}"

    print_debug "validateCommand='${validateCommand}'"
    print_debug "country='${country}'"

    local message=""

    local countryArray=""
    countryArray=$(locale_countries_array_name)

    local countryRef="${countryArray}[@]"

    # Expression for expanding an array as a string
    local countryStringRef="${countryArray}[*]"

    local result=""


    print_debug "countryArray='${countryArray}'"
    print_debug "countryRef='${countryRef}'"
    print_debug "countryStringRef='${countryStringRef}'"

    print_debug_array "countryArray"

    # Indirect reference to array is tricky in Bash 4.2, especially if
    # using 'set -u' to detect unset variables. With nameref in Bash
    # 4.3 this would be a bit more straight forward.
    #
    # What we have to do is first to construct a test expression where
    # the variable holding the name of the array ($siteref) is
    # expanded and stored in $expression, and then this expression is
    # used via the eval function (that evaluates the string) in the
    # if-statement. Reason is that Bash does not allow constructs like
    #
    # ${#${foobar}[@]}
    #
    # That is the sequence '#$' is not allowed.
    #
    # This is not the prettiest piece of code, but it
    # works in Bash 4.2. Note that Git Bash in Windows environment
    # uses Bash 4.3 or newer, alas due to what is installed in CentOS 7
    # we have to use Bash 4.2...
    expression="(( \${#${countryRef}} > 0 ))"
    if [[ -v "${countryArray}" ]] && eval "${expression}" ; then
        print_debug "${countryArray} exist and contains elements"
        print_debug "country='${country}'"
        print_debug "validateCommand='${validateCommand}'"
        print_debug "LOCALE_LIST='${LOCALE_LIST}'"
        print_debug "LOCALE_PRINT='${LOCALE_PRINT}'"
        if [[ -n "${country}" ]]; then
            print_debug "Validating country '${country}'"
            # Disable this check due to that we want to expand the
            # variable ${country} so it is no error and no need to quote
            # the '$', '{', or '}'.
            #
            # shellcheck disable=SC2076
            if [[ ! " ${!countryStringRef} " =~ " ${country} " ]]; then
                local message="Unknown country '${country}'."
                # shellcheck disable=SC2086
                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
        elif [[ "${validateCommand}" == "${LOCALE_LIST}" ]]; then
            print_debug "Creating list of countries:"
            # Return a list of values
            local country
            for country in "${!countryRef}"; do
                result+=" ${country}"
            done
        elif [[ "${validateCommand}" == "${LOCALE_PRINT}" ]]; then
            print_debug "Printing countries:"
            # Print values
            local message="Known countries using ISO 3166-1 alpha-2 "
            message+="two character notation"
            print_double_separator "${message}" "${BOLD}"

            local countryDescArray=""
            countryDescArray=$(locale_countries_description_array_name)
            print_two_columns "${countryArray}" "${countryDescArray}"

            print_double_separator "All known countries listed" "${BOLD}"
        else
            # Country is an empty string
            local message="A country must be specified."
            # shellcheck disable=SC2086
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    else
        local message="No known countries, please define some!"
        print_double_separator
        print_message "${message}"

        message="Country names must be defined using "
        message+="ISO 3166-1 alpha-2 two character notation."
        print_note "${message}"

        if [[ -n "${country}" ]]; then
            message="Can't check if given country '${country}' is valid."
        else
            message="Can't check if any given country is valid."
        fi
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    print_debug "<-- locale_validate_country(): '${result}'"
    if [[ -n "${result}" ]]; then
        echo "${result}"
    fi
}


function locale_validate_country_site()
{
    local validateCommand="${1}"
    local country="${2:-}"
    local site="${3:-}"

    print_debug "--> locale_validate_country_site()"
    print_debug "validateCommand='${validateCommand}'"
    print_debug "country='${country}'"
    print_debug "site='${site}'"

    local message=""
    local result=""

    if [[ -z "${country}" ]]; then
        if [[ -n "${site}" ]]; then
            # Only site given
            message="Country must be given if site ('${site}') is given."
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    else
        locale_validate_country "${LOCALE_VALIDATE_ONLY}" "${country}"
    fi

    if [[ -n "${country}" ]]; then
        print_debug "Processing country '${country}'"
        local siteArray=""
        siteArray=$(locale_sites_array_name "${country}")

        local siteRef="${siteArray}[@]"

        # Expression for expanding an array as a string
        local siteStringRef="${siteArray}[*]"


        # Indirect reference to array is tricky in Bash 4.2, especially if
        # using 'set -u' to detect unset variables. With nameref in Bash
        # 4.3 this would be a bit more straight forward.
        #
        # What we have to do is first to construct a test expression where
        # the variable holding the name of the array ($siteref) is
        # expanded and stored in $expression, and then this expression is
        # used via the eval function (that evaluates the string) in the
        # if-statement. Reason is that Bash does not allow constructs like
        #
        # ${#${foobar}[@]}
        #
        # That is the sequence '#$' is not allowed.
        #
        # This is not the prettiest piece of code, but it
        # works in Bash 4.2. Note that Git Bash in Windows environment
        # uses Bash 4.3 or newer, alas due to what is installed in CentOS 7
        # we have to use Bash 4.2...
        expression="(( \${#${siteRef}} > 0 ))"
        if [[ -v "${siteArray}" ]] && eval "${expression}" ; then
            print_debug "Site array '${siteArray}' exist and is non-empty"
            if [[ -n "${site}" ]]; then
                print_debug "Validating site '${site}'"
                # Disable this check due to that we want to expand the
                # variable ${country} so it is no error and no need to quote
                # the '$', '{', or '}'.
                #
                # shellcheck disable=SC2076
                if [[ ! " ${!siteStringRef} " =~ " ${site} " ]]; then
                    local message="Unknown site '${site}' "
                    message+="for country '${country}."
                    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
                fi
            elif [[ "${validateCommand}" == "${LOCALE_LIST}" ]]; then
                print_debug "Building list of sites"
                # Return a list of values
                local site
                for site in "${!siteRef}"; do
                    result+=" ${site}"
                done
            elif [[ "${validateCommand}" == "${LOCALE_PRINT}" ]]; then
                print_debug "Printing sites"
                local message="Known sites for country '${country}' "
                message+="using two or three character notation"
                print_double_separator "${message}" "${BOLD}"

                local siteDescArray=""
                siteDescArray=$(locale_sites_description_array_name \
                                      "${country}")
                print_two_columns "${siteArray}" "${siteDescArray}"

                print_double_separator "All known sites listed" "${BOLD}"
            else
                # Country is an empty string
                local message="No site is specified."
                # shellcheck disable=SC2086
                print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
            fi
        else
            local message="No known sites for country '${country}', "
            message+="please define some!"
            print_double_separator
            print_message "${message}"

            message="Site names must use two or three character notation; "
            message+="for instance 'TN' for Tannefors and "
            message+="'GPX' for Gaviao Peixoto."
            print_note "${message}"

            if [[ -n "${site}" ]]; then
                message="Can't check if given combination of "
                message+="country '${country}' and site '${site}' is valid."
            else
                message="Can't validate any sites for given "
                message+="country '${country}'."
            fi
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    fi

    print_debug "<-- locale_validate_country_site(): '${result}'"
    if [[ -n "${result}" ]]; then
        echo "${result}"
    fi
}


function locale_validate_country_site_domain()
{
    print_debug_enter "${@}"

    local validateCommand="${1}"
    local country="${2:-}"
    local site="${3:-}"
    local domain="${4:-}"

    print_debug "validateCommand='${validateCommand}'"
    print_debug "country='${country}'"
    print_debug "site='${site}'"
    print_debug "domain='${domain}'"

    local message=""
    local result=""

    if [[ -z "${country}" ]]; then
        if [[ -z "${site}" ]]; then
            if [[ -z "${domain}" ]]; then
                # None of country, site, and domain given
                case "${validateCommand}" in
                    "${LOCALE_LIST}"|"${LOCALE_PRINT}")
                        print_debug "Calling locale_validate_country(${validateCommand})"
                        locale_validate_country "${validateCommand}"
                        validateCommand="${LOCALE_VALIDATE_ONLY}"
                        ;;
                    *)
                        message="Country, site, and domain must all be given."
                        ;;
                esac
            else
                # Only domain given
                message="Country and site must be given if domain is given."
            fi
        else
            if [[ -z "${domain}" ]]; then
                # Only site given
                message="Country must be given if site is given."
            else
                # Only site and domain given
                message="Country must be given if site and domain given."
            fi
        fi
    else
        print_debug "country='${country}'"
        if [[ -z "${site}" ]]; then
            if [[ -z "${domain}" ]]; then
                # Only country given
                local debugMessage="Calling locale_validate_country_site"
                debugMessage+="('${validateCommand}' '{country}')"
                print_debug "${debugMessage}"
                print_debug "Calling locale_validate_country_site(${validateCommand} ${country})"
                locale_validate_country_site "${validateCommand}" "${country}"
                validateCommand="${LOCALE_VALIDATE_ONLY}"
            else
                # Country and domain given
                message="Site must be given if country and domain given."
            fi
        else
            print_debug "site='${site}'"
            if [[ -z "${domain}" ]]; then
                # Country and site given
                print_debug "Calling locale_validate_country_site(${LOCALE_VALIDATE_ONLY} '${country}' '${site}')"
                locale_validate_country_site "${LOCALE_VALIDATE_ONLY}" \
                                             "${country}" "${site}"
                case "${validateCommand}" in
                    "${LOCALE_LIST}"|"${LOCALE_PRINT}")
                        ;;
                    *)
                        message="Country, site, and domain must all be given."
                        ;;
                esac
            else
                # All of country, site, and domain given; domain is
                # validated below.
                print_debug "Calling locale_validate_country_site(${LOCALE_VALIDATE_ONLY} '${country}' '${site}')"
                locale_validate_country_site "${LOCALE_VALIDATE_ONLY}" \
                                             "${country}" "${site}"
            fi
        fi
    fi

    if [[ -n "${message}" ]]; then
        print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
    fi

    if [[ -n "${country}" ]] && [[ -n "${site}" ]]; then
        print_debug "country='${country}'"
        print_debug "site='${site}'"
        local domainArray=""
        domainArray=$(locale_domains_array_name "${country}" "${site}")

        local domainRef="${domainArray}[@]"

        # Expression for expanding an array as a string
        local domainStringRef="${domainArray}[*]"

        print_debug "domainArray=${domainArray}"
        print_debug "domainRef=${domainRef}"
        print_debug "domainStringRef=${domainStringRef}"

        # Indirect reference to array is tricky in Bash 4.2, especially if
        # using 'set -u' to detect unset variables. With nameref in Bash
        # 4.3 this would be a bit more straight forward.
        #
        # What we have to do is first to construct a test expression where
        # the variable holding the name of the array ($domainref) is
        # expanded and stored in $expression, and then this expression is
        # used via the eval function (that evaluates the string) in the
        # if-statement. Reason is that Bash does not allow constructs like
        #
        # ${#${foobar}[@]}
        #
        # That is the sequence '#$' is not allowed.
        #
        # This is not the prettiest piece of code, but it
        # works in Bash 4.2. Note that Git Bash in Windows environment
        # uses Bash 4.3 or newer, alas due to what is installed in CentOS 7
        # we have to use Bash 4.2...
        expression="(( \${#${domainRef}} > 0 ))"
        if [[ -v "${domainArray}" ]] && eval "${expression}" ; then
            print_debug "Domain array '${domainArray}' exist and is non-empty"
            print_debug "domain='${domain}'"
            print_debug "validateCommand='${validateCommand}'"
            print_debug "LOCALE_LIST=${LOCALE_LIST}"
            print_debug "LOCALE_PRINT=${LOCALE_PRINT}"
            if [[ -n "${domain}" ]]; then
                print_debug "Validating domain '${domain}'"
                # Disable this check due to that we want to expand the
                # variable ${country} so it is no error and no need to quote
                # the '$', '{', or '}'.
                #
                # shellcheck disable=SC2076
                if [[ ! " ${!domainStringRef} " =~ " ${domain} " ]]; then
                    local message="Unknown domain '${domain}' for given "
                    message+="combination of country '${country} "
                    message+="and site '${site}'."
                    print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
                fi
            elif [[ "${validateCommand}" == "${LOCALE_LIST}" ]]; then
                print_debug "Iterating over ${domainArray}"

                print_debug "Building list of domains"
                # Return a list of values
                local domain
                for domain in "${!domainRef}"; do
                    result+=" ${domain}"
                    print_debug "domain=${domain}"
                    print_debug "result=${result}"
                done
                print_debug "Finished iterating over ${domainArray}"
            elif [[ "${validateCommand}" == "${LOCALE_PRINT}" ]]; then
                print_debug "Printing domains"
                local message="Known domains for country '${country}' "
                message+="and site '${site}'"
                print_double_separator "${message}" "${BOLD}"

                local domainDescArray=""
                domainDescArray=$(locale_domains_description_array_name \
                                      "${country}" \
                                      "${site}")
                print_two_columns "${domainArray}" "${domainDescArray}"

                print_double_separator "All known domains listed" "${BOLD}"
            fi
        else
            local message="No known domains for given combination of "
            message+="country '${country}' and site '${site}'; "
            message+="please define some!"
            print_double_separator
            print_message "${message}"

            message="Domain names must not contain any spaces; for instance "
            message+="'Gride-H/S' ${BOLD}and not${CLEAR} 'Gride H/S'."
            print_note "${message}"

            if [[ -n "${domain}" ]]; then
                message="Can't check if given combination of "
                message+="country '${country}', site '${site}, "
                message+="and domain '${domain}' is valid."
            else
                message="Can't validate any domain combined with "
                message+="country '${country}' and site '${site}."
            fi
            print_error "${message}" $_FRIJA_EXIT_OTHER_PROBLEM
        fi
    fi

    print_debug_exit "'${result}'"
    if [[ -n "${result}" ]]; then
        echo "${result}"
    fi
}
