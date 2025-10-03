' lockscreen_mousefreeze.vbs
Option Explicit

Dim fso, shell, htaPath, htaText
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

htaPath = fso.GetSpecialFolder(2) & "\lockscreen.hta"

' Build HTA content with mouse freeze enhancements
htaText = _
"<html>" & vbCrLf & _
"<head>" & vbCrLf & _
"    <title>Favorite Drink Lock</title>" & vbCrLf & _
"    <hta:application id=""lockapp"" border=""none"" maximizeButton=""no"" minimizeButton=""no"" showInTaskbar=""no"" sysmenu=""no"" scroll=""no"" windowstate=""maximize"" />" & vbCrLf & _
"    <style>" & vbCrLf & _
"        html, body { margin:0; padding:0; width:100%; height:100%; background-color:black; color:white; font-family:Arial; display:flex; justify-content:center; align-items:center; flex-direction:column; user-select:none; overflow:hidden; cursor:none; }" & vbCrLf & _
"        #title { font-size:36px; margin-bottom:20px; }" & vbCrLf & _
"        #info { color:red; margin-top:10px; font-size:16px; height:20px; }" & vbCrLf & _
"        input { font-size:24px; padding:5px; width:360px; text-align:center; }" & vbCrLf & _
"    </style>" & vbCrLf & _
"</head>" & vbCrLf & _
"<body>" & vbCrLf & _
"    <div id=""title"">Write my favorite drinks here</div>" & vbCrLf & _
"    <input type=""password"" id=""pw"" autocomplete=""off"" onfocus=""window.isTyping=true"" onblur=""window.isTyping=false"" />" & vbCrLf & _
"    <div id=""info""></div>" & vbCrLf & _
"    <script language=""VBScript"">" & vbCrLf & _
"        Sub pw_onkeypress" & vbCrLf & _
"            If window.event.keyCode = 13 Then" & vbCrLf & _
"                If LCase(Trim(pw.value)) = ""coffee"" Then window.close Else info.innerText = ""Wrong password!!"": pw.value = """"" & vbCrLf & _
"            End If" & vbCrLf & _
"        End Sub" & vbCrLf & _
"    </script>" & vbCrLf & _
"    <script language=""JavaScript"">" & vbCrLf & _
"        window.isTyping = false;" & vbCrLf & _
"        window.onload = function(){ document.getElementById('pw').focus(); };" & vbCrLf & _
"        document.oncontextmenu = function(){ return false; };" & vbCrLf & _
"        document.onselectstart = function(){ return false; };" & vbCrLf & _
"        function centerMouse() {" & vbCrLf & _
"            try {" & vbCrLf & _
"                var shell = new ActiveXObject('WScript.Shell');" & vbCrLf & _
"                var screenWidth = screen.width;" & vbCrLf & _
"                var screenHeight = screen.height;" & vbCrLf & _
"                if(!window.isTyping){" & vbCrLf & _
"                    for(var i=0;i<5;i++){" & vbCrLf & _
"                        shell.Run('rundll32 user32.dll,SetCursorPos ' + (screenWidth/2) + ',' + (screenHeight/2),0,false);" & vbCrLf & _
"                        shell.SendKeys('{ESC}');" & vbCrLf & _
"                    }" & vbCrLf & _
"                }" & vbCrLf & _
"            } catch(e){}" & vbCrLf & _
"            setTimeout(centerMouse,10);" & vbCrLf & _
"        }" & vbCrLf & _
"        centerMouse();" & vbCrLf & _
"    </script>" & vbCrLf & _
"</body>" & vbCrLf & _
"</html>"

' Write HTA file
If fso.FileExists(htaPath) Then fso.DeleteFile(htaPath, True)
Dim htaFile
Set htaFile = fso.CreateTextFile(htaPath, True, False)
htaFile.Write htaText
htaFile.Close
Set htaFile = Nothing

' Launch HTA
shell.Run "mshta.exe """ & htaPath & """", 1, False
