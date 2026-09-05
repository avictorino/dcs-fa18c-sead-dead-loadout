<#
  SEAD/DEAD Hornet Mod - Uninstaller
  Removes only the marker-bounded blocks this mod inserted into
  FA-18C_hornet.lua / UnitPayloads\FA-18C_hornet.lua, leaving any
  other mod's edits to those same files untouched. Also removes the
  CustomWeapons\dead_sead_racks.lua file this mod added.

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

function Remove-MarkedBlocks {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return 0 }
    $content = Read-TextFile $Path
    $pattern = [regex]::new(
        [regex]::Escape($MARK_BEGIN) + ".*?" + [regex]::Escape($MARK_END) + "\r?\n?",
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    $matches = $pattern.Matches($content)
    if ($matches.Count -eq 0) { return 0 }
    $newContent = $pattern.Replace($content, "")
    Write-TextFile -Path $Path -Content $newContent
    return $matches.Count
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

$Fa18File  = Join-Path $Dcs "CoreMods\aircraft\FA-18C\FA-18C_hornet.lua"
$PayFile   = Join-Path $Dcs "CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua"
$CustomDst = Join-Path $Dcs "CoreMods\aircraft\FA-18C\CustomWeapons\dead_sead_racks.lua"
$CustomDir = Split-Path $CustomDst

$n1 = Remove-MarkedBlocks -Path $Fa18File
Write-Host "Removed $n1 marked block(s) from: $Fa18File"

$n2 = Remove-MarkedBlocks -Path $PayFile
Write-Host "Removed $n2 marked block(s) from: $PayFile"

if (Test-Path $CustomDst) {
    Remove-Item $CustomDst -Force
    Write-Host "Removed: $CustomDst"
    if ((Test-Path $CustomDir) -and ((Get-ChildItem $CustomDir -Force | Measure-Object).Count -eq 0)) {
        Remove-Item $CustomDir -Force
        Write-Host "Removed empty folder: $CustomDir"
    }
}

if ($n1 -eq 0 -and $n2 -eq 0) {
    Write-Host "Nothing to remove - mod does not appear to be installed." -ForegroundColor Yellow
} else {
    Write-Host ""
    Write-Host "Done. Mod removed; any other mods' edits to these files were left untouched." -ForegroundColor Green
    if ($SavedGames) {
        Write-Host "Log for reference: $SavedGames\Logs\dcs.log" -ForegroundColor Green
    }
}
