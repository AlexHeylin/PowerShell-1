#Please read in full 

 #This script must be run in administrative PowerShell 

 #This script will create a security group if it does not already exist and users with the proper permissions to backup with Microsoft Office 365. Once the users have been created, they will be assigned to the security group. 

 #If the script does not run because Execution Policy is disabled in the system the following line will help 

 #Set-ExecutionPolicy -Scope CurrentUser Unrestricted 

 #Before running the script there are Three values that need to be entered specific to your company and preference below $AccountAmount, $AzureAdmin, and $VBOOrg

 #Here will specify the number of users to add to the Organization
 
$ProxyCount = 2

$AdditionalAccountSets = 0
 
#This will be the user name used to sign in to execute scripts

#$AzureAdmin = "rin@aperaturelabs.biz"

#This will be your organization value as it appears in Veeam Backup for Office 365

$VBOOrg = Read-host "Enter your organization value as it appears in Veeam Backup for Office 365. i.e. aperaturelabs.onmicrosoft.com"

#-------------------------------------------------------------------------------------------
 
 #First you must install and import the AzureAD, and Veeam backup for Microsoft Office 365 Module. 
 
 write-host "Supply admin credentials for this AzureAD."
 $UserCredential = Get-Credential #-Credential $AzureAdmin 

 Install-Module -name AzureAD 

 Import-Module -Name AzureAD -ErrorAction SilentlyContinue 

 $AzureAD = Connect-AzureAD -Credential $UserCredential

 Import-Module Veeam.Archiver.PowerShell 

 Write-Host "Loading Modules Complete" 

 $ErrorActionPreference = 'SilentlyContinue'

 #$ErrorActionPreference = @()

 #This section will query the existing security group or create the security Group if you have not already 

  $SecurityGroup = Get-AzureADGroup -Filter "DisplayName eq 'VBO v5 Backup Aux Accounts'" 

  If (!$SecurityGroup) 

     { 

         $SecurityGroup = New-AzureADGroup -DisplayName "VBO v5 Backup Aux Accounts" -MailEnabled $false -SecurityEnabled $true -MailNickName "NotSet" 

     } 

 Write-Host "Generate Security Group Complete" 
 
 #-------------------------------------------------------------------------------------------
 
 #This section should create password profile and loads users.
 
 $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
 
 $PasswordProfile.Password = "FillerPassword123"
 
 $PasswordProfile.EnforceChangePasswordPolicy = $false
 
 $PasswordProfile.ForceChangePasswordNextLogin = $false

 $AccountAmount = ($ProxyCount * 8) + ($AdditionalAccountSets * 8)
 
 $Names = for ($number = 1 ; $number -le $AccountAmount ; $number++){$number | % tostring VeeamBackupMO365AuxiliaryAccount00000}

Write-Host "Load Users Complete"

Write-Host "Generating users"

$AzureDomain = ($AzureAD.Tenant).Domain

$GroupUsers = @()

foreach ($Name in $Names)
    {
 #-------------------------------------------------------------------------------------------

 #Generates each new AD user and adds user to security group.
        
        $CheckUser = Get-AzureADUser -SearchString $Name

        While (!$CheckUser)
            {

                $User = New-AzureADUser -DisplayName "$Name" -PasswordProfile $PasswordProfile -UserPrincipalName "$name@$AzureDomain" -AccountEnabled $true -MailNickName "$Name"
        
                Set-AzureADUser -ObjectId $user.ObjectId -PasswordPolicies DisablePasswordExpiration
              
                Start-Sleep -Seconds 1

                $CheckUser = Get-AzureADUser -SearchString $Name

                    IF (!$CheckUser)
                        
                        {
                            Start-Sleep -Seconds 1
                            $CheckUser = Get-AzureADUser -SearchString $Name
                            
                        }

                    IF (!$CheckUser)

                        {

                            Write-Host "Failed to create user $Name. Trying again..."

                        }

                    IF ($CheckUser)

                        {

                             Write-Host "New user added $Name"

                        }

            
            }
        
        
        $GroupUsers += $Checkuser

    }

