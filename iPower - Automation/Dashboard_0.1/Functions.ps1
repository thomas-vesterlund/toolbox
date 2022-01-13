Function HmcLogon {
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$User,
        [Parameter(Mandatory=$true)][String]$Password
    )

$LogonXmlBody = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<LogonRequest xmlns="http://www.ibm.com/xmlns/systems/power/firmware/web/mc/2012_10/"
    schemaVersion="V1_1_0">
    <Metadata>
        <Atom/>
    </Metadata>
    <UserID kb="CUR" kxe="false">$($User)</UserID>
    <Password kb="CUR" kxe="false">$($Password)</Password>
</LogonRequest>
"@

    # PERFORM API LOG ON
    $LogonRestUri = "https://$($Server):12443/rest/api/web/Logon"
    $LogonHeaders = @{
        "Content-Type" = "application/vnd.ibm.powervm.web+xml; type=LogonRequest"
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    }
    Try {
        $LogonResponse = Invoke-RestMethod -Method PUT -Uri $LogonRestUri -Headers $LogonHeaders -Body $LogonXmlBody
    } Catch {
        $StreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $StreamReader.BaseStream.Position = 0
        $ErrResp = $StreamReader.ReadToEnd()
        $StreamReader.Close()

        Write-Host -ForegroundColor Cyan $_.Exception.Message
        Write-Host -ForegroundColor Yellow $ErrResp

        throw "HmcLogon: $($_.Exception.Message)"
    }
    $Token = $LogonResponse.LogonResponse."X-API-Session"."#text"
    Write-Host -ForegroundColor Green "Logon Successful"
    return $Token
}

Function HmcLogoff {
    Param (
        [Parameter(Mandatory=$true)][String]$Server,
        [Parameter(Mandatory=$true)][String]$Token
    )
    
    $LogoffRestUri = "https://$($Server):12443/rest/api/web/Logon"
    $LogoffHeaders = @{
        "X-API-Session" = $Token
    }
    Try {
        $LogoffResponse = Invoke-RestMethod -Method DELETE -Uri $LogoffRestUri -Headers $LogoffHeaders
    } Catch {
        $StreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $StreamReader.BaseStream.Position = 0
        $ErrResp = $StreamReader.ReadToEnd()
        $StreamReader.Close()

        Write-Host -ForegroundColor Cyan $_.Exception.Message
        Write-Host -ForegroundColor Yellow $ErrResp

        return
    }

    Write-Host -ForegroundColor Green "Logoff Successful"
    return
}

Function HmcRestGet {
    Param (
        [Parameter(Mandatory=$true)][String]$Uri,
        [Parameter(Mandatory=$true)][String]$Token
    )

    # SET HEADERS
    $Headers = @{
        "Content-Type" = "application/xml"
        "X-API-Session" = $Token
        "Accept" = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"
    }

    # MAKE GET REQUEST
    Try {
        $Response = Invoke-RestMethod -Method GET -Uri $Uri -Headers $Headers
    } Catch {
        $StreamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
        $StreamReader.BaseStream.Position = 0
        $ErrResp = $StreamReader.ReadToEnd()
        $StreamReader.Close()

        Write-Host -ForegroundColor Cyan $_.Exception.Message
        Write-Host -ForegroundColor Yellow $ErrResp

        return
    }

    # RETURN RESPONSE OBJECT
    return $Response #.entry.content
}
#FUNCTIONS