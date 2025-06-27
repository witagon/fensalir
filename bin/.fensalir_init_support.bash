# Filename for non-changeable configuration, that is things a user
# should not modify.
FENSALIR_NON_CHANGEABLE_CONFIG=".fensalirncc"

# Filename for example user configuration file
FENSALIR_EXAMPLE_CONFIG="example.fensalirconfig"

# Path to folder holding Fensalir user configuration
FENSALIR_USERCONFIG_PATH="${XDG_CONFIG_HOME:-${HOME}/.config}/Fensalir"

# Filename for actual user configuration file
FENSALIR_USERCONFIG_FILE=".${FENSALIR_EXAMPLE_CONFIG##*.}"

# Folder name for configuration scripts folder
FENSALIR_SCRIPTS="scripts"

# Name of file located in $FENSALIR_SCRIPTS folder user should source
# from .bashrc file. That is path to this file is
# "${FENSALIR_USERCONFIG_PATH}/${FENSALIR_SCRIPTS}/${FENSALIR_USERINIT}"
FENSALIR_USERINIT_FILE="userinit.bash"

FENSALIR_USERINIT_PATH="${FENSALIR_USERCONFIG_PATH}/${FENSALIR_SCRIPTS}/"
FENSALIR_USERINIT_PATH+="${FENSALIR_USERINIT_FILE}"


