<#
    .SYNOPSIS 
        Generates a report of All users assigned to a given application along with base details about the application user profile.
    .DESCRIPTION
        Useful for generating a report of user assigned to a given application and the downstream identifiers for the app
    .EXAMPLE
        ApplicationExternalIdReport -oOrg prod
        This command runs a report against the org defined 
        as 'prod' the result of the report is {org}_ApplicationReport_{YYYYMMDD}.csv
    .LINK
        https://github.com/mbegan/Okta-Scripts
        https://support.okta.com/help/community
        http://developer.okta.com/docs/api/getting_started/design_principles.html
#>
Param
(
    [Parameter(Mandatory=$false)]
        [alias('org','OktaOrg')]
        [string]$oOrg=$oktaDefOrg,
    [Parameter(Mandatory=$false)]
        [ValidateLength(20,20)]
        [alias('aid','appid')]
        [string]$ApplicationID,
        [Parameter(Mandatory=$false)]
        [ValidateLength(1,255)]
        [alias('appname')]
        [string]$ApplicationName="amazon_aws_sso"
)

Import-Module Okta
if (!(Get-Module Okta))
{
    throw 'Okta module not loaded...'
}

#preseve value
$curVerbosity = $oktaVerbose

if ( [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference )
{
    $oktaVerbose = $true
} else {
    $oktaVerbose = $false
}

#Get all the Apps within the org
if ($ApplicationID)
{
    $apps = oktaGetAppbyId -oOrg $oOrg -aid $ApplicationID
} else {
    $apps = oktaGetActiveApps -oOrg $oOrg
}

$col1 = New-Object System.Collections.ArrayList

foreach ($app in $apps)
{
    if ($ApplicationName)
    {
        if ($ApplicationName -ne $app.name)
        {
            #if they provided an application name we want to skip any application that isn't that application name.
            Write-Verbose("Skipping application: " + $app.label)
            continue
        }
    }
    #fetch the users (appUsers) that are assigned to said app
    $appUsers = oktaGetUsersbyAppID -oOrg $oOrg -aid $app.id

    if ($appUsers)
    {
        foreach($appUser in $appUsers)
        {
            try
            {
                #fetch the details of the group because the appGroup object is limited
                $oUser = oktaGetUserbyID -oOrg $oOrg -uid $appUser.id
            }
            catch
            {
                #this shouldn't ever happen
                Write-Error "Okta User didn't exist!?!"
                continue
            }

            $param = @{ 
                        appName = $app.name
                        appStatus = $app.status
                        appLabel = $app.label
                        appCreated = $app.created
                        appUpdated = $app.lastUpdated
                        appFeatures = $app.features -join " : "
                        appUserNameTemplate = $app.credentials.userNameTemplate.template
                        appAcsURL = $app.settings.app.acsURL
                        appEntityID = $app.settings.app.entityID
                        userID = $ouser.id
                        userStatus = $ouser.status
                        userUpdated = $ouser.lastUpdated
                        userSource = $oUser.credentials.provider.name
                        userFirstName = $ouser.profile.firtName
                        userLastName = $ouser.profile.lastName
                        userLogin = $ouser.profile.login
                        userEmail = $ouser.profile.email
                        appUserID = $appUser.id
                        appUserStatus = $appUser.status
                        appUserSyncState = $appUser.syncState
                        appUserScope = $appUser.scope
                        appUserLastSync = $appUser.lastSync
                        appUserCreated = $appUser.created
                        appUserExternalId = $appUser.externalId
                        appUserCredUserName = $appUser.credentials.userName
                        appUserProfileDisplayName = $appUser.profile.displayName
                        appUserProfileEmail = $appUser.profile.email
                    }
                $row = New-Object psobject -Property $param
                $_c  = $col1.add($row)
        }
    } else {
        #no users assigned to the app in question so we just jam an empty row in to show the app details.
        $param = @{ 
            appName = $app.name
            appStatus = $app.status
            appLabel = $app.label
            appCreated = $app.created
            appUpdated = $app.lastUpdated
            appFeatures = $app.features -join " : "
            appUserNameTemplate = $app.credentials.userNameTemplate.template
            appAcsURL = $app.settings.app.acsURL
            appEntityID = $app.settings.app.entityID
            userID = $null
            userStatus = $null
            userUpdated = $null
            userSource = $null
            userFirstName = $null
            userLastName = $null
            userLogin = $null
            userEmail = $null
            appUserID = $null
            appUserStatus = $null
            appUserSyncState = $null
            appUserScope = $null
            appUserLastSync = $null
            appUserCreated = $null
            appUserExternalId = $null
            appUserCredUserName = $null
            appUserProfileDisplayName = $null
            appUserProfileEmail = $null
           }
        $row = New-Object psobject -Property $param
        $_c  = $col1.add($row)
    }
}

$fstamp = (Get-Date).ToString(“yyyyMMdd")
$file = $oOrg + "_ApplicationExternaleIDReport_" + $fstamp + '.csv'

$col1 | select appName,  appStatus, appLabel, appCreated, appUpdated, appFeatures, appUserNameTemplate,`
    appAcsURL, appEntityID, userID, userStatus, userUpdated, userSource, userFirstName,`
    userLastName, userLogin, userEmail, appUserID, appUserStatus, appUserSyncState,`
    appUserScope, appUserLastSync, appUserCreated, appUserExternalId, appUserCredUserName,`
    appUserProfileDisplayName, appUserProfileEmail | Export-Csv -Path ($file) -NoTypeInformation
