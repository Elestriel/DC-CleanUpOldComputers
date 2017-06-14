# DC-CleanUpOldComputers
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
