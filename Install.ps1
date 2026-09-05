<#
  SEAD/DEAD Hornet Mod - Installer
  Patches the EXISTING FA-18C_hornet.lua in place by APPENDING a small
  block at the end of the file (a lone function call is the last line of
  the stock file - a stable, structural anchor other mods are unlikely
  to remove, so this does not depend on any mid-file line surviving
  untouched).

  This mod only adds pylon rack OPTIONS (BRU-55 2x AGM-88, BRU-42A 3x
  AGM-65E) - it does not touch UnitPayloads or add any rearm/Mission
  Editor presets. Pick and mix them yourself in the loadout editor.

  How it works (see README for details):
    - outboardLeft/outboardRight/inboardLeft/inboardRight are `local`
      tables declared earlier in FA-18C_hornet.lua. Appending
      table.insert(...) calls at the END of that same file still sees
      those locals (same Lua chunk/closure) and runs before
      make_FA_18C_hornet() is ever invoked (that happens from outside
      this file, later) - so our entries are present by the time the
      pylon list is actually built.

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
# This is where the mod's actual .lua file gets placed - see note below on
# why Program Files isn't used for it.
$SavedGames = Resolve-InteractivePath -Override $SavedGamesPath -Candidates $SavedGamesCandidates `
    -FriendlyName "your DCS Saved Games folder"
Write-Host "Using Saved Games folder: $SavedGames" -ForegroundColor Cyan

$PkgRoot   = Join-Path $PSScriptRoot "DROP CONTENTS IN MAIN DIRECTORY\CoreMods\aircraft\FA-18C"
$Fa18File  = Join-Path $Dcs "CoreMods\aircraft\FA-18C\FA-18C_hornet.lua"
# The mod's actual logic file (dead_sead_racks.lua) is loaded via an
# ABSOLUTE path baked into the tiny block appended to Fa18File - Lua's
# loadfile() is plain OS file access, it doesn't go through DCS's mod/VFS
# system at all. So this file doesn't need to live under the DCS install
# (Program Files) like the stock file it patches - putting it in Saved
# Games instead means a DCS repair/verify pass has no reason to ever
# touch or flag it.
$CustomDir = Join-Path $SavedGames "Mods\aircraft\FA-18C\CustomWeapons"
$RacksSrc  = Join-Path $PkgRoot "CustomWeapons\dead_sead_racks.lua"
$RacksDst  = Join-Path $CustomDir "dead_sead_racks.lua"

if (-not (Test-Path $Fa18File)) { throw "Not found: $Fa18File - is this really a DCS World install?" }
if (-not (Test-Path $RacksSrc)) { throw "Not found: $RacksSrc" }

# Bake the absolute install-time path into the generated Lua as a plain
# string literal (forward slashes), instead of relying on any Lua global
# like current_mod_path/lfs.currentdir() being valid in this Lua state.
$RacksDstLua = $RacksDst.Replace('\', '/')

$fa18Content = Read-TextFile $Fa18File
if ($fa18Content.Contains($MARK_BEGIN)) {
    Write-Host "Already installed (marker found in FA-18C_hornet.lua). Run Uninstall.ps1 first if you want to reinstall." -ForegroundColor Yellow
} else {
    # 1) Backup the original - kept next to this script, one folder per run, never overwritten.
    $BackupRoot = Join-Path $PSScriptRoot ("backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    New-Item -ItemType Directory -Force $BackupRoot | Out-Null
    Write-Host "Backing up original to $BackupRoot ..."
    Backup-File -Path $Fa18File -BackupRoot $BackupRoot

    # 2) Append to FA-18C_hornet.lua (end of file - no mid-file anchor needed).
    #    All this mod's actual logic lives in CustomWeapons\dead_sead_racks.lua.
    #    It's loaded via loadfile()+call (not dofile()) so it can receive the
    #    local outboardLeft/outboardRight/inboardLeft/inboardRight pylon-option
    #    tables as arguments and append its own new rack options to them - the
    #    only reason it can reach those normally-out-of-scope locals at all.
    #    NOTE: pcall() is NOT available in this Lua state (DCS's aircraft/weapon
    #    database loader) - confirmed empirically (calling it throws "attempt to
    #    call global 'pcall' (a nil value)"), so this can't be wrapped in a true
    #    try/catch. loadfile() itself is safe though - it returns nil + an error
    #    string on failure instead of throwing - so a missing/broken file is
    #    still handled gracefully and logged instead of crashing anything.
    $fa18Block = @(
        $MARK_BEGIN,
        "local chunk, loadErr = loadfile(`"$RacksDstLua`")",
        "if chunk then",
        "	chunk(outboardLeft, outboardRight, inboardLeft, inboardRight)",
        "else",
        "	if log and log.write then",
        "		log.write('SEAD_DEAD_MOD', log.ERROR, 'Failed to load dead_sead_racks.lua: '..tostring(loadErr))",
        "	else",
        "		print('[SEAD_DEAD_MOD] Failed to load dead_sead_racks.lua: '..tostring(loadErr))",
        "	end",
        "end",
        $MARK_END
    )
    $fa18New = $fa18Content.TrimEnd("`r", "`n") + "`r`n" + ($fa18Block -join "`r`n") + "`r`n"
    Write-TextFile -Path $Fa18File -Content $fa18New
    Write-Host "Patched (appended): $Fa18File"
}

# 3) Drop in the new weapon-declaration file (brand new file, no merge needed)
New-Item -ItemType Directory -Force $CustomDir | Out-Null
Copy-Item $RacksSrc $RacksDst -Force
Write-Host "Installed: $RacksDst"

Write-Host ""
Write-Host "Done. Launch DCS and check the F/A-18C loadout editor (stations 2/3/7/8)." -ForegroundColor Green
Write-Host "If something doesn't show up, check the log: $SavedGames\Logs\dcs.log" -ForegroundColor Green
Write-Host "To remove this mod later, run Uninstall.ps1 (as Administrator)." -ForegroundColor Green
