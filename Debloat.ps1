#requires -version 5.1
<#
    Debloat.ps1
    Pick which built-in Windows apps to remove. Nothing is removed until you
    confirm, and only the items you choose get touched.

    GUI (default):   right-click the file and "Run with PowerShell", or
                     powershell -ExecutionPolicy Bypass -File .\Debloat.ps1

    Console menu:    .\Debloat.ps1 -NoGui
    No prompts:      .\Debloat.ps1 -Recommended        (removes the recommended set)
                     add -SkipRestorePoint to skip the restore point.

    It needs admin rights and will ask for them.
#>

param(
    [switch]$NoGui,
    [switch]$Recommended,
    [switch]$SkipRestorePoint
)

# Get admin rights if we don't have them, keeping whatever switches were passed.
$me = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $me.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $relaunch = "-ExecutionPolicy Bypass -NoProfile -File `"$PSCommandPath`""
    if ($NoGui)            { $relaunch += " -NoGui" }
    if ($Recommended)      { $relaunch += " -Recommended" }
    if ($SkipRestorePoint) { $relaunch += " -SkipRestorePoint" }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $relaunch
    exit
}

# The list of stuff we're willing to offer for removal. Only packages that
# are safe to lose for most people are in here. Anything essential (the Store,
# Terminal, Calculator, Photos, Snipping Tool, Windows Security, the .NET and
# VC runtimes) is deliberately left out so it can't be removed by accident.
#
# Recommended = removed by default. The optional ones (Xbox, Phone Link, Media
# Player) are off by default because plenty of people actually use them.
$catalog = @(
    [pscustomobject]@{ Group='News and info'; Match='Microsoft.BingNews';                    Label='Microsoft News';              Recommended=$true }
    [pscustomobject]@{ Group='News and info'; Match='Microsoft.BingWeather';                 Label='Weather';                     Recommended=$true }
    [pscustomobject]@{ Group='News and info'; Match='Microsoft.BingSearch';                  Label='Bing web search';             Recommended=$true }

    [pscustomobject]@{ Group='Help and tips'; Match='Microsoft.GetHelp';                     Label='Get Help';                    Recommended=$true }
    [pscustomobject]@{ Group='Help and tips'; Match='Microsoft.Getstarted';                  Label='Tips';                        Recommended=$true }
    [pscustomobject]@{ Group='Help and tips'; Match='Microsoft.WindowsFeedbackHub';          Label='Feedback Hub';                Recommended=$true }

    [pscustomobject]@{ Group='Office and web'; Match='Microsoft.MicrosoftOfficeHub';         Label='Office / Microsoft 365 hub';  Recommended=$true }
    [pscustomobject]@{ Group='Office and web'; Match='Microsoft.Office.OneNote';             Label='OneNote (store version)';     Recommended=$false }
    [pscustomobject]@{ Group='Office and web'; Match='Microsoft.PowerAutomateDesktop';       Label='Power Automate';              Recommended=$true }
    [pscustomobject]@{ Group='Office and web'; Match='Clipchamp.Clipchamp';                  Label='Clipchamp video editor';      Recommended=$true }

    [pscustomobject]@{ Group='Communication'; Match='Microsoft.People';                      Label='People';                      Recommended=$true }
    [pscustomobject]@{ Group='Communication'; Match='Microsoft.Todos';                       Label='Microsoft To Do';             Recommended=$false }
    [pscustomobject]@{ Group='Communication'; Match='MicrosoftTeams';                        Label='Teams (personal)';            Recommended=$true }
    [pscustomobject]@{ Group='Communication'; Match='MSTeams';                               Label='Teams (personal, new)';       Recommended=$true }
    [pscustomobject]@{ Group='Communication'; Match='Microsoft.SkypeApp';                    Label='Skype';                       Recommended=$true }
    [pscustomobject]@{ Group='Communication'; Match='Microsoft.YourPhone';                   Label='Phone Link';                  Recommended=$false }

    [pscustomobject]@{ Group='Media';  Match='Microsoft.ZuneMusic';                          Label='Media Player (Groove)';       Recommended=$false }
    [pscustomobject]@{ Group='Media';  Match='Microsoft.ZuneVideo';                          Label='Movies and TV';               Recommended=$false }

    [pscustomobject]@{ Group='Maps and misc'; Match='Microsoft.WindowsMaps';                 Label='Maps';                        Recommended=$true }
    [pscustomobject]@{ Group='Maps and misc'; Match='Microsoft.WindowsAlarms';               Label='Clock / Alarms';              Recommended=$false }
    [pscustomobject]@{ Group='Maps and misc'; Match='Microsoft.MicrosoftSolitaireCollection';Label='Solitaire Collection';        Recommended=$true }
    [pscustomobject]@{ Group='Maps and misc'; Match='Microsoft.MixedReality.Portal';         Label='Mixed Reality Portal';        Recommended=$true }
    [pscustomobject]@{ Group='Maps and misc'; Match='Microsoft.549981C3F5F10';               Label='Cortana';                     Recommended=$true }

    [pscustomobject]@{ Group='Xbox and gaming'; Match='Microsoft.GamingApp';                 Label='Xbox app';                    Recommended=$false }
    [pscustomobject]@{ Group='Xbox and gaming'; Match='Microsoft.XboxGamingOverlay';         Label='Xbox Game Bar';               Recommended=$false }
    [pscustomobject]@{ Group='Xbox and gaming'; Match='Microsoft.XboxGameOverlay';           Label='Xbox Game overlay';           Recommended=$false }
    [pscustomobject]@{ Group='Xbox and gaming'; Match='Microsoft.XboxSpeechToTextOverlay';   Label='Xbox speech-to-text overlay'; Recommended=$false }
    [pscustomobject]@{ Group='Xbox and gaming'; Match='Microsoft.Xbox.TCUI';                 Label='Xbox live UI';                Recommended=$false }
)

# Only keep the ones actually installed so we don't show dead entries.
$installed = Get-AppxPackage -AllUsers | Select-Object -ExpandProperty Name -Unique
$present = $catalog | Where-Object {
    $m = $_.Match
    @($installed | Where-Object { $_ -eq $m -or $_ -like "$m*" }).Count -gt 0
}

function Remove-Chosen {
    param(
        [string[]]$Names,
        [bool]$MakeRestorePoint,
        [scriptblock]$Say
    )
    if ($MakeRestorePoint) {
        & $Say "Creating restore point..."
        try {
            Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
            Checkpoint-Computer -Description "Before Windows Cleanup" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
            & $Say "Restore point created."
        } catch {
            & $Say "Could not create a restore point (System Protection may be off). Continuing."
        }
    }
    foreach ($n in $Names) {
        & $Say "Removing $n..."
        try {
            Get-AppxPackage -AllUsers -Name $n -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
                Where-Object { $_.DisplayName -eq $n } |
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
        } catch {
            & $Say "  failed: $($_.Exception.Message)"
        }
    }
    & $Say "Done."
}

# ---------------------------------------------------------------------------
# Non-interactive: just remove the recommended set.
# ---------------------------------------------------------------------------
if ($Recommended) {
    $names = @($present | Where-Object Recommended | Select-Object -ExpandProperty Match)
    if (-not $names) { Write-Host "Nothing to remove."; return }
    Write-Host "Removing recommended apps: $($names.Count)"
    Remove-Chosen -Names $names -MakeRestorePoint (-not $SkipRestorePoint) -Say { param($t) Write-Host $t }
    return
}

# ---------------------------------------------------------------------------
# Console menu.
# ---------------------------------------------------------------------------
if ($NoGui) {
    if (-not $present) { Write-Host "None of the known removable apps are installed."; return }

    $indexed = @($present)
    Write-Host ""
    Write-Host "Windows Cleanup" -ForegroundColor Cyan
    Write-Host "Pick the apps to remove. Essentials (Store, Terminal, Calculator,"
    Write-Host "Photos, Snipping Tool, Windows Security, runtimes) are not listed."
    Write-Host ""

    $i = 0
    $lastGroup = ""
    foreach ($item in $indexed) {
        if ($item.Group -ne $lastGroup) {
            Write-Host ""
            Write-Host $item.Group -ForegroundColor Yellow
            $lastGroup = $item.Group
        }
        $mark = if ($item.Recommended) { "*" } else { " " }
        Write-Host ("  [{0,2}] {1} {2}" -f $i, $mark, $item.Label)
        $i++
    }
    Write-Host ""
    Write-Host "* = recommended"
    Write-Host "Enter numbers separated by commas, or R for recommended, A for all, Q to quit."
    $choice = Read-Host "Selection"

    if ($choice -match '^\s*[Qq]') { return }

    $picked = @()
    if ($choice -match '^\s*[Rr]') {
        $picked = @($indexed | Where-Object Recommended)
    } elseif ($choice -match '^\s*[Aa]') {
        $picked = $indexed
    } else {
        foreach ($token in ($choice -split ',')) {
            $n = $token.Trim()
            if ($n -match '^\d+$' -and [int]$n -lt $indexed.Count) { $picked += $indexed[[int]$n] }
        }
    }

    $picked = $picked | Select-Object -Unique
    if (-not $picked) { Write-Host "Nothing selected."; return }

    Write-Host ""
    Write-Host "About to remove:" -ForegroundColor Cyan
    $picked | ForEach-Object { Write-Host "  $($_.Label)" }
    if ((Read-Host "Proceed? (y/n)") -notmatch '^\s*[Yy]') { Write-Host "Cancelled."; return }

    $doRestore = $true
    if ($SkipRestorePoint) { $doRestore = $false }
    elseif ((Read-Host "Create a restore point first? (y/n)") -match '^\s*[Nn]') { $doRestore = $false }

    Remove-Chosen -Names @($picked.Match) -MakeRestorePoint $doRestore -Say { param($t) Write-Host $t }
    Write-Host ""
    Read-Host "Press Enter to close" | Out-Null
    return
}

# ---------------------------------------------------------------------------
# GUI.
# ---------------------------------------------------------------------------
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object Windows.Forms.Form
$form.Text = "Windows Cleanup"
$form.Size = New-Object Drawing.Size(600, 720)
$form.StartPosition = "CenterScreen"
$form.MinimumSize = New-Object Drawing.Size(520, 560)

$intro = New-Object Windows.Forms.Label
$intro.Text = "Tick the apps you want gone, then click Apply. Only ticked items are removed."
$intro.Location = New-Object Drawing.Point(12, 10)
$intro.Size = New-Object Drawing.Size(560, 20)
$form.Controls.Add($intro)

$safeNote = New-Object Windows.Forms.Label
$safeNote.Text = "The Store, Terminal, Calculator, Photos, Snipping Tool, Windows Security and the system runtimes are never touched."
$safeNote.Location = New-Object Drawing.Point(12, 30)
$safeNote.Size = New-Object Drawing.Size(560, 32)
$safeNote.ForeColor = [Drawing.Color]::DimGray
$form.Controls.Add($safeNote)

$panel = New-Object Windows.Forms.Panel
$panel.Location = New-Object Drawing.Point(12, 66)
$panel.Size = New-Object Drawing.Size(560, 430)
$panel.AutoScroll = $true
$panel.BorderStyle = "FixedSingle"
$panel.Anchor = "Top,Left,Right,Bottom"
$form.Controls.Add($panel)

$boxes = @()
$y = 8
foreach ($group in ($present | Group-Object Group)) {
    $header = New-Object Windows.Forms.Label
    $header.Text = $group.Name
    $header.Font = New-Object Drawing.Font($form.Font, [Drawing.FontStyle]::Bold)
    $header.Location = New-Object Drawing.Point(8, $y)
    $header.Size = New-Object Drawing.Size(520, 18)
    $panel.Controls.Add($header)
    $y += 22

    foreach ($item in $group.Group) {
        $cb = New-Object Windows.Forms.CheckBox
        $cb.Text = $item.Label
        $cb.Checked = $item.Recommended
        $cb.Location = New-Object Drawing.Point(24, $y)
        $cb.Size = New-Object Drawing.Size(500, 20)
        $cb.Tag = $item.Match
        $panel.Controls.Add($cb)
        $boxes += $cb
        $y += 24
    }
    $y += 6
}

$restoreCheck = New-Object Windows.Forms.CheckBox
$restoreCheck.Text = "Create a system restore point first (recommended)"
$restoreCheck.Checked = $true
$restoreCheck.Location = New-Object Drawing.Point(12, 502)
$restoreCheck.Size = New-Object Drawing.Size(400, 20)
$restoreCheck.Anchor = "Left,Bottom"
$form.Controls.Add($restoreCheck)

$btnRecommended = New-Object Windows.Forms.Button
$btnRecommended.Text = "Select recommended"
$btnRecommended.Location = New-Object Drawing.Point(12, 528)
$btnRecommended.Size = New-Object Drawing.Size(140, 26)
$btnRecommended.Anchor = "Left,Bottom"
$form.Controls.Add($btnRecommended)

$btnNone = New-Object Windows.Forms.Button
$btnNone.Text = "Clear all"
$btnNone.Location = New-Object Drawing.Point(158, 528)
$btnNone.Size = New-Object Drawing.Size(90, 26)
$btnNone.Anchor = "Left,Bottom"
$form.Controls.Add($btnNone)

$btnApply = New-Object Windows.Forms.Button
$btnApply.Text = "Apply"
$btnApply.Location = New-Object Drawing.Point(472, 528)
$btnApply.Size = New-Object Drawing.Size(100, 26)
$btnApply.Anchor = "Right,Bottom"
$form.Controls.Add($btnApply)

$log = New-Object Windows.Forms.TextBox
$log.Multiline = $true
$log.ScrollBars = "Vertical"
$log.ReadOnly = $true
$log.Location = New-Object Drawing.Point(12, 562)
$log.Size = New-Object Drawing.Size(560, 110)
$log.Anchor = "Left,Right,Bottom"
$form.Controls.Add($log)

$sayGui = {
    param($t)
    $log.AppendText(("{0}  {1}{2}" -f (Get-Date -Format "HH:mm:ss"), $t, [Environment]::NewLine))
    [Windows.Forms.Application]::DoEvents()
}

$btnRecommended.Add_Click({
    foreach ($cb in $boxes) {
        $item = $present | Where-Object { $_.Match -eq $cb.Tag } | Select-Object -First 1
        $cb.Checked = [bool]$item.Recommended
    }
})

$btnNone.Add_Click({ foreach ($cb in $boxes) { $cb.Checked = $false } })

$btnApply.Add_Click({
    $chosen = $boxes | Where-Object { $_.Checked }
    if (-not $chosen) {
        [Windows.Forms.MessageBox]::Show("Nothing is ticked.", "Windows Cleanup") | Out-Null
        return
    }
    $answer = [Windows.Forms.MessageBox]::Show(
        "Remove $($chosen.Count) app(s)? This applies to all user accounts on this PC.",
        "Confirm", "YesNo", "Question")
    if ($answer -ne "Yes") { return }

    $btnApply.Enabled = $false
    Remove-Chosen -Names @($chosen.Tag) -MakeRestorePoint $restoreCheck.Checked -Say $sayGui
    foreach ($cb in $chosen) { $cb.Enabled = $false }
    $btnApply.Enabled = $true
    [Windows.Forms.MessageBox]::Show("Finished. A sign-out or restart helps some changes settle.", "Windows Cleanup") | Out-Null
})

if (-not $present) { & $sayGui "None of the known removable apps are installed on this PC." }

[void]$form.ShowDialog()
