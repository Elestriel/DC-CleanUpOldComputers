<#
  .SYNOPSIS
    Removes computers from the Domain Controller that haven't been logged into for the specified amount of days.

  .DESCRIPTION
    This script is intended to be run by a Scheduled Task on the Domain Controller. For this reason, Credentials
     are built-in, instead of passed in. In the arguments for the call, pass in the threshold of inactive days,
     and any machines that are older than this number will be removed from the Domain Controller.
  
  .EXAMPLE
    Set up a Scheduled Task to execute the following action:
     powershell C:\Cleanup\Computers\DC-CleanUpOldComputers.ps1 -InactiveDays 30

  .INPUTS
    $InactiveDays: The threshold used to determine whether a Computer should be removed.

  .OUTPUTS
    A log of all activity by the script is kept. The path is defined in $LogPath and $LogFilePath.
    If $LogPath does not exist, it will be created so that $LogFilePath is able to be created.
#>

Param (
    [Parameter(Mandatory = $true)]
    $InactiveDays
)

$LogPath = "C:\Cleanup\Computers"
$LogFilePath = "$LogPath\log.txt"

# Set these, or remove them and pass $Credential in through Params
$User = ""
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential ($User, $Password)

if (!(Test-Path $LogPath)) {
    New-Item -ItemType Directory -Force -Path $LogPath
}

Add-Content $LogFilePath "`nStarting Cleanup Script - $(Get-Date)"

# Edit the filter as needed to prevent accidental deletion of important machines.
$Computers = Get-ADComputer -Filter { MemberOf -notlike "*Infrastructure*" } -Properties LastLogonTimeStamp, MemberOf, Created
$Computers = $Computers | Select-Object DistinguishedName,Name,Created,@{Name="LastLogin"; Expression = {[DateTime]::FromFileTime($_.LastLogonTimestamp)}}

$Today = Get-Date

$Computers | ForEach-Object {
    $DaysSinceCreation = New-TimeSpan -Start $_.Created -End $Today

    if ($DaysSinceCreation.Days -gt $InactiveDays) {
        if ($_.LastLogin) {
            $DaysSinceLastLogin = New-TimeSpan -Start $_.LastLogin -End $Today
            if ($DaysSinceLastLogin.Days -gt $InactiveDays) {
                Add-Content $LogFilePath "`n -> Removing: $($_.Name), Created: $($_.Created), Last Logged In: $($_.LastLogin) ($($DaysSinceLastLogin.Days) Days)"
                Remove-ADObject -Identity "$($_.DistinguishedName)" -Credential $Credential -Confirm:$false -Recursive
            } 
        }
        else {
            Add-Content $LogFilePath "`n -> Removing: $($_.Name), Created: $($_.Created), Last Logged In: Never"
            Remove-ADObject -Identity "$($_.DistinguishedName)" -Credential $Credential -Confirm:$false -Recursive
        }
    }
}

Add-Content $LogFilePath "`nFinished Cleanup Script"
