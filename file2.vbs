' lockscreen_single.vbs
Option Explicit

Dim fso, shell, htaPath, htaText
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

htaPath = fso.GetSpecialFolder(2) & "\lockscreen.hta" ' Temporary HTA in temp folder

' Create HTA content
htaText = _
"<html>" & vbCrLf & _
"<head>" & vbCrLf & _
"    <title>Favorite Drink Lock</title>" & vbCrLf & _
"    <hta:application id=""lockapp"" border=""none"" maximizeButton=""no"" minimizeButton=""no"" showInTaskbar=""no"" sysmenu=""no"" scroll=""no"" windowstate=""maximize"" />" & vbCrLf & _
"    <style>" & vbCrLf & _
"        html, body { margin:0; padding:0; width:100%; height:100%; background-color:black; color:white; font-family:Arial; display:flex; justify-content:center; align-items:center; flex-direction:column; user-select:none; overflow:hidden; }" & vbCrLf & _
"        #title { font-size:36px; margin-bottom:20px; }" & vbCrLf & _
"        #info { color:red; margin-top:10px; font-size:16px; height:20px; }" & vbCrLf & _
"        input { font-size:24px; padding:5px; width:360px; text-align:center; }" & vbCrLf & _
"    </style>" & vbCrLf & _
"</head>" & vbCrLf & _
"<body>" & vbCrLf & _
"    <div id=""title"">Write my favorite drinks here</div>" & vbCrLf & _
"    <input type=""password"" id=""pw"" autocomplete=""off"" />" & vbCrLf & _
"    <div id=""info""></div>" & vbCrLf & _
"    <script language=""VBScript"">" & vbCrLf & _
"        Sub pw_onkeypress" & vbCrLf & _
"            If window.event.keyCode = 13 Then" & vbCrLf & _
"                If LCase(Trim(pw.value)) = ""coffee"" Then window.close Else info.innerText = ""Wrong password!!"": pw.value = """"" & vbCrLf & _
"            End If" & vbCrLf & _
"        End Sub" & vbCrLf & _
"    </script>" & vbCrLf & _
"</body>" & vbCrLf & _
"</html>"

' Write HTA file
If fso.FileExists(htaPath) Then fso.DeleteFile htaPath, True
Dim htaFile
Set htaFile = fso.CreateTextFile(htaPath, True, False)
htaFile.Write htaText
htaFile.Close
Set htaFile = Nothing

' Launch HTA non-blocking
shell.Run "mshta.exe """ & htaPath & """", 1, False

' ESC + mouse lock loop
Dim wmi, procEnum, proc, found
Set wmi = GetObject("winmgmts:\\.\root\cimv2")
WScript.Sleep 200

Do
    found = False
    Set procEnum = wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='mshta.exe'")
    For Each proc In procEnum
        If Not IsNull(proc.CommandLine) Then
            If InStr(LCase(proc.CommandLine), LCase(htaPath)) > 0 Then
                found = True
                Exit For
            End If
        End If
    Next

    If Not found Then Exit Do

    ' Center mouse
    Call SetCursorPosToCenter() ' <-- corrected usage of Call with parentheses

    ' Blast ESC
    shell.SendKeys "{ESC}"

    WScript.Sleep 10
Loop

' Cleanup HTA
If fso.FileExists(htaPath) Then fso.DeleteFile(htaPath, True)

' ---------------------------
Sub SetCursorPosToCenter()
    Dim screenWidth, screenHeight, centerX, centerY
    screenWidth = 1920
    screenHeight = 1080
    centerX = screenWidth \ 2
    centerY = screenHeight \ 2
    shell.Run "rundll32 user32.dll,SetCursorPos " & centerX & "," & centerY, 0, False
End Sub
