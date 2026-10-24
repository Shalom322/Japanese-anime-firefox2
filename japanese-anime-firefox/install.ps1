<#
 japanese-anime-firefox installer (Windows, PowerShell 5.1+).
   install.bat               install / update
   install.bat -Uninstall    remove the theme
   install.bat -ProfilePath "C:\path\to\profile"   use a specific profile
 Nothing outside the chosen Firefox profile folder is modified.
#>
param(
    [switch]$Uninstall,
    [string]$ProfilePath
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$MarkerStart = '// >>> japanese-anime-firefox >>>'
$MarkerEnd   = '// <<< japanese-anime-firefox <<<'
$OurFiles    = @('userChrome.css', 'userContent.css')
$OurImages   = @('wallpaper.jpg', 'wallpaper-panel.jpg', 'sakura-left.svg', 'sakura-right.svg', 'petals.svg')

function Get-DefaultProfile {
    $base = Join-Path $env:APPDATA 'Mozilla\Firefox'
    $ini  = Join-Path $base 'profiles.ini'
    if (-not (Test-Path -LiteralPath $ini)) {
        throw "profiles.ini not found at $ini. Start Firefox once, close it and run the installer again."
    }
    $sections = @{}
    $current = $null
    foreach ($line in (Get-Content -LiteralPath $ini)) {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') {
            $current = $Matches[1]
            $sections[$current] = @{}
            continue
        }
        if ($current -and $t -match '^([^=;#]+)=(.*)$') {
            $sections[$current][$Matches[1].Trim()] = $Matches[2].Trim()
        }
    }
    # 1) The profile used by the installed Firefox: [InstallXXXX] Default=
    foreach ($name in $sections.Keys) {
        if ($name -like 'Install*' -and $sections[$name].ContainsKey('Default')) {
            $p = $sections[$name]['Default'] -replace '/', '\'
            if ([System.IO.Path]::IsPathRooted($p)) { return $p }
            return (Join-Path $base $p)
        }
    }
    # 2) Fallback: [ProfileN] with Default=1
    foreach ($name in $sections.Keys) {
        if ($name -like 'Profile*' -and $sections[$name]['Default'] -eq '1') {
            $p = $sections[$name]['Path'] -replace '/', '\'
            if ($sections[$name]['IsRelative'] -eq '1') { return (Join-Path $base $p) }
            return $p
        }
    }
    throw 'Could not detect the default profile. Re-run with -ProfilePath "C:\path\to\profile" (see about:support).'
}

function Remove-ThemeBlock([string]$text) {
    $pattern = '(?s)\r?\n?' + [regex]::Escape($MarkerStart) + '.*?' + [regex]::Escape($MarkerEnd) + '\r?\n?'
    return [regex]::Replace($text, $pattern, '')
}

function Write-Utf8([string]$path, [string]$text) {
    [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

function Test-IsOurFile([string]$path) {
    return ((Get-Content -LiteralPath $path -Raw) -match 'japanese-anime-firefox')
}

if ($ProfilePath) { $profile = $ProfilePath } else { $profile = Get-DefaultProfile }
if (-not (Test-Path -LiteralPath $profile)) { throw "Profile folder does not exist: $profile" }

Write-Host "Firefox profile: $profile"
if (Get-Process -Name firefox -ErrorAction SilentlyContinue) {
    Write-Host 'NOTE: Firefox is running. Files will be copied, but you must restart Firefox afterwards.' -ForegroundColor Yellow
}

$chromeDir = Join-Path $profile 'chrome'
$imagesDir = Join-Path $chromeDir 'images'
$userJs    = Join-Path $profile 'user.js'

if ($Uninstall) {
    foreach ($f in $OurFiles) {
        $p = Join-Path $chromeDir $f
        if ((Test-Path -LiteralPath $p) -and (Test-IsOurFile $p)) { Remove-Item -LiteralPath $p -Force; Write-Host "Removed $f" }
    }
    foreach ($f in $OurImages) {
        $p = Join-Path $imagesDir $f
        if (Test-Path -LiteralPath $p) { Remove-Item -LiteralPath $p -Force }
    }
    if ((Test-Path -LiteralPath $imagesDir) -and -not (Get-ChildItem -LiteralPath $imagesDir -Force)) {
        Remove-Item -LiteralPath $imagesDir -Force
    }
    if (Test-Path -LiteralPath $userJs) {
        $clean = Remove-ThemeBlock (Get-Content -LiteralPath $userJs -Raw)
        if ($clean.Trim().Length -eq 0) { Remove-Item -LiteralPath $userJs -Force } else { Write-Utf8 $userJs $clean }
        Write-Host 'Removed theme block from user.js'
    }
    Write-Host 'Done. Restart Firefox. Backups (*.bak-*) were left in place.'
    Write-Host 'Prefs already saved by Firefox (sidebar.*, toolkit.legacyUserProfileCustomizations.stylesheets) can be reset in about:config.'
    return
}

# Install ---------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $imagesDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

foreach ($f in $OurFiles) {
    $dst = Join-Path $chromeDir $f
    if ((Test-Path -LiteralPath $dst) -and -not (Test-IsOurFile $dst)) {
        Copy-Item -LiteralPath $dst -Destination "$dst.bak-$stamp"
        Write-Host "Backed up existing $f -> $f.bak-$stamp"
    }
    Copy-Item -LiteralPath (Join-Path $ProjectRoot "chrome\$f") -Destination $dst -Force
}
# Wallpapers are not shipped with the repo (see README, "Wallpapers").
$wp      = Join-Path $ProjectRoot 'chrome\images\wallpaper.jpg'
$wpPanel = Join-Path $ProjectRoot 'chrome\images\wallpaper-panel.jpg'
if (-not (Test-Path -LiteralPath $wp)) {
    Write-Host 'NOTE: chrome\images\wallpaper.jpg not found. The theme will work, but with a plain dark background. Add your picture and run the installer again.' -ForegroundColor Yellow
} elseif (-not (Test-Path -LiteralPath $wpPanel)) {
    try {
        & (Join-Path $ProjectRoot 'make-panel-wallpaper.ps1')
    } catch {
        Write-Host "NOTE: could not create wallpaper-panel.jpg automatically: $_" -ForegroundColor Yellow
    }
}
Copy-Item -Path (Join-Path $ProjectRoot 'chrome\images\*') -Destination $imagesDir -Force

$prefs = Get-Content -LiteralPath (Join-Path $ProjectRoot 'user.js') -Raw
$existing = ''
if (Test-Path -LiteralPath $userJs) {
    $existing = Get-Content -LiteralPath $userJs -Raw
    if ($existing -notmatch [regex]::Escape($MarkerStart)) {
        Copy-Item -LiteralPath $userJs -Destination "$userJs.bak-$stamp"
        Write-Host "Backed up existing user.js -> user.js.bak-$stamp"
    }
    $existing = Remove-ThemeBlock $existing
}
$block = $MarkerStart + "`r`n" + $prefs.TrimEnd() + "`r`n" + $MarkerEnd + "`r`n"
if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { $existing += "`r`n" }
Write-Utf8 $userJs ($existing + $block)

Write-Host ''
Write-Host 'Installed. Fully close Firefox (all windows) and start it again.' -ForegroundColor Green
