Import-Module Okta
$oktaVerbose = $true
$org = 'prod'

#Get all the active Apps within the org
$activeapps = oktaGetActiveApps -oOrg $org

$col1 = New-Object System.Collections.ArrayList
foreach ($app in $activeapps)
{
    #fetch the groups that are used to assign the app to users
    $appgroups = oktaGetAppGroups -oOrg $org -AppId $app.id
    if ($appgroups)
    {
        foreach($group in $appgroups)
        {
            try
            {
                #fetch the details of the group
                $oktagroup = oktaGetGroupbyId -oOrg $org -groupId $group.id
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
            $params = @{ Application = $app; Priority = 0 }
            $_c = $col1.add($params)
    }
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

$col2 = new-object System.Collections.ArrayList
foreach ($c in $col1)
{
    $param = @{ AppID = $c.Application.id
                Application = $c.Application.name
                Description = $c.Application.label
                AssignmentPriority = $c.Priority
                appSignOnMOde = $c.Application.signOnMode
                appUserNameTemplate = $c.Application.credentials.userNameTemplate.template
                appDetail = (AppDetails -app $c.Application)
                GroupClass = $c.Group.ObjectClass[0]
                GroupName = $C.Group.profile.name
                GroupDesc = $C.Group.profile.description
                GroupID = $C.Group.id
              }
    $row = New-Object psobject -Property $param
    $_c  = $col2.add($row)
}

$col2 | Export-Csv -Path OktaAppReport.csv -NoTypeInformation