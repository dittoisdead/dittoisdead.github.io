# Rebuilds the gif grid + lightbox overlays in gifs.html
# from every .gif inside the images\gifs folder (subfolders included).
# It only rewrites the regions between the AUTO-GRID and AUTO-LIGHTBOX
# markers in gifs.html; the rest of the page is left untouched.

$ErrorActionPreference = 'Stop'

# --- Paths (relative to this script's folder = your site root) ---
$root     = $PSScriptRoot
$htmlPath = Join-Path $root 'gifs.html'
$gifDir   = Join-Path $root 'images\gifs'   # <-- change to 'images' if you don't want a gifs subfolder

if (-not (Test-Path $htmlPath)) { Write-Host "Couldn't find gifs.html next to this script."; return }
if (-not (Test-Path $gifDir))   { Write-Host "Couldn't find the folder: $gifDir"; return }

# --- Find gifs, sorted naturally (so 2 comes before 10) ---
$gifs = Get-ChildItem -Path $gifDir -Recurse -File -Filter *.gif |
        Sort-Object { [regex]::Replace($_.FullName, '\d+', { param($m) $m.Value.PadLeft(10,'0') }) }

if ($gifs.Count -eq 0) {
    Write-Host "No .gif files found in $gifDir - leaving gifs.html unchanged."
    return
}

# --- Build the markup ---
$gridLines = @()
$lbLines   = @()
$i = 0
foreach ($g in $gifs) {
    $i++
    $rel = $g.FullName.Substring($root.Length).TrimStart('\','/') -replace '\\','/'
    $gridLines += '      <figure><a href="#gif{0}"><img src="{1}" alt="" loading="lazy"></a></figure>' -f $i, $rel
    $lbLines   += '  <a class="lightbox" id="gif{0}" href="#"><span class="close">&times;</span><img src="{1}" alt="" loading="lazy"></a>' -f $i, $rel
}

$gridBlock = "<!-- AUTO-GRID:START  (everything between these markers is rewritten by update-gifs.bat) -->`r`n" +
             ($gridLines -join "`r`n") + "`r`n      <!-- AUTO-GRID:END -->"

$lbBlock   = "<!-- AUTO-LIGHTBOX:START  (rewritten by update-gifs.bat) -->`r`n" +
             ($lbLines -join "`r`n") + "`r`n  <!-- AUTO-LIGHTBOX:END -->"

# --- Swap the regions in place ---
$html = Get-Content $htmlPath -Raw
$html = [regex]::Replace($html, '(?s)<!-- AUTO-GRID:START.*?<!-- AUTO-GRID:END -->',         { $gridBlock })
$html = [regex]::Replace($html, '(?s)<!-- AUTO-LIGHTBOX:START.*?<!-- AUTO-LIGHTBOX:END -->', { $lbBlock })

[System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Done - gifs.html now lists $i gif(s) from $gifDir."
