#!/usr/bin/env pwsh
# Generate committed MSIX assets from assets/plezy.png.

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Split-Path -Parent (Split-Path -Parent $ScriptDir)
Set-Location $ProjectRoot

Add-Type -AssemblyName System.Drawing

$Source = Resolve-Path "assets\plezy.png"
$OutputDir = Join-Path $ProjectRoot "windows\msix\assets"

# Names and dimensions mirror the manifest's VisualElements.
$Targets = @(
    @{ Name = "Square44x44Logo.png";   Width =  44; Height =  44 }
    @{ Name = "Square150x150Logo.png"; Width = 150; Height = 150 }
    @{ Name = "StoreLogo.png";         Width =  50; Height =  50 }
    @{ Name = "Wide310x150Logo.png";   Width = 310; Height = 150 }
    @{ Name = "Square310x310Logo.png"; Width = 310; Height = 310 }
    @{ Name = "SplashScreen.png";      Width = 620; Height = 300 }
    # Scale-200 variants avoid shell upscaling on high-DPI displays.
    @{ Name = "Square44x44Logo.scale-200.png";   Width =  88; Height =  88 }
    @{ Name = "Square150x150Logo.scale-200.png"; Width = 300; Height = 300 }
)

# Resources.pri resolves these unplated variants; plain payload files are inert.
foreach ($Size in 16, 24, 32, 48, 256) {
    foreach ($Form in "", "_altform-unplated", "_altform-lightunplated") {
        $Targets += @{ Name = "Square44x44Logo.targetsize-${Size}${Form}.png"; Width = $Size; Height = $Size }
    }
}

# Remove stale outputs when targets are renamed.
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
                # Preserve alpha for the manifest's transparent tile background.
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
