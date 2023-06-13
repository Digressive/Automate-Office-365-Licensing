<#PSScriptInfo

.VERSION 1.1

.GUID d89e65ae-1bed-4991-a54f-dd70a4e34996

.AUTHOR Mike Galvin Contact: mike@gal.vin 

.COMPANYNAME Mike Galvin

.COPYRIGHT (C) Mike Galvin. All rights reserved.

.TAGS Microsoft Office 365 Licensing Automation

.LICENSEURI

.PROJECTURI https://gal.vin/posts/automated-office-365-licensing/

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES

#>

<#
    .SYNOPSIS
    Assigns licenses to Office 365 users in an Active Directory OU structure.

    .DESCRIPTION
    Assigns licenses to Office 365 users in an Active Directory OU structure.

    This script will:
    
    Take users in a specified OU structure and will assign Office 365 licenses to users that aren't licensed.
    
    Important note #1: The MSOnline PowerShell management modules should be installed for this script to run successfully.
    Important note #2: Depending on the number of users in the OU structure this script can take a long time to run.
    
    .PARAMETER User365
    The Office 365 Admin user to use for the operation.

    .PARAMETER Pwd365
    The password for the Office 365 Admin user to use for the operation.

    .PARAMETER Lic
    The Office 365 license to apply to your users.

    .PARAMETER UseLoc
    The Office 365 usage location to use.

    .PARAMETER OU
    The top level OU that contains the users to license in Office 365.

    .PARAMETER L
    The path to output the log file to.
    The file name will be Office-365-Licensing.log

    .PARAMETER Subject
    The email subject that the email should have. Encapulate with single or double quotes.

    .PARAMETER SendTo
    The e-mail address the log should be sent to.

    .PARAMETER From
    The from address the log should be sent from.

    .PARAMETER Smtp
    The DNS or IP address of the SMTP server.

    .PARAMETER User
    The user account to connect to the SMTP server.

    .PARAMETER Pwd
    The txt file containing the encrypted password for the user account.

    .PARAMETER UseSsl
    Connect to the SMTP server using SSL.

    .EXAMPLE
    Office-365-Licensing.ps1 -User365 GAdmin@contosocom.onmicrosoft.com -Pwd365 P@ssw0rd -Lic contosocom:ENTERPRISEPACK -UseLoc GB -OU OU=MyUsers,DC=contoso,DC=com -L C:\scripts\logs -Subject 'Server: O365 Licensing' -SendTo me@contoso.com -From Office-365-licensing@contoso.com -Smtp smtp.outlook.com -User user -Pwd c:\scripts\ps-script-pwd.txt -UseSsl
    This will login to Office 365 with the specified user and assign licenses to the users in the MyUsers OU, and OUs below that. On completion it will e-mail the log file to the specified address with a custom subject line.
#>

## Set Params via cmd.
[CmdletBinding()]
Param(
    [parameter(Mandatory=$True)]
    [alias("User365")]
    $365AdUser,
    [parameter(Mandatory=$True)]
    [alias("Pwd365")]
    $365Password,
    [parameter(Mandatory=$True)]
    [alias("Lic")]
    $License,
    [parameter(Mandatory=$True)]
    [alias("UseLoc")]
    $UsageLocation,
    [parameter(Mandatory=$True)]
    [alias("OU")]
    $OUDN,
    [alias("L")]
    [ValidateScript({Test-Path $_ -PathType 'Container'})]
    $LogPath,
    [alias("Subject")]
    $MailSubject,
    [alias("SendTo")]
    $MailTo,
    [alias("From")]
    $MailFrom,
    [alias("Smtp")]
    $SmtpServer,
    [alias("User")]
    $SmtpUser,
    [alias("Pwd")]
    [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
    $SmtpPwd,
    [switch]$UseSsl)

## Log in to Office 365.
$365PwdSecure = ConvertTo-SecureString $365Password -AsPlainText -Force
$365Cred = New-Object System.Management.Automation.PSCredential $365AdUser, $365PwdSecure

## Connect to Azure AD.
Connect-MsolService -Credential $365Cred

## Get Users from local AD to compare to Azure AD.
$ADUsers = Get-ADUser -Filter * -SearchBase $OUDN

## Create a variable that contains the users who are not licensed.
$LicNo = ForEach ($ADUser in $ADUsers)
{
    ## Get Azure AD users by UPN.
    $UserLic = Get-MsolUser -UserPrincipalName $ADUser.UserPrincipalName
 
    ## If user has no license, output something so we can count it.
    If ($UserLic.IsLicensed -eq $false)
    {
        Write-output "$($ADUser.UserPrincipalName) is unlicensed"
    }
}

## Count the users who are not licensed. If the variable does not equal zero, then license the users.
If ($LicNo.count -ne 0)
{
    ## If logging is configured, start log.
    If ($LogPath)
    {
        $LogFile = "Office-365-Licensing.log"
        $Log = "$LogPath\$LogFile"

        ## If the log file already exists, clear it.
        $LogT = Test-Path -Path $Log

        If ($LogT)
        {
            Clear-Content -Path $Log
        }

        Add-Content -Path $Log -Value "****************************************"
        Add-Content -Path $Log -Value "$(Get-Date -Format g) Log started"
        Add-Content -Path $Log -Value ""
    }

    ## For each user Azure AD user from the OU configured above.
    ForEach ($ADUser in $ADUsers)
    {
        ## Get Azure AD users UPN.
        $UserLic = Get-MsolUser -UserPrincipalName $ADUser.UserPrincipalName

        ## If user has no license set one.
        If ($UserLic.IsLicensed -eq $false)
        {
            Set-MsolUser -UserPrincipalName $ADUser.UserPrincipalName –UsageLocation $UsageLocation
            Set-MsolUserLicense -UserPrincipalName $ADUser.UserPrincipalName -AddLicenses $License
            
            ## If log is configured then log the user being licensed.
            If ($LogPath)
            {
                Add-Content -Path $Log -Value "$(Get-Date -Format g) Office 365 License added for $($ADUser.UserPrincipalName)"
            }
        }
    }

    ## If log is configured, stop the log.
    If ($LogPath)
    {
        Add-Content -Path $Log -Value ""
        Add-Content -Path $Log -Value "$(Get-Date -Format g) Log finished"
        Add-Content -Path $Log -Value "****************************************"

        ## If email was configured, set the variables for the email subject and body.
        If ($SmtpServer)
        {
            # If no subject is set, use the string below.
            If ($Null -eq $MailSubject)
            {
                $MailSubject = "Office 365 Licensing"
            }

            $MailBody = Get-Content -Path $Log | Out-String

            ## If an email password was configured, create a variable with the username and password.
            If ($SmtpPwd)
            {
                $SmtpPwdEncrypt = Get-Content $SmtpPwd | ConvertTo-SecureString
                $SmtpCreds = New-Object System.Management.Automation.PSCredential -ArgumentList ($SmtpUser, $SmtpPwdEncrypt)

                ## If ssl was configured, send the email with ssl.
                If ($UseSsl)
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -UseSsl -Credential $SmtpCreds
                }

                ## If ssl wasn't configured, send the email without ssl.
                Else
                {
                    Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer -Credential $SmtpCreds
                }
            }
        
            ## If an email username and password were not configured, send the email without authentication.
            Else
            {
                Send-MailMessage -To $MailTo -From $MailFrom -Subject $MailSubject -Body $MailBody -SmtpServer $SmtpServer
            }
        }
    }
}

## End
