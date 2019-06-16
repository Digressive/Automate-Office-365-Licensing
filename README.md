# Automate Office 365 Licensing

## Update 2019-06-16

I recently learned that Office 365 licensing can be managed via Azure Active Directory's group based licensing feature and I have since switched to using this and have retired this script. I'll leave this post and the script itself available here, on the Microsoft TechNet Gallery and GitHub, but I'll not be developing the script any further. For more information on Azure Active Directory group-based licensing please check out Microsoft's documentation here and here to start with.

PowerShell script to assign Office 365 license to users in an Active Directory OU structure.

My Automate Office 365 Licensing Utility PowerShell script can also be downloaded from:

* [The Microsoft TechNet Gallery](https://gallery.technet.microsoft.com/Automated-Office-365-8789a236)
* For full instructions and documentation, [visit my blog post](https://gal.vin/2018/11/04/automated-office-365-licensing/)

-Mike

Tweet me if you have questions: [@mikegalvin_](https://twitter.com/mikegalvin_)

## Features and Requirements

This utility will assign a configurable Office 365 license to Active Directory user accounts within an OU or descending OUs. All options are added via command line switches. Options include:

* The Office 365 Global Admin user and password to use.
* The Office 365 license and usage location to assign.
* Organisation Unit which contains to users to license.
* The directory to output a log file to.
* An optional email address to send the log file to.
* This utility has been tested running on Windows Server 2016. This utility requires the MSOnline and Active Directory PowerShell modules to be installed.

The script has been tested on Windows 10, Windows Server 2016 (Datacenter and Core installations) and Windows Server 2012 R2 (Datacenter and Core Installations) with PowerShell 5.0.

### Generating A Password File

The password used for SMTP server authentication must be in an encrypted text file. To generate the password file, run the following command in PowerShell, on the computer that is going to run the script and logged in with the user that will be running the script. When you run the command you will be prompted for a username and password. Enter the username and password you want to use to authenticate to your SMTP server.

Please note: This is only required if you need to authenticate to the SMTP server when send the log via e-mail.

```
$creds = Get-Credential
$creds.Password | ConvertFrom-SecureString | Set-Content c:\scripts\ps-script-pwd.txt
```

After running the commands, you will have a text file containing the encrypted password. When configuring the -Pwd switch enter the path and file name of this file.

### Configuration

Here’s a list of all the command line switches and example configurations.
```
-User365
```
The Office 365 Admin user to use for the operation.
```
-Pwd365
```
The password for the Office 365 Admin user to use for the operation.
```
-Lic
```
The Office 365 license to apply to your users.
```
-UseLoc
```
The Office 365 usage location to use.
```
-OU
```
The top level OU that contains the users to license in Office 365.
```
-L
```
The path to output the log file to. The file name will be Office-365-Licensing.log
```
-SendTo
```
The e-mail address the log should be sent to.
```
-From
```
The e-mail address the log should be sent from.
```
-Smtp
```
The DNS name or IP address of the SMTP server.
```
-User
```
The user account to connect to the SMTP server.
```
-Pwd
```
The txt file containing the encrypted password for the user account.
```
-UseSsl
```
Configures the script to connect to the SMTP server using SSL.

### Example

```
Office-365-Licensing.ps1 -User365 GAdmin@contosocom.onmicrosoft.com -Pwd365 P@ssw0rd -Lic contosocom:ENTERPRISEPACK -UseLoc GB -OU OU=MyUsers,DC=contoso,DC=com -L C:\logs -SendTo me@contoso.com -From Office-365-licensing@contoso.com -Smtp smtp.outlook.com -User user -Pwd C:\foo\pwd.txt -UseSsl
```
This will login to Office 365 with the specified user and assign licenses to the users in the MyUsers OU, and OUs below that. On completion it will email the log file to the specified address.
