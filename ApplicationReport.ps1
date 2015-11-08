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
}

$col2 = new-object System.Collections.ArrayList
foreach ($c in $col1)
{
    $param = @{ Application = $c.Application.name
                AppDesc= $c.Application.label
                AppUserNameTemplate = $c.Application.credentials.userNameTemplate.template
                AssignmentPriority = $c.Priority
                GroupClass = $c.Group.ObjectClass[0]
                GroupName = $C.Group.profile.name
                GroupDesc = $C.Group.profile.description
                GroupID = $C.Group.id
              }
    $row = New-Object psobject -Property $param
    $_c  = $col2.add($row)
}

$col2 | Export-Csv -Path OktaAppReport.csv -NoTypeInformation