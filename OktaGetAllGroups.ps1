$groups = oktaGetGroupsAll -oOrg prod

$col = New-Object System.Collections.ArrayList
foreach ($g in $groups)
{
    if ($g.objectClass -eq 'okta:windows_security_principal')
    {
        $props = @{
                    OktaId = $g.id
                    Guid = (oktaExternalIdtoGUID -externalId $g.profile.externalId).Guid
                    Name = $g.profile.name
                    samAccountName = $g.profile.samAccountName
                    dn = $g.profile.dn
                    winQualName = $g.profile.windowsDomainQualifiedName
                    lastUpdated = $g.lastUpdated
                    lastMembershipUpdated = $g.lastMembershipUpdated
                }
        $obj = New-Object psobject -Property $props
        $_c = $col.Add($obj)
        
    } elseif ($g.objectClass -ne 'okta:user_group')
    {
        $g
    }
}

$col | Export-Csv -Path C:\temp\OktaAdGroups.csv -NoTypeInformation
