<#
  SEAD/DEAD Hornet Mod - Installer
  Patches the EXISTING FA-18C_hornet.lua / UnitPayloads\FA-18C_hornet.lua
  in place by APPENDING a small block right before/after the anchor
  that ends each file (a lone function call at EOF for the pylon
  file, the "return unitPayloads" statement for the payloads file).
  Both anchors are structural necessities of the file, not text any
  other mod is likely to remove - so this does not depend on any
  mid-file line surviving untouched by other mods.

  How it works (see README for details):
    - outboardLeft/outboardRight/inboardLeft/inboardRight are `local`
      tables declared earlier in FA-18C_hornet.lua. Appending
      table.insert(...) calls at the END of that same file still sees
      those locals (same Lua chunk/closure) and runs before
      make_FA_18C_hornet() is ever invoked (that happens from outside
      this file, later) - so our entries are present by the time the
      pylon list is actually built.
    - unitPayloads.payloads is a field on the table this file returns.
      Appending to it right before "return unitPayloads" is safe for
      the same reason.

  File I/O uses raw .NET ReadAllText/WriteAllText (UTF-8, no BOM)
  instead of Get-Content/Set-Content, because Windows PowerShell's
  default encoding detection can silently corrupt this file's
  existing non-ASCII (Cyrillic) comments on a read/write round trip.

  Run this from an elevated (Administrator) PowerShell.
#>

param(
    [string]$DcsPath,
    [string]$SavedGamesPath
)

$ErrorActionPreference = "Stop"
$MARK_BEGIN = "-- >>> SEAD_DEAD_MOD"
$MARK_END   = "-- <<< SEAD_DEAD_MOD"
$Utf8NoBom  = New-Object System.Text.UTF8Encoding($false)

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "This script must run as Administrator (writes to Program Files)." -ForegroundColor Red
        Write-Host "Right-click Install.ps1 -> 'Run with PowerShell' as Administrator, or open an elevated PowerShell and re-run it." -ForegroundColor Yellow
        exit 1
    }
}

function Resolve-InteractivePath {
    param(
        [string]$Override,
        [string[]]$Candidates,
        [string]$FriendlyName,
        [switch]$Optional
    )
    if ($Override) {
        if (Test-Path $Override) { return $Override }
        Write-Host "The path you passed for $FriendlyName does not exist: $Override" -ForegroundColor Yellow
    }
    $found = @($Candidates | Where-Object { Test-Path $_ })
    if ($found.Count -eq 1) {
        $ans = Read-Host "Found $FriendlyName at `"$($found[0])`" - use this? [Y/n]"
        if ($ans -eq "" -or $ans -match "^[Yy]") { return $found[0] }
    } elseif ($found.Count -gt 1) {
        Write-Host "Found multiple possible locations for $FriendlyName :"
        for ($i = 0; $i -lt $found.Count; $i++) { Write-Host "  [$($i+1)] $($found[$i])" }
        $sel = Read-Host "Pick a number, or press Enter to type a custom path"
        if ($sel -match '^\d+$' -and [int]$sel -ge 1 -and [int]$sel -le $found.Count) {
            return $found[[int]$sel - 1]
        }
    } else {
        Write-Host "Could not auto-detect $FriendlyName." -ForegroundColor Yellow
    }
    $manual = Read-Host "Enter the full path to your $FriendlyName folder (or press Enter to skip)"
    if ([string]::IsNullOrWhiteSpace($manual)) {
        if ($Optional) { return $null }
        throw "$FriendlyName is required to continue."
    }
    if (-not (Test-Path $manual)) { throw "Path does not exist: $manual" }
    return $manual
}

function Read-TextFile  { param([string]$Path) return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
function Write-TextFile { param([string]$Path, [string]$Content) [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom) }

function Backup-File {
    param([string]$Path, [string]$BackupRoot)
    if (-not (Test-Path $Path)) { return }
    Copy-Item $Path (Join-Path $BackupRoot (Split-Path $Path -Leaf)) -Force
    Write-Host "  Backed up: $Path"
}

# ---------------------------------------------------------------------
Assert-Admin

$DcsCandidates = @(
    "C:\Program Files\Eagle Dynamics\DCS World",
    "C:\Program Files\Eagle Dynamics\DCS World OpenBeta",
    "C:\Program Files (x86)\Steam\steamapps\common\DCSWorld",
    "C:\Program Files (x86)\Steam\steamapps\common\DCS World"
)
$Dcs = Resolve-InteractivePath -Override $DcsPath -Candidates $DcsCandidates -FriendlyName "your DCS World install"
Write-Host "Using DCS install: $Dcs" -ForegroundColor Cyan

$SavedGamesCandidates = @(
    (Join-Path $env:USERPROFILE "Saved Games\DCS"),
    (Join-Path $env:USERPROFILE "Saved Games\DCS.openbeta")
)
$SavedGames = Resolve-InteractivePath -Override $SavedGamesPath -Candidates $SavedGamesCandidates `
    -FriendlyName "your DCS Saved Games folder (only used to point you at dcs.log afterward)" -Optional
if ($SavedGames) { Write-Host "Using Saved Games folder: $SavedGames" -ForegroundColor Cyan }

$PkgRoot   = Join-Path $PSScriptRoot "DROP CONTENTS IN MAIN DIRECTORY\CoreMods\aircraft\FA-18C"
$Fa18File  = Join-Path $Dcs "CoreMods\aircraft\FA-18C\FA-18C_hornet.lua"
$PayFile   = Join-Path $Dcs "CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua"
$CustomSrc = Join-Path $PkgRoot "CustomWeapons\dead_sead_racks.lua"
$CustomDst = Join-Path $Dcs "CoreMods\aircraft\FA-18C\CustomWeapons\dead_sead_racks.lua"

if (-not (Test-Path $Fa18File)) { throw "Not found: $Fa18File - is this really a DCS World install?" }
if (-not (Test-Path $PayFile))  { throw "Not found: $PayFile" }
if (-not (Test-Path $CustomSrc)) { throw "Not found: $CustomSrc" }

$fa18Content = Read-TextFile $Fa18File
if ($fa18Content.Contains($MARK_BEGIN)) {
    Write-Host "Already installed (marker found in FA-18C_hornet.lua). Run Uninstall.ps1 first if you want to reinstall." -ForegroundColor Yellow
    exit 0
}

# 1) Backup originals - kept next to this script, one folder per run, never overwritten.
$BackupRoot = Join-Path $PSScriptRoot ("backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Force $BackupRoot | Out-Null
Write-Host "Backing up originals to $BackupRoot ..."
Backup-File -Path $Fa18File -BackupRoot $BackupRoot
Backup-File -Path $PayFile  -BackupRoot $BackupRoot

# 2) Append to FA-18C_hornet.lua (end of file - no mid-file anchor needed).
#    dofile() is wrapped in pcall so a problem loading the new weapons
#    file can't take down the whole aircraft/database load.
$fa18Block = @(
    $MARK_BEGIN,
    "local ok, err = pcall(dofile, current_mod_path..'/CustomWeapons/dead_sead_racks.lua')",
    "if not ok then",
    "	if log and log.write then",
    "		log.write('SEAD_DEAD_MOD', log.ERROR, 'Failed to load dead_sead_racks.lua: '..tostring(err))",
    "	else",
    "		print('[SEAD_DEAD_MOD] Failed to load dead_sead_racks.lua: '..tostring(err))",
    "	end",
    "end",
    "table.insert(outboardLeft,  { CLSID = `"{BRU55_2xAGM88}`",    Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })",
    "table.insert(outboardLeft,  { CLSID = `"{BRU42A_x3_AGM65E}`", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })",
    "table.insert(outboardRight, { CLSID = `"{BRU55_2xAGM88}`",    Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })",
    "table.insert(outboardRight, { CLSID = `"{BRU42A_x3_AGM65E}`", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })",
    "table.insert(inboardLeft,   { CLSID = `"{BRU55_2xAGM88}`",    Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })",
    "table.insert(inboardLeft,   { CLSID = `"{BRU42A_x3_AGM65E}`", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })",
    "table.insert(inboardRight,  { CLSID = `"{BRU55_2xAGM88}`",    Cx_gain_empty = 0.371, Cx_gain_item = 0.621 })",
    "table.insert(inboardRight,  { CLSID = `"{BRU42A_x3_AGM65E}`", Cx_gain_empty = 0.338, Cx_gain_item = 1.593 })",
    $MARK_END
)
$fa18New = $fa18Content.TrimEnd("`r", "`n") + "`r`n" + ($fa18Block -join "`r`n") + "`r`n"
Write-TextFile -Path $Fa18File -Content $fa18New
Write-Host "Patched (appended): $Fa18File"

