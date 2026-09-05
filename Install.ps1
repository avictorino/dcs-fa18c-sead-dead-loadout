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
# Required now (not just for the closing log-path hint): this is where the
# mod's actual .lua files get placed - see note below on why Program Files
# isn't used for these two files.
$SavedGames = Resolve-InteractivePath -Override $SavedGamesPath -Candidates $SavedGamesCandidates `
    -FriendlyName "your DCS Saved Games folder"
Write-Host "Using Saved Games folder: $SavedGames" -ForegroundColor Cyan

$PkgRoot      = Join-Path $PSScriptRoot "DROP CONTENTS IN MAIN DIRECTORY\CoreMods\aircraft\FA-18C"
$Fa18File     = Join-Path $Dcs "CoreMods\aircraft\FA-18C\FA-18C_hornet.lua"
$PayFile      = Join-Path $Dcs "CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua"
# The mod's actual logic files (dead_sead_racks.lua / dead_sead_presets.lua)
# are loaded via an ABSOLUTE path baked into the tiny block appended to the
# two files above - Lua's loadfile() is plain OS file access, it doesn't go
# through DCS's mod/VFS system at all. So these two files don't need to live
# under the DCS install (Program Files) like the stock files they patch -
# putting them in Saved Games instead means a DCS repair/verify pass has no
# reason to ever touch or flag them.
$CustomDir    = Join-Path $SavedGames "Mods\aircraft\FA-18C\CustomWeapons"
$RacksSrc     = Join-Path $PkgRoot "CustomWeapons\dead_sead_racks.lua"
$RacksDst     = Join-Path $CustomDir "dead_sead_racks.lua"
$PresetsSrc   = Join-Path $PkgRoot "CustomWeapons\dead_sead_presets.lua"
$PresetsDst   = Join-Path $CustomDir "dead_sead_presets.lua"

if (-not (Test-Path $Fa18File)) { throw "Not found: $Fa18File - is this really a DCS World install?" }
if (-not (Test-Path $PayFile))  { throw "Not found: $PayFile" }
if (-not (Test-Path $RacksSrc)) { throw "Not found: $RacksSrc" }
if (-not (Test-Path $PresetsSrc)) { throw "Not found: $PresetsSrc" }

# Bake the absolute install-time path into the generated Lua as a plain
# string literal (forward slashes), instead of relying on any Lua global
# like current_mod_path/lfs.currentdir() being valid in whatever state
# loads each file - UnitPayloads\FA-18C_hornet.lua in particular is
# loaded through a different path than the aircraft's own entry.lua
# chain, and there's no evidence current_mod_path exists there.
$RacksDstLua   = $RacksDst.Replace('\', '/')
$PresetsDstLua = $PresetsDst.Replace('\', '/')

# Each target file is checked and patched INDEPENDENTLY - don't assume
# both are always in sync (a prior run could have been interrupted, or
# one file could have been hand-edited/restored separately).
$fa18Content = Read-TextFile $Fa18File
$payContent  = Read-TextFile $PayFile
$fa18AlreadyDone = $fa18Content.Contains($MARK_BEGIN)
$payAlreadyDone  = $payContent.Contains($MARK_BEGIN)

if ($fa18AlreadyDone -and $payAlreadyDone) {
    Write-Host "Already installed (marker found in both files). Run Uninstall.ps1 first if you want to reinstall." -ForegroundColor Yellow
    exit 0
}

# 1) Backup originals - kept next to this script, one folder per run, never overwritten.
$BackupRoot = Join-Path $PSScriptRoot ("backups\" + (Get-Date -Format "yyyyMMdd_HHmmss"))
New-Item -ItemType Directory -Force $BackupRoot | Out-Null
Write-Host "Backing up originals to $BackupRoot ..."
if (-not $fa18AlreadyDone) { Backup-File -Path $Fa18File -BackupRoot $BackupRoot }
if (-not $payAlreadyDone)  { Backup-File -Path $PayFile  -BackupRoot $BackupRoot }

# 2) Append to FA-18C_hornet.lua (end of file - no mid-file anchor needed).
#    All this mod's actual logic lives in CustomWeapons\dead_sead_racks.lua.
#    It's loaded via loadfile()+call (not dofile()) so it can receive the
#    local outboardLeft/outboardRight/inboardLeft/inboardRight pylon-option
#    tables as arguments and append its own new rack options to them - the
#    only reason it can reach those normally-out-of-scope locals at all.
#    Wrapped in pcall so a problem loading that file can't take down the
#    whole aircraft/database load.
$fa18Block = @(
    $MARK_BEGIN,
    "local ok, err = pcall(function()",
    "	local chunk = assert(loadfile(`"$RacksDstLua`"))",
    "	chunk(outboardLeft, outboardRight, inboardLeft, inboardRight)",
    "end)",
    "if not ok then",
    "	if log and log.write then",
    "		log.write('SEAD_DEAD_MOD', log.ERROR, 'Failed to load dead_sead_racks.lua: '..tostring(err))",
    "	else",
    "		print('[SEAD_DEAD_MOD] Failed to load dead_sead_racks.lua: '..tostring(err))",
    "	end",
    "end",
    $MARK_END
)
if ($fa18AlreadyDone) {
    Write-Host "Skipped (already patched): $Fa18File" -ForegroundColor Yellow
} else {
    $fa18New = $fa18Content.TrimEnd("`r", "`n") + "`r`n" + ($fa18Block -join "`r`n") + "`r`n"
    Write-TextFile -Path $Fa18File -Content $fa18New
    Write-Host "Patched (appended): $Fa18File"
}

