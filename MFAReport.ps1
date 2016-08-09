Param
(
    [Parameter(Mandatory=$true)][alias('org','OktaOrg')][string]$oOrg
)

$Group = '00gzbdjvecVNYVGYHJJM'

$AllUsers = oktaGetGroupMembersbyId -oOrg $oOrg -gid $Group
$oktaVerbose = $true

$factorProviders = 
@{
    OKTA = @('push','question','sms','token:software:totp')
    GOOGLE = @('token:software:totp')
    SYMANTEC = @('token')
    RSA = @('token')
    DUO = @('web')
    YUBICO = @('token:hardware')
}

function oktaFactortoHash()
{
    param
    (
        $factors
    )

    $factorH = New-Object System.Collections.Hashtable
    foreach ($factor in $factors)
    {
        if (!$factorH[$factor.provider])
        {
            $factorH[$factor.provider] = New-Object System.Collections.Hashtable
        }
        if (!$factorH[$factor.provider][$factor.factorType])
        {
            #$factorH[$factor.provider][$factor.factorType] = New-Object System.Collections.ArrayList
            $factorH[$factor.provider][$factor.factorType] = $factor
        }
        #$_c = $factorH[$factor.provider][$factor.factorType].Add($factor)
    }
    return $factorH
}

function oktaGetFactorInfo()
{
    param
    (
        $factor
    )

    #if ($factor.status -eq 'ACTIVE')
    switch ($factor.provider)
    {
        'OKTA'
        {
            switch ($factor.factorType)
            {
                'sms'
                {
                    if ($factor.status -eq 'ACTIVE')
                    {
                        return ("A:" + $factor.profile.phoneNumber)
                    } else {
                        return ("I:" + $factor.profile.phoneNumber)
                    }
                }
                'question'
                {
                    if ($factor.status -eq 'ACTIVE')
                    {
                        return ("A:" + $factor.profile.question)
                    } else {
                        return ("I:" + $factor.profile.question)
                    }
                }
                'push'
                {
                    if ($factor.status -eq 'ACTIVE')
                    {
                        return ("A:" + $factor.profile.name)
                    } else {
                        return ("I:" + $factor.profile.name)
                    }
                }
                'token:software:totp'
                {
                    if ($factor.status -eq 'ACTIVE')
                    {
                        return ("A:" + $factor.profile.credentialId)
                    } else {
                        return ("I:" + $factor.profile.credentialId)
                    }
                }
                Default
                {
                    return $factor.status
                }
            }
        }
        'YUBICO'
        {
            switch ($factor.factorType)
            {
                'token:hardware'
                {
                    if ($factor.status -eq 'ACTIVE')
                    {
                        return ("A:" + $factor.profile.credentialId)
                    } else {
                        return ("I:" + $factor.profile.credentialId)
                    }
                }
                Default
                {
                    return $factor.status
                }
            }
        }
        Default
        {
            return $factor.status
        }
    }
}

$FactorbyUser = New-Object System.Collections.Hashtable
foreach ($u in $AllUsers)
{
    $factors = oktaGetFactorsbyUser -oOrg $oOrg -uid $u.id
    $samAccount = $u.profile.login.Split('@')[0].ToLower()
    $adUser = Get-ADUser -Identity $samAccount -Properties StreetAddress,l,st,c,employeeid,employeeGroup,employeeSubGroup,mail
    $hash = @{oktaUser = $u;adUser = $adUser;Factors = (oktaFactortoHash -factors $factors)}
    $FactorbyUser.Add($samAccount,$hash)
}

$col = New-Object System.Collections.ArrayList
foreach ($ukey in $FactorbyUser.Keys)
{
    $row = @{ userKey = $ukey
              oktaId = $FactorbyUser[$ukey]['oktaUser'].id
              UserPrincipalName = $FactorbyUser[$ukey]['adUser'].UserPrincipalName
              Country = $FactorbyUser[$ukey]['adUser'].c
              State = $FactorbyUser[$ukey]['adUser'].st
              City = $FactorbyUser[$ukey]['adUser'].l
              Street = $FactorbyUser[$ukey]['adUser'].StreetAddress
              Group = $FactorbyUser[$ukey]['adUser'].employeeGroup
              SubGroup = $FactorbyUser[$ukey]['adUser'].employeeSubGroup
              Email = $FactorbyUser[$ukey]['adUser'].mail
            }
    foreach ($prov in $factorProviders.Keys)
    {
        if (!($FactorbyUser[$ukey]['Factors'][$prov]))
        {
            foreach ($type in $factorProviders[$prov])
            {
                $row.Add(($prov + ":" + $type),$null)
                $row.Add(("has" + $prov + ":" + $type),0)
            }
        } else {
            foreach ($type in $factorProviders[$prov])
            {
                if ($FactorbyUser[$ukey]['Factors'][$prov][$type])
                {
                    $info = oktaGetFactorInfo -factor $FactorbyUser[$ukey]['Factors'][$prov][$type]
                    $row.Add(($prov + ":" + $type),$info)
                    $row.Add(("has" + $prov + ":" + $type),1)
                } else {
                    $row.Add(($prov + ":" + $type),$null)
                    $row.Add(("has" + $prov + ":" + $type),0)
                }
            }
        }
    }
    $obj = New-Object psobject -Property $row
    $_c = $col.Add($obj)
}

$col | Select userKey,UserPrincipalName,Email,Group,SubGroup,Street,City,State,Country,oktaID,OKTA:*,YUBICO:*,DUO:*,GOOGLE:*,RSA:*,SYMANTEC:* | Export-Csv -Path C:\temp\mfa.csv -Force -NoTypeInformation

function cleanupPendingFactors()
{
    foreach ($ukey in $FactorbyUser.Keys)
    {
        foreach ($provider in $FactorbyUser[$ukey]['factors'].Keys)
        {
            foreach ($type in $FactorbyUser[$ukey]['factors'][$provider].Keys)
            {
                foreach ($factor in $FactorbyUser[$ukey]['factors'][$provider][$type])
                {
                    if ('ACTIVE' -ne $factor.status)
                    {
                        Write-Host $ukey -> $provider -> $type -> $factor.id is $factor.status
                        try
                        {
                            oktaResetFactorbyUser -oOrg $oOrg -uid $FactorbyUser[$ukey]['oktaUser'].id -fid $factor.id
                        }
                        catch
                        {
                            Write-Host $_.exception
                        }
                    }
                }
            }
        }
    }
}