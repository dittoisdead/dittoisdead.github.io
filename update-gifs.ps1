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
# --- Ordering: pick ONE block below (the others stay commented out) ---

# Newest first, by when the file was last saved/exported (default):
$gifs = Get-ChildItem -Path $gifDir -Recurse -File -Filter *.gif | Sort-Object LastWriteTime -Descending

# Newest first, by the file's creation date on disk:
# $gifs = Get-ChildItem -Path $gifDir -Recurse -File -Filter *.gif | Sort-Object CreationTime -Descending

# By filename, natural order so 2 comes before 10 (the old behaviour):
# $gifs = Get-ChildItem -Path $gifDir -Recurse -File -Filter *.gif |
#         Sort-Object { [regex]::Replace($_.FullName, '\d+', { param($m) $m.Value.PadLeft(10,'0') }) }

if ($gifs.Count -eq 0) {
    Write-Host "No .gif files found in $gifDir - leaving gifs.html unchanged."
    return
}

# --- Read current page + remember any captions already typed (keyed by gif path) ---
$html = Get-Content $htmlPath -Raw
$captions = @{}
foreach ($m in [regex]::Matches($html, '(?s)<img[^>]*src="([^"]+)"[^>]*>\s*<figcaption>(.*?)</figcaption>')) {
    $captions[$m.Groups[1].Value] = $m.Groups[2].Value
}

# --- Build the markup ---
$n = $gifs.Count
$gridLines = @()
$lbLines   = @()
$lbLines   += '  <input class="lb-toggle" type="radio" name="lb" id="r-none" checked aria-hidden="true">'
$i = 0
foreach ($g in $gifs) {
    $i++
    $rel = $g.FullName.Substring($root.Length).TrimStart('\','/') -replace '\\','/'
    $cap = ''
    if ($captions.ContainsKey($rel)) { $cap = $captions[$rel] }
    $prev = if ($i -eq 1)  { $n } else { $i - 1 }
    $next = if ($i -eq $n) { 1 } else { $i + 1 }
    $gridLines += '      <figure><label for="r-gif{0}"><img src="{1}" alt="" loading="lazy"></label></figure>' -f $i, $rel
    $lbLines   += '  <input class="lb-toggle" type="radio" name="lb" id="r-gif' + $i + '" aria-hidden="true">'
    $lbLines   += '  <div class="lightbox"><label class="backdrop" for="r-none" aria-label="close"></label><label class="close" for="r-none">&times;</label><label class="lb-prev" for="r-gif' + $prev + '" aria-label="previous">&lsaquo;</label><label class="lb-next" for="r-gif' + $next + '" aria-label="next">&rsaquo;</label><figure class="shot"><img src="' + $rel + '" alt="" loading="lazy"><figcaption>' + $cap + '</figcaption></figure></div>'
}

$gridBlock = "<!-- AUTO-GRID:START  (everything between these markers is rewritten by update-gifs.bat) -->`r`n" +
             ($gridLines -join "`r`n") + "`r`n      <!-- AUTO-GRID:END -->"

$lbBlock   = "<!-- AUTO-LIGHTBOX:START  (rewritten by update-gifs.bat; your figcaption text is kept) -->`r`n" +
             ($lbLines -join "`r`n") + "`r`n  <!-- AUTO-LIGHTBOX:END -->"

# --- Swap the regions in place ---
$html = [regex]::Replace($html, '(?s)<!-- AUTO-GRID:START.*?<!-- AUTO-GRID:END -->',         { $gridBlock })
$html = [regex]::Replace($html, '(?s)<!-- AUTO-LIGHTBOX:START.*?<!-- AUTO-LIGHTBOX:END -->', { $lbBlock })

[System.IO.File]::WriteAllText($htmlPath, $html, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Done - gifs.html now lists $i gif(s) from $gifDir."
