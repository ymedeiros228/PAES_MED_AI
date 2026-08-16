' Iniciar_PAES_MED_AI.vbs
' Inicia backend silenciosamente e abre o app Flutter
' Nao abre navegador, nao mostra janela preta

Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")
here = fso.GetParentFolderName(WScript.ScriptFullName)

' Caminhos
backendDir = here & "\backend"
venvPython = backendDir & "\.venv\Scripts\python.exe"
appExe = here & "\app\paes_med_ai.exe"
reqFile = backendDir & "\requirements.txt"

' Verifica se o exe existe
If Not fso.FileExists(appExe) Then
    MsgBox "App nao encontrado em: " & appExe & vbCrLf & vbCrLf & _
           "O pacote esta incompleto.", vbCritical, "PAES MED AI"
    WScript.Quit 1
End If

' Cria venv se nao existir
If Not fso.FolderExists(backendDir & "\.venv") Then
    shell.Run "cmd /c python -m venv """ & backendDir & "\.venv""", 0, True
End If

' Instala dependencias se faltar fastapi
If Not fso.FolderExists(backendDir & "\.venv\Lib\site-packages\fastapi") Then
    shell.Run "cmd /c """ & venvPython & """ -m pip install -r """ & reqFile & """", 0, True
End If

' Verifica se backend ja esta rodando (porta 8000)
Set http = CreateObject("WinHttp.WinHttpRequest.5.1")
backendRunning = False
On Error Resume Next
http.Open "GET", "http://127.0.0.1:8000/health", False
http.Send
If Err.Number = 0 And http.Status = 200 Then
    backendRunning = True
End If
On Error GoTo 0

' Inicia backend se nao estiver rodando
If Not backendRunning Then
    shell.Run "cmd /c cd /d """ & backendDir & """ && """ & venvPython & _
              """ -m uvicorn main:app --host 127.0.0.1 --port 8000", 0, False

    ' Aguarda backend ficar pronto (max 60 segundos)
    For i = 1 To 30
        WScript.Sleep 2000
        Set http2 = CreateObject("WinHttp.WinHttpRequest.5.1")
        On Error Resume Next
        http2.Open "GET", "http://127.0.0.1:8000/health", False
        http2.Send
        If Err.Number = 0 And http2.Status = 200 Then
            backendRunning = True
            Exit For
        End If
        On Error GoTo 0
    Next
End If

' Abre o app Flutter (NUNCA abre navegador)
shell.Run """" & appExe & """", 1, False
