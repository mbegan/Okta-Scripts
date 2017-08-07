
$user = "00uabxx4hlwm47RSV0h7"
$filter = 'actor.id eq "' + $user + '" or target.id eq "' + $user + '"'
$log2 = oktaListLogs -filter $filter -order DESCENDING -sinceDaysAgo 7 -until "2017-08-05T23:55:00.000Z"

#GET https://mattegantest.oktapreview.com/api/v1/logs?limit=100&sortOrder=DESCENDING&since=2017-07-29T00:40:57.923Z&until=2017-08-05T23:55:00.000Z&filter=actor.id eq "00uabxx4hlwm47RSV0h7" or target.id eq "00uabxx4hlwm47RSV0h7"

$bySbyT = New-Object System.Collections.Hashtable

$sevMap = @{'DEBUG'= 1;'INFO'=2;'WARN'=3;'ERROR'=4}

foreach ($log in $log2)
{
    #sift through potential issues with our keys
    if ($log.authenticationContext.externalSessionId)
    {
        $sessionId = $log.authenticationContext.externalSessionId
    } else {
        $sessionId = 'null'
    }

    if ($log.transaction.id)
    {
        $transactionId = $log.transaction.id
    } else {
        $transactionId = 'null'
    }

    if ($log.client.ipAddress)
    {
        $clientIp = $log.client.ipAddress
    } else {
        $clientIp = 'null'
    }

    #Do we already have a hash for this session, if not create it
    if (! $bySbyT[$sessionId])
    {
        $bySbyT[$sessionId] = New-Object System.Collections.Hashtable
        $bySbyT[$sessionId]['clientChanged'] = $false
        $bySbyT[$sessionId]['clients'] = New-Object System.Collections.Hashtable
        $bySbyT[$sessionId]['clients'].Add($clientIp, $log.client)

        $bySbyT[$sessionId]['actor'] = $log.actor
        $bySbyT[$sessionId]['maxSev'] = $log.severity
        $bySbyT[$sessionId]['eventTypes'] = New-Object System.Collections.ArrayList
        $bySbyT[$sessionId]['transactions'] = New-Object System.Collections.Hashtable
        
        #make sure our dates are not strings for easy compare
        if ($log.published -is [DateTime])
        {
            $bySbyT[$sessionId]['oldDate'] = $log.published
            $bySbyT[$sessionId]['newDate'] = $log.published
        } else {
            $bySbyT[$sessionId]['oldDate'] = (Get-Date $log.published)
            $bySbyT[$sessionId]['newDate'] = (Get-Date $log.published)
        }
    }

    #Add the event of every log processed
    $_c = $bySbyT[$sessionId]['eventTypes'].Add($log.eventType)

   #was this a failure?
    if ($log.outcome.result -eq 'FAILURE')
    {
        $bySbyT[$sessionId]['sawFailure'] = $true
    } else {
        $bySbyT[$sessionId]['sawFailure'] = $false
    }

    #was our user the actor or the target?
    if ($log.actor.id -eq $user)
    {
        $bySbyT[$sessionId]['role'] = "actor"
    } else {
        $bySbyT[$sessionId]['role'] = "target"
    }

    


    #Did the client change? add to hash and flip the clientChanged to $true
    if(! $bySbyT[$sessionId]['clients'][$clientIp])
    {
        $bySbyT[$sessionId]['clientChanged'] = $true
        $bySbyT[$sessionId]['clients'].Add($clientIp, $log.client)
    }

    #Is this log more severe than the current?
    if ($sevMap[$log.severity] -gt $sevMap[$bySbyT[$sessionId]['maxSev']])
    {
        $bySbyT[$sessionId]['maxSev'] = $log.severity
    }

    #Is this date older or newer than we have?
    if ($log.published -is [DateTime])
    {
        $thisDate = $log.published
    } else {
        $thisDate = (Get-Date $log.published)
    }
    if ($thisDate -gt $bySbyT[$sessionId]['newDate'])
    {
        $bySbyT[$sessionId]['newDate'] = $thisDate
    }
    if ($thisDate -lt $bySbyT[$sessionId]['oldDate'])
    {
        $bySbyT[$sessionId]['oldDate'] = $thisDate
    }

    if (! $bySbyT[$sessionId]['transactions'][$transactionId])
    {
        $bySbyT[$sessionId]['transactions'][$transactionId] = New-Object System.Collections.Hashtable
        $bySbyT[$sessionId]['transactions'][$transactionId]['events'] = New-Object System.Collections.ArrayList
    }

    #Finally add the full event so that the UI can fully expand if someone wants to drill all the way in... in here i just add the UUID
    $_c = $bySbyT[$sessionId]['transactions'][$transactionId]['events'].Add($log.uuid)
}