## Set Params via cmd
[CmdletBinding()]
Param(
    [alias("L")]
    $LogPath,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    $SmtpPwd,
    [switch]$UseSsl)

## Log in to the o365 service
$O365Admin = "Office365SyncAdmin@tcatacuk.onmicrosoft.com"
$365Password = ConvertTo-SecureString "aNVrEuB4VtCy8uxN" -AsPlainText -Force
$CloudCred = New-Object System.Management.Automation.PSCredential $O365Admin, $365Password

## License options
$License = "tcatacuk:STANDARDWOFFPACK_IW_STUDENT"
$UsageLocation = "GB"

$OU = "OU=Individual,OU=Students,DC=Hub,DC=tcat,DC=network"

## Connect to Azure AD
Connect-MsolService -Credential $CloudCred

## Get Users from local AD to compare to Azure AD
$StudUsers = Get-ADUser -Filter * -SearchBase $OU

## Count the users who are not licensed
$LicNo = ForEach ($StudUser in $StudUsers)
{
    ## Get Azure AD users by UPN
    $UserLic = Get-MsolUser -UserPrincipalName $StudUser.UserPrincipalName
}

If ($LicNo.count -ne 0)
{
    ## If logging is configured, start log
    If ($LogPath)
    {
        $LogFile = "O365-Students-License.log"
        $Log = "$LogPath\$LogFile"

        ## If the log file already exists, clear it
        $LogT = Test-Path -Path $Log
        If ($LogT)
        {
            Clear-Content -Path $Log
        }

        Add-Content -Path $Log -Value "****************************************"
        Add-Content -Path $Log -Value "$(Get-Date -Format G) Log started"
        Add-Content -Path $Log -Value ""
    }

    ## For each user
    ForEach ($StudUser in $StudUsers)
    {
        ## Get Azure AD users by UPN
        $UserLic = Get-MsolUser -UserPrincipalName $StudUser.UserPrincipalName

        ## If user has no license, set one.
        If ($UserLic.IsLicensed -eq $false)
        {
            Set-MsolUser -UserPrincipalName $StudUser.UserPrincipalName –UsageLocation $UsageLocation
            Set-MsolUserLicense -UserPrincipalName $StudUser.UserPrincipalName -AddLicenses $License
        
            ## Logging
            If ($LogPath)
            {
                Add-Content -Path $Log -Value "$(Get-Date -Format G) Office 365 License added for $($StudUser.UserPrincipalName)"
                Add-Content -Path $Log -Value ""
            }
        }
    }

    ## If log was configured stop the log
    If ($LogPath)
    {
        ## If log was configured stop the log
        Add-Content -Path $Log -Value ""
        Add-Content -Path $Log -Value "$(Get-Date -Format G) Log finished"
        Add-Content -Path $Log -Value "****************************************"

        ## If email was configured, set the variables for the email subject and body
        If ($SmtpServer)
        {
            $MailSubject = "O365 Licensing"
            $MailBody = Get-Content -Path $Log | Out-String

            ## If an email password was configured, create a variable with the username and password
            If ($SmtpPwd)
            {
                $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
                $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

                ## If ssl was configured, send the email with ssl
                If ($UseSsl)
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -UseSsl -Credential $SmtpCreds
                }

                ## If ssl wasn't configured, send the email without ssl
                Else
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Credential $SmtpCreds
                }
            }
    
            ## If an email username and password were not configured, send the email without authentication
            Else
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer
            }
        }
    }
}

## End