# 3) Insert into UnitPayloads\FA-18C_hornet.lua right before "return unitPayloads"
#    (the file's mandatory last line - the one anchor guaranteed to exist).
$presetBlock = @(
    $MARK_BEGIN,
    'table.insert(unitPayloads.payloads, {',
    '	["name"] = "[SEAD] AGM-88*8, FUEL*1",',
    '	["pylons"] = {',
    '		[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 2},',
    '		[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},',
    '		[3] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},',
    '		[4] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 8},',
    '		[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},',
    '		[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},',
    '		[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},',
    '	},',
    '	["tasks"] = { [1] = 19 },',
    '})',
    'table.insert(unitPayloads.payloads, {',
    '	["name"] = "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1",',
    '	["pylons"] = {',
    '		[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},',
    '		[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},',
    '		[3] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 2},',
    '		[4] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 8},',
    '		[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},',
    '		[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},',
    '		[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},',
    '	},',
    '	["tasks"] = { [1] = 19 },',
    '})',
    $MARK_END
)
$payContent = Read-TextFile $PayFile
$returnPattern = [regex]::new("(?m)^return\s+unitPayloads\s*$")
if (-not $returnPattern.IsMatch($payContent)) {
    throw "Could not find 'return unitPayloads' in $PayFile - manual merge needed (see README)."
}
$insertText = ($presetBlock -join "`r`n") + "`r`n"
$payNew = $returnPattern.Replace($payContent, { param($m) $insertText + $m.Value }, 1)
Write-TextFile -Path $PayFile -Content $payNew
Write-Host "Patched (inserted before return): $PayFile"

# 4) Drop in the new weapon-declaration file (brand new file, no merge needed)
New-Item -ItemType Directory -Force (Split-Path $CustomDst) | Out-Null
Copy-Item $CustomSrc $CustomDst -Force
Write-Host "Installed: $CustomDst"

Write-Host ""
Write-Host "Done. Launch DCS and check the F/A-18C loadout editor (stations 2/3/7/8) and the rearm menu." -ForegroundColor Green
if ($SavedGames) {
    Write-Host "If something doesn't show up, check the log: $SavedGames\Logs\dcs.log" -ForegroundColor Green
}
Write-Host "To remove this mod later, run Uninstall.ps1 (as Administrator)." -ForegroundColor Green
