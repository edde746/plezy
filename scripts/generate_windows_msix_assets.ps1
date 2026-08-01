#!/usr/bin/env pwsh
# Windows MSIX Asset Generator
# Renders the tile, store and splash PNGs the Store manifest references from
# assets/plezy.png, for windows/msix/assets. The results are committed and
# windows/build-msix.ps1 only copies them, so packaging stays runnable without
# image tooling; regenerating is only needed when the app icon changes.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent $ScriptDir
Set-Location $ProjectRoot

Add-Type -AssemblyName System.Drawing

$Source = Resolve-Path "assets\plezy.png"
$OutputDir = Join-Path $ProjectRoot "windows\msix\assets"

# Sizes and names come from the uap:VisualElements attributes in the manifest
# template; a rename here has to be made there too. The two non-square targets
# letterbox the square icon on transparent padding rather than stretching it.
$Targets = @(
    @{ Name = "Square44x44Logo.png";   Width =  44; Height =  44 }
    @{ Name = "Square150x150Logo.png"; Width = 150; Height = 150 }
    @{ Name = "StoreLogo.png";         Width =  50; Height =  50 }
    @{ Name = "Wide310x150Logo.png";   Width = 310; Height = 150 }
    @{ Name = "Square310x310Logo.png"; Width = 310; Height = 310 }
    @{ Name = "SplashScreen.png";      Width = 620; Height = 300 }
    # The base logos are scale-100. Without a 200 the shell upscales them on the
    # high-DPI displays most laptops ship with.
    @{ Name = "Square44x44Logo.scale-200.png";   Width =  88; Height =  88 }
    @{ Name = "Square150x150Logo.scale-200.png"; Width = 300; Height = 300 }
)

# The taskbar, task view and Alt-Tab draw the small logo on a plate filled with
# BackgroundColor, and a transparent background leaves the shell painting the
# user's accent colour behind the icon. An altform-unplated variant is the only
# way to suppress that plate; lightunplated is its light-theme counterpart.
# These resolve through resources.pri, which windows/build-msix.ps1 builds - as
# plain payload files they are inert.
foreach ($Size in 16, 24, 32, 48, 256) {
    foreach ($Form in "", "_altform-unplated", "_altform-lightunplated") {
        $Targets += @{ Name = "Square44x44Logo.targetsize-${Size}${Form}.png"; Width = $Size; Height = $Size }
    }
}

# Regenerate from scratch so a renamed target cannot leave an orphan behind.
if (Test-Path $OutputDir) { Remove-Item (Join-Path $OutputDir "*.png") -Force }
New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Write-Host "Generating MSIX assets from $Source..." -ForegroundColor Cyan

$SourceImage = [System.Drawing.Image]::FromFile($Source)
try {
    foreach ($Target in $Targets) {
        $Canvas = New-Object System.Drawing.Bitmap(
            $Target.Width, $Target.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $Graphics = [System.Drawing.Graphics]::FromImage($Canvas)
            try {
                # SourceCopy keeps the icon's own alpha instead of blending it
                # into the canvas; the manifest declares a transparent tile
                # background and expects the padding to stay transparent.
                $Graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
                $Graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $Graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

                $Edge = [Math]::Min($Target.Width, $Target.Height)
                $Left = [int](($Target.Width - $Edge) / 2)
                $Top = [int](($Target.Height - $Edge) / 2)
                $Graphics.DrawImage(
                    $SourceImage, (New-Object System.Drawing.Rectangle($Left, $Top, $Edge, $Edge)))
            } finally {
                $Graphics.Dispose()
            }

            $Path = Join-Path $OutputDir $Target.Name
            $Canvas.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
            Write-Host "  $($Target.Name) ($($Target.Width)x$($Target.Height))" -ForegroundColor Green
        } finally {
            $Canvas.Dispose()
        }
    }
} finally {
    $SourceImage.Dispose()
}

Write-Host "`nWrote $($Targets.Count) asset(s) to $OutputDir" -ForegroundColor White