# Transforms the file $_FENSALIR_INIT in source repo and stores it in
# target repo.
#
# First parameter is path to root of target
#
# Second parameter is optional path to root of source repo; if not
#                  specified (empty string) it defaults to root of
#                  target
#
# Third parameter is country to use
#
# Fourth parameter is site to use
#
# Fifth parameter is domain to use
function transform_fensalir_init()
{
    local fensalirRoot="${1}"
    local inputRoot="${2:-${fensalirRoot}}"
    local country="${3}"
    local site="${4}"
    local domain="${5}"

    # Name of repo is the last component of the path. Thus by removing
    # everything except the last path component from the path gives
    # the name of the repo.
    local fensalirReponame="${fensalirRoot##*/}"

    # sed expression to replace all occurrences of
    # '_FENSALIR_REPONAME="_REPONAME_"' with
    # '_FENSALIR_REPONAME="<name of repo>"'
    local reponameString="_FENSALIR_REPONAME"
    local sedReponame="s/^${reponameString}=\".{_REPONAME_}\"/"
    sedReponame+="${reponameString}=\"${fensalirReponame}\"/"

    # sed expression to replace all occurrences of
    # '_FENSALIR_ROOT="_REPOPATH_"' with
    # '_FENSALIR_ROOT="<path to root of repo>"'.
    #
    # As a PATH contain '/' characters we must use another separator
    # character then '/' and here we opt to use '%' and cross our fingers
    # that the path to Volla does not contain any '%' characters (it
    # should not do that).
    local reporootString="_FENSALIR_ROOT"
    local sedReporoot="s%^${reporootString}=\".{_REPOPATH_}\"%"
    sedReporoot+="${reporootString}=\"${fensalirRoot}\"%"

    # sed expression to replace all occurrences of
    # 'export _FRIJA_DEVELOPMENT_SAFE_COUNTRY=""' with
    # 'export _FRIJA_DEVELOPMENT_SAFE_COUNTRY="<country>"'
    local countryString="export _FRIJA_DEVELOPMENT_COUNTRY"
    local sedCountry="s/^${countryString}=\"\"/${countryString}=\"${country}\"/"

    # sed expression to replace all occurrences of
    # 'export _FRIJA_DEVELOPMENT_SAFE_SITE=""' with
    # 'export _FRIJA_DEVELOPMENT_SAFE_SITE="<site>"'
    local siteString="export _FRIJA_DEVELOPMENT_SITE"

    # To be extra careful we take precautions that any '/' characters in
    # the site name does not cause any problems in the sed expression
    # below. See the comment for $sedDomain below for further information.
    local sedSite="s%^${siteString}=\"\"%${siteString}=\"${site//%/\\%}\"%"

    # sed expression to replace all occurrences of $domainString with $domain
    local domainString="export _FRIJA_DEVELOPMENT_DOMAIN"

    # sed expression to replace all occurrences of
    # 'export _FRIJA_DEVELOPMENT_SAFE_DOMAIN=""' with
    # 'export _FRIJA_DEVELOPMENT_SAFE_DOMAIN="<domain>"'
    #
    # Note that due to that $domain may contain '/' character(s) it is
    # not possible to write sed expressions using slashes, for
    # instance 'sed -e s/foo/bar/'. The sed command has built-in
    # support for this case due to that the usage of the '/' character
    # is not hardcoded. Instead sed uses the character following 's'
    # as the field spearator; in the above case '/' is used to
    # separate the match part ('foo') from the replacement part
    # ('bar').
    #
    # We could use another character like '%' as the field separator like
    # 'sed -e s%foo%bar%' but then we would end up with the same problem
    # if there are any '%' caracters in either 'foo' or 'bar'.
    #
    # Another option is to escape any occurrences of the field separator
    # in 'bar' using '\'; assuming bar is "a/b/c" we would then get 'sed
    # -e s/foo/a\\/b\\/c/'. This is beacause backslash needs to be escaped
    # for Bash to get the backslash character, thus '\\' means a single
    # backslash and we end up with '\\/' to escape the slash character.
    #
    # As this is rapidly approaching something that looks like white noise
    # a more readable approach is to combine the two methods outlined
    # above. Use another character than '/' as the field separator and
    # escape it. Here we have opted to use '%' as the field separator and
    # then you instead get 'sed -e s%foo%a/b/c%'; alas we also have to
    # escape all occurrences of '%' in the replacement string.
    #
    # This is done useing Bash parameter expansion with string
    # replacement, for instance '${var//foo/bar}' will replace all
    # occurrences of 'foo' with 'bar' during expansion of $var. Thus to
    # replace all occurrences of '%' with '\\%' we simply to
    # '${var//%/\\%}'.
    #
    # Note: Since Bash does not allow '%' in variable names there is no
    # need to do anything with $domainString as it is guaranteed to be
    # 'safe'.
    local sedDomain="s%^${domainString}=\"\"%"
    sedDomain+="${domainString}=\"${domain//%/\\%}\"%"


    ## sed expression to replace all occurrences of
    # 'export _FRIJA_DEVELOPMENT_SAFE_COUNTRY=""' with
    # 'export _FRIJA_DEVELOPMENT_SAFE_COUNTRY="<safe country>"'
    local safeCountryString="export _FRIJA_DEVELOPMENT_SAFE_COUNTRY"

    # Transform $country by removing all slashes. The intention is to
    # create a string that can safely be used in filenames, search paths,
    # branch names, and so on.
    local safeCountry="${country//\//}"

    # Expression for replacing the dummy assignment with an actual value
    local sedSafeCountry="s/^${safeCountryString}=\"\"/"
    sedSafeCountry+="${safeCountryString}=\"${safeCountry}\"/"


    ## sed expression to replace all occurrences of
    # export _FRIJA_DEVELOPMENT_SAFE_SITE="" with
    # export _FRIJA_DEVELOPMENT_SAFE_SITE="<safe site>"
    local safeSiteString="export _FRIJA_DEVELOPMENT_SAFE_SITE"

    # Transform $site by removing all slashes. The intention is to
    # create a string that can safely be used in filenames, search paths,
    # branch names, and so on.
    local safeSite="${site//\//}"

    # Expression for replacing the dummy assignment with an actual value
    local sedSafeSite="s/^${safeSiteString}=\"\"/"
    sedSafeSite+="${safeSiteString}=\"${safeSite}\"/"


    ## sed expression to replace all occurrences of
    # export _FRIJA_DEVELOPMENT_SAFE_DOMAIN="" with
    # export _FRIJA_DEVELOPMENT_SAFE_DOMAIN="<safe domain>"
    local safeDomainString="export _FRIJA_DEVELOPMENT_SAFE_DOMAIN"

    # Transform $domain by removing all slashes. The intention is to
    # create a string that can safely be used in filenames, search paths,
    # branch names, and so on.
    local safeDomain="${domain//\//}"

    # Expression for replacing the dummy assignment with an actual value
    local sedSafeDomain="s/^${safeDomainString}=\"\"/"
    sedSafeDomain+="${safeDomainString}=\"${safeDomain}\"/"


    # File template for the core Fensalir configuration file. This
    # file is filtered below using sed.
    local inputFilePath="${inputRoot}/config/${_FENSALIR_INIT}"

    # File to store sed result in; folder is the parent of the
    # Fensalir repo folder
    local outputFilePath="${fensalirRoot%/*}/${_FENSALIR_INIT}"

    # sed command to execute where output of command is redirected to
    # $outputFilePath
    local message="${CLEAR}Filtering Fensalir init script"
    local command=("${SINGLE}" "${message}" "${outputFilePath}" \
                               sed -e "${sedReponame}" \
                               -e "${sedReporoot}" \
                               -e "${sedCountry}" \
                               -e "${sedSite}" \
                               -e "${sedDomain}" \
                               -e "${sedSafeCountry}" \
                               -e "${sedSafeSite}" \
                               -e "${sedSafeDomain}" \
                               "${inputFilePath}")
    run_with_redirect "${command[@]}"
}


