' Iniciar_PAES_MED_AI.vbs
' Wrapper invisivel que executa o .bat sem mostrar a tela preta de cmd
Set sh = CreateObject("WScript.Shell")
here = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)
sh.Run """" & here & "\Iniciar_PAES_MED_AI.bat""", 0, False
