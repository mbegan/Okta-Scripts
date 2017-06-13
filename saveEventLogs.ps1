<#
    .SYNOPSIS 
        Retrieves logs from okta, converts them to jsonl format and saves them to a local file
    .DESCRIPTION
        Useful for extracting events from Okta and storing them locally
    .EXAMPLE
        This command will start a job that collects events from a defined org with a given startDate 
        the resulting events will be written into a timestamped file (based on published date of the event) OktaEvent_{oOrg}_{YYYY-MM-DD}.jsonl
    .LINK
        https://github.com/mbegan/Okta-Scripts
        https://support.okta.com/help/community
        http://developer.okta.com/docs/api/getting_started/design_principles.html
#>
Param
(
    [Parameter(Mandatory=$false)]
        [alias('org','OktaOrg')]
        [string]$oOrg=$oktaDefOrg,
    [Parameter(Mandatory=$false)]
        [string]$startDate
)

#jsonlines
try
{
    $state = Get-Content -Path (".state_" + $oOrg) -ErrorAction Continue
    $state = ConvertFrom-Json -InputObject $state[-1]
}
catch
{
    Write-Debug("No existing .state file found")
}

if ($state.until)
{
    $startDate = $state.until
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

Import-Module Okta
if (!(Get-Module Okta))
{
    throw 'Okta module not loaded...'
}

function writeState()
{
    param
    (
        $after,
        $until,
        $oOrg
    )
    $state = @{ until = $until; after = $after }
    $state = ConvertTo-Json -InputObject $state -Compress
    Add-Content -Value $state -Path (".state_" + $oOrg)
}

#preseve value
$curVerbosity = $oktaVerbose

if ( [System.Management.Automation.ActionPreference]::SilentlyContinue -ne $VerbosePreference )
{
    $oktaVerbose = $true
} else {
    $oktaVerbose = $false
}


$daystofetch = ([math]::Floor($span.TotalDays))
$after = $false
if ($state.after)
{
    $after=$state.after
}

while ($daystofetch -gt 0)
{
    $since = $now.AddDays(($daystofetch *-1))
    $until = $since.AddDays(1)
    Write-Verbose("fetch logs from " + $since + " to " + $until)
    $events = oktaListEvents -oOrg $oOrg -since $since -until $until -after $after
    foreach ($event in $events)
    {
	$pubd = $event.published.ToString("o")
        $out = "OktaEvent_" + $oOrg + "_"
        $out += $pubd.Substring(0,10)
        $out += ".jsonl"
        $line = ConvertTo-Json -InputObject $event -Depth 12 -Compress
        Add-Content -Value $line -Path $out
        $after = $event.eventId
    }
    writeState -after $after -until $until -oOrg $oOrg
    $daystofetch--
}
