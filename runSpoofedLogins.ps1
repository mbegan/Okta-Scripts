$userAgents = Import-Csv -Path C:\users\megan\Downloads\userAgents.csv

$ipAddresses = Import-csv -Path C:\users\megan\Downloads\IPAddresses.csv

$users = @('matt.egan', 'mark.stevens','ed.king', 'eric.smith', 'hassen')

$users = @('matt.egan', 'mark.stevens', 'megan')


$pwgood = 'Password3'
$pwbadd = 'asdf1234'
$org = $oktaDefOrg
$org = "okp1"

$passwords = @( $pwgood, $pwgood, $pwgood, $pwbadd, $pwbadd, $pwgood, $pwgood, $pwbadd, $pwgood, $pwgood, $pwgood, $pwgood, $pwbadd, $pwbadd )
$Allapps = oktaListApps -status ACTIVE
$apps = New-Object System.Collections.ArrayList
$valid = @('SAML_2_0','BOOKMARK')
foreach ($app in $Allapps)
{
    if ( ($valid.Contains($app.signOnMode)) -and ($app._links.appLinks.href) )
    {
        $_c = $apps.Add($app)
    }
}

$pwnum = 0
$loopCount = 1
$loopMax = 1000
while ($loopCount -le $loopMax)
{   
    $uanum = Get-Random -Minimum 0 -Maximum ($userAgents.Count)
    $ipnum = Get-Random -Minimum 0 -Maximum ($ipAddresses.Count)
    $unnum = Get-Random -Minimum 0 -Maximum ($users.Count)

    $fakeUA = $userAgents[$uanum].useragent.ToString()
    $fakeIP = $ipAddresses[$ipnum].ipaddress.ToString()
    $username = $users[$unnum].ToString()

    $altHeaders = New-Object System.Collections.Hashtable
    if ($fakeUA)
    {
        if ($UserAgent -like "*")
        {
            $altHeaders.Add('UserAgent', $fakeUA)
        }
    }
    if ($fakeIP)
    {
        $altHeaders.Add('X-Forwarded-For', $fakeIP)
    }

    
    Write-Progress -PercentComplete ( $loopCount / $loopMax) -Activity 'Generating Logins' -Status ($username + " : " + $fakeIP + " : " + $fakeUA) -Id 1
    try
    {
        $auth = oktaCheckCreds -oOrg $org -ipAddress $fakeIP  -UserAgent $fakeUA -username $username -password $passwords[$pwnum] -Verbose
    }
    catch
    {
        Write-Warning($_.Exception.Message)
        $auth = $false
    }

    if ('SUCCESS' -eq $auth.status)
    {
        Write-Host($auth.status)
        $scd = ($oktaOrgs[$org].baseUrl + "/login/sessionCookieRedirect?token=" + $auth.sessionToken + "&redirectUrl=" + $oktaOrgs[$org].baseUrl)
        $Authreq = Invoke-WebRequest -SessionVariable oktaSession -Uri $scd -Headers $altHeaders -UserAgent $fakeUA
        $allmyApps = oktaListApps -uid $auth._embedded.user.id -oOrg $org
        $myApps = New-Object System.Collections.ArrayList
        foreach ($app in $allmyApps)
        {
            if ( ($valid.Contains($app.signOnMode)) -and ($app._links.appLinks.href) )
            {
                $_c = $myApps.Add($app)
            }
        }
        #how many apps for this iteration are we going to fetch?
        $apnum = Get-Random -Minimum 0 -Maximum ($myApps.Count-1)
        $num = 1
        while ($num -le $apnum)
        {
            #which app index num are we going to use?
            $apInum = Get-Random -Minimum 0 -Maximum ($myApps.Count-1)
            Write-Progress -PercentComplete ($num / ($apnum+1)) -Activity 'App Logins' -Status $myApps[$apInum].label -Id 2 -ParentId 1
            try
            {
                $req = Invoke-WebRequest -WebSession $oktaSession -Uri $myApps[$apInum]._links.appLinks[0].href -MaximumRedirection 3 -Headers $altHeaders -UserAgent $fakeUA
            }
            catch
            {
                Write-Warning($_.Exception.Message)
            }
            $num++
        }
        #take a shot at another app of all apps, will fail sometimes, expected.
        $apnum = Get-Random -Minimum 0 -Maximum ($apps.Count-1)
        Write-Progress -PercentComplete (($num+1) / ($apnum+1)) -Activity 'App Logins' -Status $apps[$apnum].label -Id 2 -ParentId 1
        try
        {
            $req = Invoke-WebRequest -WebSession $oktaSession -Uri $apps[$apnum]._links.appLinks[0].href -MaximumRedirection 3 -Headers $altHeaders -UserAgent $fakeUA
        }
        catch
        {
            Write-Warning($_.Exception.Message)
        }
        Write-Progress -PercentComplete 100 -Activity 'App Logins' -Status "Done" -Id 2 -ParentId 1 -Completed
        try
        {
            $req = Invoke-WebRequest -Method Delete -Uri ($oktaOrgs[$org].baseUrl + "/api/v1/sessions/me" ) -WebSession $oktaSession -Headers $altHeaders -UserAgent $fakeUA
            Remove-Variable -Name oktaSession -Force
        }
        catch
        {
            continue
        }
    }

    $pwnum++
    if ($pwnum -eq $passwords.Count)
    {
        $pwnum=0
    }

    $loopCount++
    sleep -Milliseconds (Get-Random -Minimum 323 -Maximum 6464)
}