CONFIG_VERSION_FILE="version.config"

#
# First parameter is path to root of Fensalir repo
#
function update_user_config_version()
{
    local fensalirRoot="${1}"

    local configVersionPath="${FENSALIR_USERCONFIG_PATH}/${CONFIG_VERSION_FILE}"

    declare -a command="()"
    command=("${NONE}" "" \
                       "${configVersionPath}" \
                       git -C "${fensalirRoot}" rev-parse)
    run_with_redirect "${command[@]}"
    .
}


#
# First parameter is path to root of Fensalir repo
#
function fensalir_vcs_version()
{
    local fensalirRoot="${1}"

    local version=""
    ! version=$(git -C "${fensalirRoot}" \
                    rev-parse "--quiet" "--verify" HEAD 2>/dev/null )
    if [[ -z "${version}" ]]; then
        local message="Given path '${fensalirRoot}' is not within a Git repo, "
        message+="aborting."
        print_error "${message}" "${FRIJA_EXIT_OTHER_PROBLEM}"
    fi

    echo "${version}"
}


# Updates the user config folder. If it does not exist it is created
# before the update. If previous versions of files user is allowed to
# edit differ from the new version then warning messages are printed.
#
# First parameter is path to root of Fensalir repo
#
function update_user_config()
{
    local fensalirRoot="${1}"
    local domain="${domain}"

    # Aliases for constants.
    local userConfigPath="${FENSALIR_USERCONFIG_PATH}"
    local exampleConfigFile="${FENSALIR_EXAMPLE_CONFIG}"
    local nonchangeableConfigFile="${FENSALIR_NON_CHANGEABLE_CONFIG}"
    local userInitFile="${FENSALIR_USERINIT_FILE}"
    local userConfigFile="${FENSALIR_USERCONFIG_FILE}"

    # Folder storing script files that Fensalir manages, including the
    # file that the user is supposed to source from .bashrc file
    # ($userInitFile)
    local scriptsFolder="${FENSALIR_SCRIPTS}"

    declare -a command="()"
    command=("${SINGLE}" "Ensuring '${userConfigPath}' exist" \
                               mkdir -p "${userConfigPath}/${scriptsFolder}")
    run "${command[@]}"

    # Path to folder containing scripts to be copied to users
    # configuration folder
    local userfiles="${fensalirRoot}/config/userfiles"

    # Target example user configuration file
    local exampleConfigFilePath="${userConfigPath}/${exampleConfigFile}"
    local exampleConfigFilePath="${userConfigPath}/${exampleConfigFile}"


    # sed expression to replace all occurrences of
    # _FENSALIRNCC_ with value of ${nonchangeableConfigFile}
    local sedFensalirNcc="s/_FENSALIRNCC_/${nonchangeableConfigFile}/"

    # sed expression to replace all occurrences of
    # _FENSALIRCONFIG_ with value of ${userConfigFile}
    local sedFensalirConfig="s/_FENSALIRCONFIG_/${userConfigFile}/"

    local configHome="${userConfigPath}"
    if [[ "${userConfigPath}" == "${HOME}/"* ]]; then
        # shellcheck disable=SC2016
        configHome='${HOME}/'"${userConfigPath/${HOME}\//}"
    fi
    # sed expression to replace all occurrences of
    # _FENSALIR_USER_CONFIG_HOME_ with value of ${configHome}
    local sedFensalirConfigHome="s;_FENSALIR_USER_CONFIG_HOME_;${configHome};"


    # Filter template example configuration file and store it as a
    # temporary copy in the $userConfigPath folder

    local inputFilePath="${userfiles}/${exampleConfigFile}"
    local outputFilePath="${exampleConfigFilePath}.tmp"

    # Use sed command to filter $inputFilePath to $outputFilePath.
    # Note that the content of this variable is reused below when
    # temporary file is renamed.
    command=("${SINGLE}" "${CLEAR}Filtering example config" \
                         "${outputFilePath}" \
                         sed -e "${sedFensalirConfig}" \
                         -e "${sedFensalirConfigHome}" \
                         "${inputFilePath}")
    run_with_redirect "${command[@]}"


    if [[ -e "${exampleConfigFilePath}" ]]; then
        if ! diff "${outputFilePath}" "${exampleConfigFilePath}" 1>&2 >/dev/null
        then
            local warning="Existing Fensalir example configuration file "
            warning+="'${exampleConfigFilePath}' differs from new version."

            local message="Please compare new version with backup copy and "
            message+="update personal Fensalir configuration settings as "
            message+="necessary."

            print_warning "${warning}" "${message}"

            # To force cp command to create a backup for us we have to
            # create a copy of the exsiting file first
            command=("${SINGLE}" "" \
                                 cp "${exampleConfigFilePath}" \
                                 "${exampleConfigFilePath}.old")
            run "${command[@]}"

            command=("${SINGLE}" \
                         "Creating backup of existing example config file" \
                         cp "--backup=numbered" "--force" \
                         "${exampleConfigFilePath}.old" \
                         "${exampleConfigFilePath}")
            run "${command[@]}"

            # Cleaning up
            command=("${SINGLE}" "Removing existing example config file" \
                                 rm "--force" \
                                 "${exampleConfigFilePath}" \
                                 "${exampleConfigFilePath}.old")
            run "${command[@]}"

            command=("${SINGLE}" \
                         "Clearing '${userConfigPath}/${scriptsFolder}'" \
                         rm -fr "${userConfigPath}/${scriptsFolder}")
            run "${command[@]}"

            # Recreate scripts folder we just removed
            command=("${SINGLE}" \
                         "" \
                         mkdir -p "${userConfigPath}/${scriptsFolder}")
            run "${command[@]}"
        fi
    fi


    ##########################################
    ## Generate non-chgangeable configuration

    ## Generic Linux notation paths
    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Linux for current development domain.
    local linuxPwaMapName=$(_fensalir_pwa_map_array_name "${_FENSALIR_LINUX}")
    local fensalirLinuxHome=""
    if [[ -v "${linuxPwaMapName}[@]" ]]; then
	declare -n linuxPwaMapName="${linuxPwaMapName}"
	fensalirLinuxHome="${linuxPwaMapName[${domain}]:-}"
    fi


    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Windows for current development domain.
    local windowsPwaMapName=$(_fensalir_pwa_map_array_name \
				  "${_FENSALIR_WINDOWS}")
    local fensalirWindowsHome=""
    if [[ -v "${windowsPwaMapName}[@]" ]]; then
	declare -n windowsPwaMapName="${windowsPwaMapName}"
	fensalirWindowsHome="${windowsPwaMapName[${domain}]:-}"
    fi


    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Solaris for current development domain.
    local solarisPwaMapName=$(_fensalir_pwa_map_array_name \
				      "${_FENSALIR_SOLARIS}")
    local fensalirSolarisHome=""
    if [[ -v "${solarisPwaMapName}[@]" ]]; then
	declare -n solarisPwaMapName="${solarisPwaMapName}"
	pwaMap="${solarisPwaMapName[${domain}]:-}"
    fi


    ## OS-specific notation paths
    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Linux for current development domain.
    local linuxPwaOsMapName=$(_fensalir_pwa_os_map_array_name \
				  "${_FENSALIR_LINUX}")
    local fensalirLinuxOsHome=""
    if [[ -v "${linuxPwaOsMapName}[@]" ]]; then
	declare -n linuxPwaOsMapName="${linuxPwaOsMapName}"
	fensalirLinuxOsHome="${linuxPwaOsMapName[${domain}]:-}"
    fi


    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Windows for current development domain.
    local windowsPwaOsMapName=$(_fensalir_pwa_os_map_array_name \
				  "${_FENSALIR_WINDOWS}")
    local fensalirWindowsOsHome=""
    if [[ -v "${windowsPwaOsMapName}[@]" ]]; then
	declare -n windowsPwaOsMapName="${windowsPwaOsMapName}"
	fensalirWindowsOsHome="${windowsPwaOsMapName[${domain}]:-}"
    fi


    # Local indirect reference variable to associative array for where
    # Fensalir is installed on Solaris for current development domain.
    local solarisPwaOsMapName=$(_fensalir_pwa_os_map_array_name \
				      "${_FENSALIR_SOLARIS}")
    local fensalirSolarisOsHome=""
    if [[ -v "${solarisPwaOsMapName}[@]" ]]; then
	declare -n solarisPwaOsMapName="${solarisPwaOsMapName}"
	fensalirSolarisOsHome="${solarisPwaOsMapName[${domain}]:-}"
    fi

    cat <<EOF >| "${userConfigPath}/${nonchangeableConfigFile}"
################################################################################
# Start of NON-CHANGEABLE configuration settings
#
################################################################################
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
################################################################################
# Changing or removing ANY of these NON-CHANGEABLE configuration
# settings may break the Fensalir installation. Changing any of the
# settings might cause unexpected side effects. Here be dragons!
################################################################################
# WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING WARNING
################################################################################
_FENSALIR_LINUX_HOME="${fensalirLinuxHome}"
_FENSALIR_SOLARIS_HOME="${fensalirWindowsHome}"
_FENSALIR_WINDOWS_HOME="${fensalirSolarisHome}"

_FENSALIR_LINUX_OS_HOME="${fensalirLinuxOsHome}"
_FENSALIR_SOLARIS_OS_HOME="${fensalirWindowsOsHome}"
_FENSALIR_WINDOWS_OS_HOME="${fensalirSolarisOsHome}"
################################################################################
# End of NON-CHANGEABLE configuration settings
################################################################################
EOF


    # Expand glob selecting files to copy by creating an array
    declare -a files=()
    files=("${userfiles}"/*)
    command=("${SINGLE}" "Copying Fensalir init and configuration files" \
                         cp "--recursive" "--force" \
                         "${files[@]}" \
                         "${userConfigPath}")
    run "${command[@]}"

    # Rename temporary filtered example config file, effectively
    # replacing the one originating from the repo with placeholder
    # fields
    command=("${SINGLE}" "" \
                         mv "${outputFilePath}" "${exampleConfigFilePath}")
    run "${command[@]}"


    # Filter template userinit file and store it in the
    # $userConfigPath folder

    inputFilePath="${userfiles}/${scriptsFolder}/${userInitFile}"
    outputFilePath="${userConfigPath}/${scriptsFolder}/${userInitFile}"

    # Use sed command to filter $inputFilePath to $outputFilePath.
    command=("${SINGLE}" "${CLEAR}Filtering userconfig script" \
                         "${outputFilePath}" \
                         sed -e "${sedFensalirConfig}" \
			 -e "${sedFensalirNcc}" \
                         "${inputFilePath}")
    run_with_redirect "${command[@]}"

    # Check if there already exist a user configuration file and if so
    # inform user that it might need to be updated

    local configFile=""
    if [[ -r "${HOME}/${userConfigFile}" ]]; then
        configFile="${HOME}/${userConfigFile}"
    elif [[ -r "${userConfigPath}/${userConfigFile}" ]]; then
        configFile="${userConfigPath}/${userConfigFile}"
    fi

    if [[ -n "${configFile}" ]]; then
        if ! diff "${exampleConfigFilePath}" "${configFile}" 1>&2 >/dev/null
        then
            local warning="Discovered an old Fensalir user configuration "
            warning+="file ('${configFile}')."

            local message="Please review "
            message+="'${BOLD}${exampleConfigFilePath}${CLEAR}' "
            message+="and update your personal Fensalir user configuration "
            message+="settings as necessary."

            print_warning "${warning}" "${message}"
        fi
    fi
}
