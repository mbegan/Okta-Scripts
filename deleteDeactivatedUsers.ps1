#Run with Caution
#Set "dryRun variable to false to make it go"


#try using 500, if you have issues drop it down, really only impacts the initial collection of users.
$limit = 500

#your org name from okta_org file

$org = 'matt'

#Verbose settings for this script
$verbose=$false
$oktaVerbose=$false

#set to false to really delete stuff
$dryRun = $true


[string]$desiredState = "DEPROVISIONED"

try
{
    $users = oktaListUsersbyStatus -status $desiredState -limit $limit -oOrg $org -Verbose:$verbose
}
catch
{
    Write-Warning($_.Exception.Message)
    Throw("_Failure_")
}


$c = 0
$total = $users.Count

foreach ($user in $users)
{
    $c++
    Write-Progress -Activity "Deleting User" -Status "Working on: " -CurrentOperation $user.id -PercentComplete (($c / $total)*100)

    #get a fresh copy of the user, just in case
    try
    {
        $user = oktaGetUserbyID -uid $user.id -oOrg $org -Verbose:$verbose
    }
    catch
    {
        Write-Host("Failure`tFetching User: " + $user.id + " Encountered: " + $_.Exception.Message) -ForegroundColor Red
        Continue
    }

    #Deactivate users that aren't already
    if ($user.status -ne $desiredState)
    {
        if (!$dryRun)
        {
            try
            {
                oktaDeactivateUserbyID -uid $user.id -oOrg $org -Verbose:$verbose
            }
            catch
            {
                Write-Host("Failure`tDeactivating User: " + $user.id + " Encountered: " + $_.Exception.Message) -ForegroundColor Red
                Continue
            }
        } else {
            Write-Host("I would have Deactivated User: " + $user.id + " if we weren't in Dry Run Mode")   
        }
    }

    #Delete users that are deactivated
    if (!$dryRun)
    {
        try
        {
            oktaDeleteUserbyID -uid $user.id -oOrg $org -Verbose:$verbose
        }
        catch
        {
            Write-Host("Failure`tDeleting User: " + $user.id + " Encountered: " + $_.Exception.Message) -ForegroundColor Red
            Continue
        }
        Write-Host("Success`tDeleted User: `t" + $user.id + "`t" + $user.profile.login)
    } else {
        Write-Host("I would have Deleted User: " + $user.id + " if we weren't in Dry Run Mode")  
    }
}