Start-Sleep -Seconds 3

    foreach ($GroupUser in $GroupUsers)

        {

            $GroupUserID = $GroupUser.DisplayName

            $CheckUserGroup = Get-AzureADGroupMember -ObjectId $SecurityGroup.objectid -All $true | Where-Object {$_.DisplayName -eq $GroupUserID}

            While (!$CheckUserGroup)

                {
                        Add-AzureADGroupMember -ObjectId $SecurityGroup.objectid -RefObjectId $GroupUser.objectid


                        $CheckUserGroup = Get-AzureADGroupMember -ObjectId $SecurityGroup.objectid -all $true | ? {$_.DisplayName -eq $GroupUserID}

                            IF (!$CheckUserGroup)

                                {
                                        
                                     Start-Sleep -Seconds 1
                                     
                                     $CheckUserGroup = Get-AzureADGroupMember -ObjectId $SecurityGroup.objectid -all $true | ? {$_.DisplayName -eq $GroupUserID}

                                 }

                            IF (!$CheckUserGroup)

                                {

                                    Write-Host "Failed adding $GroupUserID to group. Trying again..."

                                }
                            
                            IF ($CheckUserGroup)

                                {

                                    Write-Host "Added User $GroupUserID to group"

                                }

                }
        
        

    }

Write-Host "Generate users Complete"

Write-Host "Users added to Security Group Complete"
 
#This section will pause to allow the users to populate

Write-Host "Waiting for accounts to generate in Azure"

Start-sleep -Seconds 20

Write-Host "Populating accounts for Veeam Backup for Microsoft Office 365"

#-------------------------------------------------------------------------------------------

#Here will pull up organization and security group members for VBO

        $org = Get-VBOOrganization -name $VBOOrg
        
        $group = Get-VBOOrganizationGroup -Organization $org -DisplayName $SecurityGroup.DisplayName
        
        Start-Sleep -Seconds 2

        $members = Get-VBOOrganizationGroupMember -Group $group | Sort-Object

$setacc = @()

#$Count = 1

foreach ($member in $members)
    {
 #-------------------------------------------------------------------------------------------
 #This section a random password is generated for each user
        
        Write-Host "Working on $member account"

        Do

            {
        
                $PasswordSet = "0"
                
                $minLength = 16 ## characters

                $maxLength = 20 ## characters

                $length = Get-Random -Minimum $minLength -Maximum $maxLength

                $nonAlphaChars = 10

                $RandomGen = [System.Web.Security.Membership]::GeneratePassword($length, $nonAlphaChars)

                $Password = ConvertTo-SecureString -String $RandomGen -AsPlainText -Force
        
                $DisplayName = $member.DisplayName

                $PasswordSet = Set-AzureADUserPassword -ObjectId (Get-AzureADUser -Filter "DisplayName eq '$Displayname'").ObjectID -ForceChangePasswordNextLogin $false -Password $Password
        
                Start-Sleep -Seconds 1

                IF ($PasswordSet)

                    {

                        Start-Sleep -Seconds 1

                        Write-Host "Retrying password on account"

                    }

            } While ($PasswordSet)

 #-------------------------------------------------------------------------------------------
 #This section adds the user to the Organization in Veeam Backup for Microsoft Office 365 Auxiliary Backup Accounts
        
        $account = New-VBOBackupAccount -SecurityGroupMember $member -Password $Password

        Start-Sleep -Seconds 1
        
        $setacc += $account
        
    }

Write-Host "Adding accounts to console"

Start-Sleep -Seconds 4

Set-VBOOrganization -Organization $Org -BackupAccounts $setacc

Write-Host "Users password set complete"

Write-Host "Users added to Veeam Backup for Microsoft Office 365 Complete"
 
#-------------------------------------------------------------------------------------------

#Last the connections will be disconnected

Disconnect-AzureAD

Write-Host "Disconnect Complete"
