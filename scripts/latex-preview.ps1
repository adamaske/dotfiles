#!/usr/bin/env pwsh
# Live in-terminal LaTeX preview.
# Watches a PDF and, whenever it changes, rasterizes every page with poppler's
# pdftoppm, then paints them inline with chafa. Rendering runs in a herdr pane
# beside Neovim while `latexmk -pvc` rebuilds the PDF on save.
#
# Format notes:
#   -Format kitty    crisp images. Requires herdr `[experimental] kitty_graphics
#                    = true` AND a server restart so the parser initializes at
#                    boot (a live config reload is not enough). WezTerm is the
#                    kitty-compatible outer terminal.
#   -Format symbols  colored Unicode block art. Works in any pane with no
#                    graphics protocol; use as a fallback if kitty won't render.
#
# We force chafa's format and size explicitly so it never probes the terminal
# (probing panics/hangs inside a multiplexer pane).
#
# Usage: latex-preview.ps1 <path-to-pdf> [-Dpi 150] [-Format kitty|symbols|sixel|iterm]
param(
    [Parameter(Mandatory = $true)] [string]$Pdf,
    [int]$Dpi = 150,
    [string]$Format = "kitty"
)

$ErrorActionPreference = "SilentlyContinue"
$Pdf = [System.IO.Path]::GetFullPath($Pdf)
$work = Join-Path $env:TEMP ("latexpreview_" + [System.IO.Path]::GetFileNameWithoutExtension($Pdf))
New-Item -ItemType Directory -Force -Path $work | Out-Null

function Show-Image([string]$path) {
    $cols = [Console]::WindowWidth
    if ($cols -lt 1) { $cols = 80 }
    # Width in cells; height auto (aspect preserved). Truecolor for legibility;
    # --animate off so multi-page PDFs aren't treated as an animation.
    & chafa -f $Format -c full --size "$cols" --animate off "$path"
}

function Render {
    Clear-Host
    Get-ChildItem "$work\page-*.png" | Remove-Item -Force
    & pdftoppm -png -r $Dpi "$Pdf" "$work\page" 2>$null
    $pages = Get-ChildItem "$work\page-*.png" | Sort-Object Name
    if (-not $pages) { Write-Host "waiting for a valid PDF..."; return }
    foreach ($p in $pages) { Show-Image $p.FullName; Write-Host "" }
    Write-Host ("-- {0} page(s) @ {1} dpi [{2}] | scroll for more | Ctrl-C to quit --" -f $pages.Count, $Dpi, $Format)
}

Write-Host "Live preview of $Pdf"
Write-Host "Waiting for first build..."
$last = [datetime]::MinValue
while ($true) {
    if (Test-Path $Pdf) {
        $mtime = (Get-Item $Pdf).LastWriteTime
        if ($mtime -ne $last) {
            Start-Sleep -Milliseconds 250   # let the PDF finish being written
            Render
            $last = (Get-Item $Pdf).LastWriteTime
        }
    }
    Start-Sleep -Milliseconds 400
}
