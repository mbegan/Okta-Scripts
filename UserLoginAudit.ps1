Param
(
    [Parameter(Mandatory=$true)][alias('org','OktaOrg')][string]$oOrg
)

$oktausers = oktaListUsers -oOrg $oOrg

$buckets = New-Object System.Collections.Hashtable

foreach ($user in $oktausers)
{
    OktaUserfromJson -user $user
    if (!$buckets[$user.status])
    {
        $buckets[$user.status] = New-Object System.Collections.ArrayList
    }
    $_c = $buckets[$user.status].Add($user)
}

$Active = New-Object System.Collections.Hashtable
$today = Get-Date
$ranges = @(7,21,30,60,90,120,150,180,360,500,1000)

#$oneWeek = $today.AddDays(-7)
#$oneMonth = $today.AddDays(-30)
#$threeMonth = $today.AddDays(-90)
#$SixMonth = $today.AddDays(-180)
#$1Year = $today.AddDays(-366)

foreach ($user in $buckets.ACTIVE)
{
    if (!$user.lastLogin)
    {
            if (!$Active['NoLogin'])
            {
                #$Active['NoLogin'] = New-Object System.Collections.ArrayList
                $Active['NoLogin'] = 0
            }
        #$_c = $Active['NoLogin'].Add($user)
        $Active['NoLogin']++
        continue
    }

    $span = New-TimeSpan -Start $user.lastLogin -End $today
    foreach ($r in $ranges)
    {
        if ($span.TotalDays -lt $r)
        {
            if (!$Active[$r])
            {
                #$Active[$r] = New-Object System.Collections.ArrayList
                $Active[$r] = 0
            }
            #$_c = $Active[$r].Add($user)
            $_c = $Active[$r]++
            break
        }
    }
}