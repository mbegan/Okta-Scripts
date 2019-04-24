Import-Module Okta

$myOrg = 'okp1'
$myAppId = '0oa1cz6mppvsqMnK21d8'
$myLimit = 500
$oktaVerbose=$true
$myVerbose=$true

#Get all the Users assgined to the app
$appUsers = oktaGetUsersbyAppID -oOrg $myOrg -aid $myAppId -limit $myLimit -Verbose:$myVerbose

#Get all of the groups used to assign the app
$appGroups = oktaGetAppGroups -oOrg $myOrg -aid $myAppId -Verbose:$myVerbose

#turn the array of groups into a hash that is keyed by groupId for easier reconcilliation at the next step.
$appGroupHash = New-Object System.Collections.Hashtable
foreach ($appGroup in $appGroups)
{
    $appGroupHash.Add($appGroup.id,$appGroup)
}

#a few arrays to store the "report" in
$joinedReport = New-Object System.Collections.ArrayList
$multiLineReport = New-Object System.Collections.ArrayList

foreach ($appUser in $appUsers)
{
    $allSamlRoles = New-Object System.Collections.ArrayList
    foreach ($samlRole in $appUser.profile.samlRoles)
    {
        $_c = $allSamlRoles.Add($samlRole)
    }
    $usersGroups = oktaGetGroupsbyUserId -oOrg $myOrg -uid $appUser.id -Verbose:$myVerbose
    foreach ($gId in $appGroupHash.Keys)
    {
        if ($usersGroups.Contains($gId))
        {
            $thisGroup = $appGroupHash[$gId]
            foreach ($groupSamlRole in $thisGroup.profile.samlRoles)
            {
                if (!$allSamlRoles.Contains($groupSamlRole))
                {
                    $_c = $allSamlRoles.Add($groupSamlRole)
                }
            }
        }
    }
    #option one, join the array of samlroles and stuff one line into the report
    $stringSamlRoles = ($allSamlRoles -join ";")
    $line = @{ externalID = $appUser.externalId; firstname = $appUser.profile.firstName; lastname = $appUser.profile.lastname; email = $appUser.profile.email; samlRoles = $stringSamlRoles }
    $row = New-Object psobject -Property $line
    $_c = $joinedReport.Add($row)

    #option two, stuff a line in the report for each role
    foreach ($samlRole in $allSamlRoles)
    {
        $line = @{ externalID = $appUser.externalId; firstname = $appUser.profile.firstName; lastname = $appUser.profile.lastname; email = $appUser.profile.email; samlRole = $samlRole }
        $row = New-Object psobject -Property $line
        $_c = $multiLineReport.Add($row)
    }
}

($joinedReport | Select-Object externalID, firstname, lastname, email, samlRoles) | Format-Table
($multiLineReport | Select-Object externalID, firstname, lastname, email, samlRole) | Format-Table