# 3) Insert into UnitPayloads\FA-18C_hornet.lua right before "return unitPayloads"
#    (the file's mandatory last line - the one anchor guaranteed to exist).
#    Same loadfile()+call trick: dead_sead_presets.lua receives the local
#    `unitPayloads` table as an argument and appends its own preset entries
#    to unitPayloads.payloads itself - all the actual preset data lives in
#    that file, not here.
$presetBlock = @(
    $MARK_BEGIN,
    "local ok, err = pcall(function()",
    "	local chunk = assert(loadfile(`"$PresetsDstLua`"))",
    "	chunk(unitPayloads)",
    "end)",
    "if not ok then",
    "	if log and log.write then",
    "		log.write('SEAD_DEAD_MOD', log.ERROR, 'Failed to load dead_sead_presets.lua: '..tostring(err))",
    "	else",
    "		print('[SEAD_DEAD_MOD] Failed to load dead_sead_presets.lua: '..tostring(err))",
    "	end",
    "end",
    $MARK_END
)
if ($payAlreadyDone) {
    Write-Host "Skipped (already patched): $PayFile" -ForegroundColor Yellow
} else {
    $returnPattern = [regex]::new("(?m)^return\s+unitPayloads\s*$")
    if (-not $returnPattern.IsMatch($payContent)) {
        throw "Could not find 'return unitPayloads' in $PayFile - manual merge needed (see README)."
    }
    $insertText = ($presetBlock -join "`r`n") + "`r`n"
    $payNew = $returnPattern.Replace($payContent, { param($m) $insertText + $m.Value }, 1)
    Write-TextFile -Path $PayFile -Content $payNew
    Write-Host "Patched (inserted before return): $PayFile"
}

# 4) Drop in the new weapon-declaration file (brand new file, no merge needed)
New-Item -ItemType Directory -Force $CustomDir | Out-Null
Copy-Item $RacksSrc   $RacksDst   -Force
Copy-Item $PresetsSrc $PresetsDst -Force
Write-Host "Installed: $RacksDst"
Write-Host "Installed: $PresetsDst"

Write-Host ""
Write-Host "Done. Launch DCS and check the F/A-18C loadout editor (stations 2/3/7/8) and the rearm menu." -ForegroundColor Green
if ($SavedGames) {
    Write-Host "If something doesn't show up, check the log: $SavedGames\Logs\dcs.log" -ForegroundColor Green
}
Write-Host "To remove this mod later, run Uninstall.ps1 (as Administrator)." -ForegroundColor Green
