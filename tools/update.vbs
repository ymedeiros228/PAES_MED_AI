Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "powershell -ExecutionPolicy Bypass -WindowStyle Hidden -File ""tools\update.ps1""", 0, False
Set WshShell = Nothing
