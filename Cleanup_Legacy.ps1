<#
  One-off cleanup for leftovers from the very first ("robocopy full-file
  overwrite") version of this mod, from before Install.ps1/Uninstall.ps1
  existed. Those edits were never wrapped in -- >>> SEAD_DEAD_MOD markers,
  so Uninstall.ps1 has no way to find and remove them. This script removes
  that exact old content via regex (tolerant of CRLF vs bare LF, since
  that early version's full-file replacement mixed the two).

  Safe to run even if the legacy blocks aren't present, or only partially
  present (each removal is a no-op if its pattern isn't found). Run as
  Administrator.
#>

param(
    [string]$DcsPath = "C:\Program Files\Eagle Dynamics\DCS World"
)

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$NL = "\r?\n"  # tolerate either line-ending style found in the legacy content

function Assert-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "Run this as Administrator." -ForegroundColor Red
        exit 1
    }
}
function Read-TextFile  { param([string]$Path) return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8) }
function Write-TextFile { param([string]$Path, [string]$Content) [System.IO.File]::WriteAllText($Path, $Content, $Utf8NoBom) }

Assert-Admin

# --- UnitPayloads\FA-18C_hornet.lua : remove the old unmarked [26]/[27] presets ---
$PayFile = Join-Path $DcsPath "CoreMods\aircraft\FA-18C\UnitPayloads\FA-18C_hornet.lua"
$payPatternText = @'
[26] = {
			["name"] = "[SEAD] AGM-88*8, FUEL*1",
			["pylons"] = {
				[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 2},
				[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},
				[3] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},
				[4] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 8},
				[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},
				[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},
				[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},
			},
			["tasks"] = {
				[1] = 19,
			},
		},
		[27] = {
			["name"] = "[SEAD+DEAD] AGM-88*4, AGM-65E*6, FUEL*1",
			["pylons"] = {
				[1] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 3},
				[2] = {["CLSID"] = "{BRU55_2xAGM88}", ["num"] = 7},
				[3] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 2},
				[4] = {["CLSID"] = "{BRU42A_x3_AGM65E}", ["num"] = 8},
				[5] = {["CLSID"] = "{FPU_8A_FUEL_TANK}", ["num"] = 5},
				[6] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 1},
				[7] = {["CLSID"] = "{6CEB49FC-DED8-4DED-B053-E1F033FF72D3}", ["num"] = 9},
			},
			["tasks"] = {
				[1] = 19,
			},
		},
'@
# Turn the literal block above into a line-ending-tolerant regex: escape
# everything, then relax the line joins to \r?\n, and eat one leading
# blank line before it (the separator left over from the original insert).
$payLines = $payPatternText -split "`r?`n"
$payRegexBody = ($payLines | ForEach-Object { [regex]::Escape($_) }) -join $NL
$payPattern = [regex]::new("(?:$NL)?(?:$NL)?\t\t$payRegexBody", [System.Text.RegularExpressions.RegexOptions]::Singleline)

if (Test-Path $PayFile) {
    $c = Read-TextFile $PayFile
    if ($payPattern.IsMatch($c)) {
        $c2 = $payPattern.Replace($c, "")
        Write-TextFile -Path $PayFile -Content $c2
        Write-Host "Removed legacy [26]/[27] preset block from: $PayFile" -ForegroundColor Green
    } else {
        Write-Host "Legacy preset block not found (already clean) in: $PayFile" -ForegroundColor Yellow
    }
} else {
    Write-Host "Not found: $PayFile" -ForegroundColor Yellow
}

# --- FA-18C_hornet.lua : remove the old unmarked rack-option lines (appear twice) ---
$Fa18File = Join-Path $DcsPath "CoreMods\aircraft\FA-18C\FA-18C_hornet.lua"
$line1 = [regex]::Escape('{ CLSID = "{BRU55_2xAGM88}",') + "\t+" + [regex]::Escape('Cx_gain_empty = 0.371, Cx_gain_item = 0.621') + "\t" + [regex]::Escape('},') + "\t" + [regex]::Escape('-- [SEAD/DEAD Mod] BRU-55 2*AGM-88')
$line2 = [regex]::Escape('{ CLSID = "{BRU42A_x3_AGM65E}",') + "\t+" + [regex]::Escape('Cx_gain_empty = 0.338, Cx_gain_item = 1.593') + "\t" + [regex]::Escape('},') + "\t" + [regex]::Escape('-- [SEAD/DEAD Mod] BRU-42A 3*AGM-65E')
$rackPattern = [regex]::new("(?:$NL)\t$line1(?:$NL)\t$line2(?:$NL)")

if (Test-Path $Fa18File) {
    $c = Read-TextFile $Fa18File
    $matchCount = $rackPattern.Matches($c).Count
    if ($matchCount -gt 0) {
        $c2 = $rackPattern.Replace($c, "")
        Write-TextFile -Path $Fa18File -Content $c2
        Write-Host "Removed $matchCount legacy rack-option block(s) from: $Fa18File" -ForegroundColor Green
    } else {
        Write-Host "Legacy rack-option lines not found (already clean) in: $Fa18File" -ForegroundColor Yellow
    }
} else {
    Write-Host "Not found: $Fa18File" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
