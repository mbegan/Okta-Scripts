Import-Module okta
$oktaVerbose = $true
$org = 'prod'

#Get the ID of your admin application, easiest way i know is to run a report
#filter the report by 'Okta Administration' the appid is printed along with every action
#cheat like I do an expand your okta org definition to keep quick tabs on it 
$adminAppID = $oktaOrgs.$org.AdminAID

#Collect a list of users that are assigned to the admin application
$admins = oktaGetUsersbyAppID -oOrg $org -aid $oktaOrgs.prod.AdminAID

$byUser = New-Object System.Collections.ArrayList

#loop through the admins, retrieve their role(s)
foreach ($a in $admins)
{
    $user = oktaGetUserbyID -oOrg $org -userName $a.id
    $roles = oktaGetRolesByUserId -oOrg $org -uid $a.id
    Add-Member -InputObject $user -MemberType NoteProperty -Name roles -Value $roles

    $_c = $byUser.Add($user)
}

#create a report
$col1 = New-Object System.Collections.ArrayList

foreach ($user in $byUser)
{
    foreach ($role in $user.roles)
    {
        $param = @{ role = $role.label
                    type = $role.type
                    UserRoleCreated = $role.created
                    UserRoleupdated = $role.lastUpdated
                    userCreated = $user.created
                    userUpdated = $user.lastUpdated
                    userLastLogin = $user.lastLogin
                    userCredsType = $user.credentials.provider.type
                    userCredsProv = $user.credentials.provider.name
                    status = $role.status
                    userName = $user.profile.login
                    firstName = $user.profile.firstName
                    lastName = $user.profile.lastName
                    userid = $user.id
                  }
        $row = New-Object psobject -Property $param
        $_c = $col1.Add($row)
    }
}

$col1 | Export-Csv -Path OktaAdminReport.csv -NoTypeInformation
