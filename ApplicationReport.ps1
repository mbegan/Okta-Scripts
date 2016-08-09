<#
    .SYNOPSIS 
        Generates a report of All active Applications and their associated assignment groups
    .DESCRIPTION
        Useful for generating a report of application ownership roles, saves results in a csv file
    .EXAMPLE
        ApplicationReport -oOrg prod
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
        [string]$ApplicationID
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

function AppDetails()
{
    param
    (
        $app
    )

    switch -Exact ($app.signOnMode)
    {

        'BOOKMARK'
        {
            return $app.settings.app.url
        }
        'BROWSER_PLUGIN'
        {
            #nothing distinguishable
            return $null
        }
        'AUTO_LOGIN'
        {
            #nothing distinguishable
            return $null
        }
        'SAML_1_1'
        {
            #probably specific to O365
            return $app.settings.app.domain
        }
        'WS_FEDERATION'
        {
            return $app.settings.app.wReplyURL
            break
        }
        'SAML_2_0'
        {
            switch -Exact ($app.name)
            {
                'template_saml_2_0'
                {
                    return $app.settings.app.destination
                }
                'salesforce'
                {
                    return ( $app.settings.app.instanceType + " :: " + $app.settings.app.loginUrl)
                }
                'newrelic'
                {
                    return  $app.settings.app.loginUrl
                }
                #'successfactors' 'servicenow'
                { (($_ -eq 'successfactors') -or ($_ -eq 'servicenow')) }
                {
                    return $app.settings.app.loginURL
                }
                'bigmachines'
                {
                    return $app.settings.app.siteURL
                }
                'jira_onprem'
                {
                    return $app.settings.app.baseURL
                }
                'concur'
                {
                    #nothing distinguishable?
                    return $null
                }
                'teachscape'
                {
                    return $app.settings.app.companyName
                }
                'docusign'
                {
                    return $app.settings.app.instanceType
                }
                'accellion'
                {
                    return $app.settings.app.subDomain
                }
                'amazon_aws'
                {
                    return $app.settings.app.identityProviderArn
                }
                'github_enterprise'
                {
                    return $app.settings.app.githubUrl              
                }
                'opendns'
                {
                    #nothing distinguishable?
                    return $null
                }
                default
                {
                    if ($app.settings.signOn.destination -like '*') { return $app.settings.signOn.destination }
                    elseif ($app.settings.app.loginURL -like '*')   { return $app.settings.app.loginURL }
                    elseif ($app.settings.app.loginUrl -like '*')   { return $app.settings.app.loginUrl }
                    elseif ($app.settings.app.siteUrl -like '*')    { return $app.settings.app.siteUrl }
                    elseif ($app.settings.app.siteURL -like '*')    { return $app.settings.app.siteURL }
                    elseif ($app.settings.app.baseUrl -like '*')    { return $app.settings.app.baseUrl }
                    elseif ($app.settings.app.baseURL -like '*')    { return $app.settings.app.baseURL }
                    else
                    {
                        #Write-Host $app.id : $app.label : $app.name : zyzz
                        #$app.settings | ConvertTo-Json
                        return $null
                    }
                }
            }
            break
        }
        default
        {
            if ('active_directory' -eq $app.name)
            {
                #Write-Host $app.id : $app.label : $app.settings.app.namingContext
                return $app.settings.app.namingContext
            }
            return $null
        }
    }
}

$col1 = New-Object System.Collections.ArrayList
foreach ($app in $apps)
{
    #fetch the groups that are used to assign the app to users
    $appgroups = oktaGetAppGroups -oOrg $oOrg -AppId $app.id
    if ($appgroups)
    {
        foreach($group in $appgroups)
        {
            try
            {
                #fetch the details of the group
                $oktagroup = oktaGetGroupbyId -oOrg $oOrg -groupId $group.id
            }
            catch
            {
                Write-Error "group didn't exist?"
            }

            $params = @{ Application = $app
                         Priority = $group.priority
                         Updated = $group.lastUpdated
                         Group = $oktagroup
                       }
            $_c = $col1.add($params)
        }
    } else {
            $params = @{ Application = $app
                         Priority = 0
                         Updated = $null
                         Group = $false
                       }
            $_c = $col1.add($params)
    }
}

$col2 = new-object System.Collections.ArrayList
foreach ($c in $col1)
{
    $param = @{ AppID = $c.Application.id
                Application = $c.Application.name
                AssignmentPriority = $c.Priority
                Description = $c.Application.label
                appSignOnMOde = $c.Application.signOnMode
                appUserNameTemplate = $c.Application.credentials.userNameTemplate.template
                appVpnNotification = $c.Application.settings.notifications.vpn.network.connection
                appHideWeb = $c.Application.visibility.hide.web
                appHideMobile = $c.Application.visibility.hide.iOS
                appDetail = (AppDetails -app $c.Application)
                GroupClass = $null
                GroupName = 'NoGroup'
                GroupDesc = $null
                GroupID = $null
              }
    if ($c.Group)
    {
        $param.GroupClass = $c.Group.ObjectClass[0]
        $param.GroupName = $C.Group.profile.name
        $param.GroupDesc = $C.Group.profile.description
        $param.GroupID = $C.Group.id
    }
    $row = New-Object psobject -Property $param
    $_c  = $col2.add($row)
}

$fstamp = (Get-Date).ToString(“yyyyMMdd")
$file = $env:TEMP + '\' + $oOrg + "_ApplicationReport_" + $fstamp + '.csv'

$col2 | Select AppID,Application,AssignmentPriority,Description,appSignOnMOde,appUserNameTemplate,`
 appVpnNotification,appHideWeb,appHideMobile,appDetail,GroupID,GroupName,GroupClass,GroupDesc `
 | Export-Csv -Path ($file) -NoTypeInformation

 . $file