#This will be the user name used to sign in to execute scripts

$AzureAdmin = "admin@company.biz"

#First you must install/import the AzureAD, MsolService, and Veeam backup for Microsoft Office 365 Module. 

#-------------------------------------------------------------------------------------------

$UserCredential = Get-Credential -Credential $AzureAdmin 

Connect-MsolService -Credential $UserCredential

Connect-AzureAD -Credential $UserCredential

Import-Module Veeam.Archiver.PowerShell 

 $SecurityGroup = Get-AzureADGroup -Filter "DisplayName eq 'VBO v5 Backup Aux Accounts'" 

$VBOgroupusers = Get-AzureADGroupMember -ObjectId $SecurityGroup.ObjectId

$DeletedUsers = Get-AzureADGroupMember -ObjectId $SecurityGroup.ObjectId

#-------------------------------------------------------------------------------------------
#Deleting users from Security Group

While ($VBOgroupusers)

    {

    foreach ($VBOgroupuser in $VBOgroupusers)

            {

               Remove-AzureADUser -ObjectId $VBOgroupuser.objectid

               Write-Host $VBOgroupuser.Displayname was deleted

            }

    $VBOgroupusers = Get-AzureADGroupMember -ObjectId $SecurityGroup.ObjectId

    }



Start-Sleep -Seconds 10

#-------------------------------------------------------------------------------------------
#Deleting users from recycling bin

While ($DeletedUsers)

    {

        foreach ($DeletedUser in $DeletedUsers)

            {
                
                Remove-MsolUser -ObjectId $DeletedUser.objectid -RemoveFromRecycleBin -Force

                Write-Host $DeletedUser.Displayname was deleted from recycling

            }

        $DeletedUsers = Get-MsolUser -ReturnDeletedUsers
    }

#-------------------------------------------------------------------------------------------
#Deleting Security Group

IF ($SecurityGroup)

    {

        $RemovedGroup = Remove-AzureADGroup -ObjectId $SecurityGroup.objectid

        Write-Host Group $RemovedGroup.displayname was removed

    }


Write-Host "Task Complete"

#-------------------------------------------------------------------------------------------
#Disconnecting from Azure

Disconnect-AzureAD

Write-Host "Disconnect Complete"
