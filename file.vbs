' lock_and_block.vbs
' Creates a fullscreen HTA password lock and while the HTA is open:
' - centers the mouse continuously
' - repeatedly sends ESC to block Start menu / non-alphanumeric effects
' Correct password: coffee
Option Explicit

Dim fso, shell, scriptPath, scriptFolder, htaPath, htaText
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("WScript.Shell")

' Determine folder where the VBS is running and HTA path
scriptPath = WScript.ScriptFullName
scriptFolder = fso.GetParentFolderName(scriptPath)
htaPath = scriptFolder & "\" & "lockscreen.hta"

' HTA content (multiline)
htaText = _
"<html>" & vbCrLf & _
"<head>" & vbCrLf & _
"    <title>Favorite Drink Lock</title>" & vbCrLf & _
"    <hta:application" & vbCrLf & _
"        id=""lockapp""" & vbCrLf & _
"        border=""none""" & vbCrLf & _
"        maximizeButton=""no""" & vbCrLf & _
"        minimizeButton=""no""" & vbCrLf & _
"        showInTaskbar=""no""" & vbCrLf & _
"        sysmenu=""no""" & vbCrLf & _
"        scroll=""no""" & vbCrLf & _
"        windowstate=""maximize""" & vbCrLf & _
"    />" & vbCrLf & _
"    <meta http-equiv=""X-UA-Compatible"" content=""IE=Edge"" />" & vbCrLf & _
"    <style>" & vbCrLf & _
"        html, body {" & vbCrLf & _
"            margin:0; padding:0; width:100%; height:100%; background-color:#000; color:#fff;" & vbCrLf & _
"            font-family:Arial, sans-serif; display:flex; justify-content:center; align-items:center; flex-direction:column; user-select:none;" & vbCrLf & _
"        }" & vbCrLf & _
"        #title { font-size:36px; margin-bottom:20px; }" & vbCrLf & _
"        #info { color:red; margin-top:10px; font-size:16px; height:20px; }" & vbCrLf & _
"        input { font-size:24px; padding:8px 10px; width:360px; text-align:center; }" & vbCrLf & _
"    </style>" & vbCrLf & _
"</head>" & vbCrLf & _
"<body>" & vbCrLf & _
"    <div id=""title"">Write my favorite drinks here</div>" & vbCrLf & _
"    <input type=""password"" id=""pw"" autocomplete=""off"" />" & vbCrLf & _
"    <div id=""info""></div>" & vbCrLf & _
"" & vbCrLf & _
"    <script language=""VBScript"">" & vbCrLf & _
"        Sub pw_onkeypress" & vbCrLf & _
"            If window.event.keyCode = 13 Then ' Enter" & vbCrLf & _
"                If LCase(Trim(pw.value)) = ""coffee"" Then" & vbCrLf & _
"                    window.close" & vbCrLf & _
"                Else" & vbCrLf & _
"                    info.innerText = ""Wrong password!!""" & vbCrLf & _
"                    pw.value = """"" & vbCrLf & _
"                    pw.focus" & vbCrLf & _
"                End If" & vbCrLf & _
"            End If" & vbCrLf & _
"        End Sub" & vbCrLf & _
"    </script>" & vbCrLf & _
"" & vbCrLf & _
"    <script type=""text/javascript"">" & vbCrLf & _
"        // Focus input on load" & vbCrLf & _
"        window.onload = function(){ pw.focus(); };" & vbCrLf & _
"        // Prevent some default interactions" & vbCrLf & _
"        document.oncontextmenu = function(){ return false; }" & vbCrLf & _
"        document.onselectstart = function(){ return false; }" & vbCrLf & _
"        // Try to trap Alt+F4 / Ctrl+W by overriding keydown (best-effort; system combos may still work)" & vbCrLf & _
"        document.addEventListener('keydown', function(e){ e.stopPropagation(); }, true);" & vbCrLf & _
"    </script>" & vbCrLf & _
"</body>" & vbCrLf & _
"</html>"

' Write HTA file (overwrite if exists)
On Error Resume Next
If fso.FileExists(htaPath) Then
    fso.DeleteFile htaPath, True
End If
On Error GoTo 0

Dim htaFile
Set htaFile = fso.CreateTextFile(htaPath, True, False)
htaFile.Write htaText
htaFile.Close
Set htaFile = Nothing

' Launch the HTA (non-blocking)
Dim cmd
cmd = "mshta.exe """ & htaPath & """"
shell.Run cmd, 1, False

' Use WMI to detect the mshta process for this HTA
Dim wmi, procEnum, proc, found
Set wmi = GetObject("winmgmts:\\.\root\cimv2")

' Wait briefly for process to appear
WScript.Sleep 200

' Poll: while the HTA process that references our HTA file is running, do blocking actions
Do
    found = False
    Set procEnum = wmi.ExecQuery("SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name = 'mshta.exe'")
    For Each proc In procEnum
        If Not IsNull(proc.CommandLine) Then
            ' CommandLine may contain the HTA path; compare case-insensitive
            If InStr(LCase(proc.CommandLine), LCase(htaPath)) > 0 Then
                found = True
                Exit For
            End If
        End If
    Next

    If Not found Then Exit Do

    ' Center mouse
    Call SetCursorPosToCenter()

    ' Blast ESC to suppress Start / other non-alphanumeric effects
    shell.SendKeys "{ESC}"

    ' Small sleep to reduce CPU usage
    WScript.Sleep 10
Loop

' Clean up HTA file (optional - keep or delete as you like)
' On some systems deleting while process exists can fail; here we'll attempt deletion.
On Error Resume Next
If fso.FileExists(htaPath) Then fso.DeleteFile htaPath, True
On Error GoTo 0

' Done. Everything returns to normal once HTA closed and loop exits.
WScript.Echo "Lock closed. Script finished."

' ---------------------------
' Helper function to center mouse using rundll32 SetCursorPos
' ---------------------------
Sub SetCursorPosToCenter()
    Dim screenWidth, screenHeight, centerX, centerY
    ' Try to read actual screen size from environment using WMI or fallback to common values
    screenWidth = GetSystemMetric(0) ' SM_CXSCREEN
    screenHeight = GetSystemMetric(1) ' SM_CYSCREEN
    If screenWidth <= 0 Then screenWidth = 1920
    If screenHeight <= 0 Then screenHeight = 1080
    centerX = Int(screenWidth / 2)
    centerY = Int(screenHeight / 2)
    shell.Run "rundll32 user32.dll,SetCursorPos " & centerX & "," & centerY, 0, False
End Sub

' ---------------------------
' GetSystemMetric via small DllCall helper (uses rundll32 trick for screen size isn't available,
' so we use WMI to fetch current screen size from Win32_VideoController as fallback)
' ---------------------------
Function GetSystemMetric(index)
    ' index 0 = width, 1 = height
    On Error Resume Next
    Dim metrics
    GetSystemMetric = 0

    ' Try using WScript.Shell's Environment (no direct API), fallback to WMI
    Dim objWMIService, colItems, objItem
    Set objWMIService = GetObject("winmgmts:\\.\root\CIMV2")
    Set colItems = objWMIService.ExecQuery("Select CurrentHorizontalResolution,CurrentVerticalResolution FROM Win32_VideoController")
    For Each objItem In colItems
        If index = 0 Then
            If Not IsNull(objItem.CurrentHorizontalResolution) Then
                GetSystemMetric = objItem.CurrentHorizontalResolution
                Exit Function
            End If
        ElseIf index = 1 Then
            If Not IsNull(objItem.CurrentVerticalResolution) Then
                GetSystemMetric = objItem.CurrentVerticalResolution
                Exit Function
            End If
        End If
    Next

    ' If that fails, try environment variables (rare)
    Dim env
    Set env = shell.Environment("PROCESS")
    If index = 0 Then
        If env.Exists("SCREEN_WIDTH") Then GetSystemMetric = CLng(env("SCREEN_WIDTH"))
    Else
        If env.Exists("SCREEN_HEIGHT") Then GetSystemMetric = CLng(env("SCREEN_HEIGHT"))
    End If

    ' final fallback values handled by caller
    On Error GoTo 0
End Function
