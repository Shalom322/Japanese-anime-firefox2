<#
 japanese-anime-firefox: make-panel-wallpaper.ps1
 Creates chrome\images\wallpaper-panel.jpg (darkened, tinted copy used by the
 left panel) from chrome\images\wallpaper.jpg. Windows PowerShell 5.1+.
 Run:  powershell -ExecutionPolicy Bypass -File make-panel-wallpaper.ps1
 install.bat runs this automatically when wallpaper-panel.jpg is missing.
#>
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$src  = Join-Path $root 'chrome\images\wallpaper.jpg'
$dst  = Join-Path $root 'chrome\images\wallpaper-panel.jpg'

if (-not (Test-Path -LiteralPath $src)) {
    throw "Not found: $src . Put your picture there first (see README, section 'Wallpapers')."
}

Add-Type -AssemblyName System.Drawing
$img = [System.Drawing.Image]::FromFile($src)
try {
    $bmp = New-Object System.Drawing.Bitmap($img.Width, $img.Height)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.DrawImage($img, 0, 0, $img.Width, $img.Height)
        # dark violet veil, ~60% opacity
        $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(153, 11, 10, 26))
        $g.FillRectangle($brush, 0, 0, $img.Width, $img.Height)
        $brush.Dispose()
    } finally { $g.Dispose() }
    $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $bmp.Dispose()
} finally { $img.Dispose() }

Write-Host "Created $dst"
