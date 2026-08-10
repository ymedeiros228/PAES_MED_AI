$ws = New-Object -ComObject WScript.Shell
$lnk = $ws.CreateShortcut("C:\Users\Yuri\Desktop\PAES MED AI.lnk")
Write-Output "TargetPath: $($lnk.TargetPath)"
Write-Output "WorkingDir: $($lnk.WorkingDirectory)"
Write-Output "Arguments: $($lnk.Arguments)"
