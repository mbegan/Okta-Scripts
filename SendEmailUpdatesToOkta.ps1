Param
(
    [Parameter(Mandatory=$true)][alias('org','OktaOrg')][string]$oOrg
)

#This group is the 'All - xxx' Group, cleanest way to grab just active xxx user accounts.
$Group = '00gzbdjvecVNYVGYHJJM'

#Get all the Okta users that are in the Group
$VarianOktaUsers = oktaGetGroupMembersbyId -oOrg $oOrg -gid $Group

#Get all the AD users profiles
$VarianADUsers = oktaGetUsersbyAppID -oOrg $oOrg -aid $oktaOrgs.$org.ProfileMaster

#make a hashtable with the OktaUsers
$vous = New-Object System.Collections.Hashtable
foreach ($vou in $VarianOktaUsers)
{
    $vous.Add($vou.id,$vou)
}
Remove-Variable -Name VarianOktaUsers

#Make a hashtable with the ADProfiles
$vaps = New-Object System.Collections.Hashtable
foreach ($vap in $VarianADUsers)
{
    $vaps.Add($vap.id,$vap)
}

Remove-Variable -Name VarianADUsers


#Combine the two bits into one thingy
$UserProfiles = New-Object System.Collections.Hashtable
foreach ($id in $vous.Keys)
{
    if ($vaps[$id])
    {
        $userProfile = @{Okta = $vous[$id];AD = $vaps[$id]}
        $UserProfiles.Add(($vaps[$id].profile.samAccountName.ToLower()),$userProfile)
    } else {
        Write-Warning (("No AD Profile exists for " + $vous[$id].profile.login + " : " + $id))
    }
}

Remove-Variable -Name vous
Remove-Variable -Name vaps

$textinfo = (Get-Culture).TextInfo
$needupdates = 0
#Flip through the list and find users needin updates
Write-Host ("samAccountName`tOkta Email Value`tAD Email Value")
foreach ($user in $UserProfiles.Keys)
{
    #If the AD profile email isn't the same as the okta user email call it out
    if ($UserProfiles[$user].AD.profile.email)
    {
        if ( ($UserProfiles[$user].AD.profile.email.ToLower()) -ne ($UserProfiles[$user].Okta.profile.email.ToLower()) )
        {
            $needupdates++
            try
            {
                $parts = $UserProfiles[$user].AD.profile.email.Split("@")
                $left = $textinfo.ToTitleCase( $parts[0].ToLower() )
                $right = $parts[1].ToLower()
                $email = $left + "@" + $right
                Write-Host ($user + "`t") -NoNewline
                Write-Host ($UserProfiles[$user].Okta.profile.email.ToLower() + "`t" + $email )
                $update = @{email = $email}
                $UserProfiles[$user].NewOkta = oktaUpdateUserProfilebyID -oOrg $oOrg -uid $UserProfiles[$user].Okta.id -Profile $update -partial
            }
            catch
            {
                Write-Warning (($_.Exception.Message + " occured when updating email for " + $user))
            }
        }
    } else {
        Write-Warning ($user + " Doesn't have an email in Okta's presentation of AD")
    }
}

Write-Host $needupdates