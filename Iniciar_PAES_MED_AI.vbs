' Iniciar_PAES_MED_AI.vbs
' Wrapper invisivel que executa o app Flutter diretamente.
' Nao chama mais .bat, evitando piscar tela de CMD.
Set sh = CreateObject("WScript.Shell")
here = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\") - 1)
sh.Run """" & here & "\app\paes_med_ai.exe""", 1, False
