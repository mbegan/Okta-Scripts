<#
    .SYNOPSIS 
        Retrieves logs (syslogV2) from okta, converts them to jsonl format and saves them to a local file
    .DESCRIPTION
        Useful for extracting logs from Okta and storing them locally
    .EXAMPLE
        This command will start a job that collects logs from a defined org with a given startDate (since)
        the resulting events will be written into a timestamped file (based on published date of the log) OktaLog_{oOrg}_{YYYY-MM-DD}.jsonl

        powershell -file saveEventLogsV2.ps1 -oOrg <orgName> -startDate <YYYY-MM-DD>

    .LINK
        https://github.com/mbegan/Okta-Scripts
        https://support.okta.com/help/community
        https://developer.okta.com/docs/api/getting_started/design_principles
#>
Param
(
    [Parameter(Mandatory=$false)]
        [alias('org','OktaOrg')]
        [string]$oOrg=$oktaDefOrg,
    [Parameter(Mandatory=$false)]
        [alias('since')]
        [string]$startDate
)

#jsonlines

if (Test-Path -Path (".logState_" + $oOrg))
{
    try
    {
        $state = Get-Content -Path (".logState_" + $oOrg) -ErrorAction Continue
        $state = ConvertFrom-Json -InputObject $state[-1]
    }
    catch
    {
        Write-Debug("No existing .logState file found")
    }
}

Import-Module Okta
if ($module = Get-Module Okta)
{
    $version = [decimal][string]$module.Version.ToString()
    if ($version -lt 2.3)
    {
        throw 'Okta module verion less than 2.3, must upgrade for this script to work'
    } else {
        Write-Verbose("Found Okta Module version " + $version.ToString()  + " continuing")
    }
} else {
    throw 'Okta module not loaded...'
}

function writeState()
{
    param
    (
        $next,
        $since
    )
    Write-Verbose("Writing State File with next: '" + $next + "' and since '" + $since + "'")
    $state = @{ next = $next; since = $since }
    $state = ConvertTo-Json -InputObject $state -Compress
    Add-Content -Value $state -Path (".logState_" + $oOrg)
}

#preseve value
$curVerbosity = $oktaVerbose

if ( [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference )
{
    $oktaVerbose = $true
} else {
    $oktaVerbose = $false
}

if ($state.next)
{
    $next = $state.next
    $daystofetch = 1 #(assuming so anyway)
} else {

    if ($state.since)
    {
        $startDate = $state.since    
    }
    try
    {
        $startDate = Get-Date $startDate
        $now = Get-Date
        $span = New-TimeSpan -Start $startDate -End $now
    }
    catch
    {
        throw($_.Exception.Message)
    }
    $next = $false
    $daystofetch = ([math]::Floor($span.TotalDays))
}

while ($daystofetch -gt 0)
{
    if (! $next)
    {
        $since = $now.AddDays(($daystofetch *-1))
        if ($daystofetch -eq 1)
        {
            #Make this an open ended query once we hit 1 day
            $until=$null
        } else {
            $until = $since.AddDays(1)
        }
        Write-Verbose("fetch logs from " + $since + " to " + $until)
        $events = oktaListLogs -oOrg $oOrg -Verbose:$oktaVerbose -sinceDaysAgo $daystofetch -untilDaysAgo ($daystofetch-1)
    } else {
        Write-Verbose("fetch logs using next link: " + $next)
        $events = oktaListLogs -oOrg $oOrg -Verbose:$oktaVerbose -next $next
    }
    
    foreach ($event in $events)
    {
        if ($event.published -is [DateTime])
        {      
	        $pubd = $event.published.ToString("o")
        } else {
            $pubd = $event.published.ToString()
        }
        $out = "OktaLog_" + $oOrg + "_"
        $out += $pubd.Substring(0,10)
        $out += ".jsonl"
        $line = ConvertTo-Json -InputObject $event -Depth 12 -Compress
        Add-Content -Value $line -Path $out
        $stateSince = $event.published
    }

    $stateSince = $event.published
    if ($Global:nextNext -is [string])
    {
        $stateNext = $Global:nextNext
    } else { $stateNext = $false }
    writeState -since $stateSince -next $stateNext
    $daystofetch--
}

#restore verbosity level
$oktaVerbose = $curVerbosity
