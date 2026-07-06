# Sync SumatraPDF settings between this repo and the live file.
#
# Sumatra has no config-path env var and mixes settings with per-PC state
# (window positions, sessions, open counts) in one file it rewrites
# constantly - so the live file can't be versioned or symlinked directly.
# Sumatra itself separates the halves with a marker comment; only the
# config half lives in the repo (sumatra/SumatraPDF-settings.txt).
#
#   sumatra-settings.ps1 capture   live config half -> repo (then commit)
#   sumatra-settings.ps1 apply     repo -> live file, keeping local state
param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateSet('apply', 'capture')]
    [string]$Mode,

    # Overridable for testing against a copy.
    [string]$LiveFile = "$env:LOCALAPPDATA\SumatraPDF\SumatraPDF-settings.txt"
)

$ErrorActionPreference = 'Stop'
$RepoFile = Join-Path $PSScriptRoot '..\sumatra\SumatraPDF-settings.txt'
$Marker = "# You're not expected to change those manually"

function Split-Settings([string]$Path) {
    $text = Get-Content $Path -Raw
    $idx = $text.IndexOf($Marker)
    if ($idx -lt 0) { return @{ Config = $text; State = '' } }
    @{ Config = $text.Substring(0, $idx); State = $text.Substring($idx) }
}

switch ($Mode) {
    'capture' {
        (Split-Settings $LiveFile).Config | Set-Content -NoNewline $RepoFile
        "Captured config from $LiveFile"
        "Review with: git diff sumatra/"
    }
    'apply' {
        # A running Sumatra rewrites the live file on exit and would clobber
        # what we write. Only relevant when targeting the real live file.
        $isRealTarget = $LiveFile -eq "$env:LOCALAPPDATA\SumatraPDF\SumatraPDF-settings.txt"
        if ($isRealTarget -and (Get-Process SumatraPDF -ErrorAction SilentlyContinue)) {
            throw 'SumatraPDF is running - close it first, then re-run apply.'
        }
        $config = (Split-Settings $RepoFile).Config
        $state = if (Test-Path $LiveFile) { (Split-Settings $LiveFile).State } else { '' }
        New-Item -ItemType Directory -Force (Split-Path $LiveFile) | Out-Null
        ($config + $state) | Set-Content -NoNewline $LiveFile
        "Applied repo settings to $LiveFile (per-PC state preserved)"
    }
}
