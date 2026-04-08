Add-Type -AssemblyName System.Drawing

$out = "$PSScriptRoot\PromptPixel.ico"
$png = "$PSScriptRoot\PromptPixel.png"
$size = 256

$bmp = New-Object System.Drawing.Bitmap $size, $size
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode    = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.PixelOffsetMode  = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

# --- Rounded background with purple->cyan gradient ---
$rect = New-Object System.Drawing.Rectangle 0, 0, $size, $size
$radius = 48

$path = New-Object System.Drawing.Drawing2D.GraphicsPath
$d = $radius * 2
$path.AddArc($rect.X, $rect.Y, $d, $d, 180, 90)
$path.AddArc($rect.Right - $d, $rect.Y, $d, $d, 270, 90)
$path.AddArc($rect.Right - $d, $rect.Bottom - $d, $d, $d, 0, 90)
$path.AddArc($rect.X, $rect.Bottom - $d, $d, $d, 90, 90)
$path.CloseFigure()

$c1 = [System.Drawing.Color]::FromArgb(255, 30, 64, 175)    # deep blue
$c2 = [System.Drawing.Color]::FromArgb(255, 59, 130, 246)   # bright blue
$grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 135.0
$g.FillPath($grad, $path)

# --- Pixel grid (3x3) on the left ---
$pixSize = 28
$gap = 10
$gridX = 42
$gridY = 70
$white = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$whiteBrush = New-Object System.Drawing.SolidBrush $white
$dimBrush   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160, 255, 255, 255))

# Pattern: filled = bright, others = dim — looks like a stylized 'P'
$pattern = @(
    @(1,1,1),
    @(1,0,1),
    @(1,1,0)
)
for ($r = 0; $r -lt 3; $r++) {
    for ($c = 0; $c -lt 3; $c++) {
        $x = $gridX + $c * ($pixSize + $gap)
        $y = $gridY + $r * ($pixSize + $gap)
        $brush = if ($pattern[$r][$c] -eq 1) { $whiteBrush } else { $dimBrush }
        $g.FillRectangle($brush, $x, $y, $pixSize, $pixSize)
    }
}

# --- Chat bubble in bottom-right ---
$bubble = New-Object System.Drawing.Drawing2D.GraphicsPath
$bx = 142; $by = 142; $bw = 86; $bh = 70; $br = 18
$bubble.AddArc($bx, $by, $br*2, $br*2, 180, 90)
$bubble.AddArc($bx + $bw - $br*2, $by, $br*2, $br*2, 270, 90)
$bubble.AddArc($bx + $bw - $br*2, $by + $bh - $br*2, $br*2, $br*2, 0, 90)
# tail
$bubble.AddLine($bx + $bw - 24, $by + $bh, $bx + $bw - 8, $by + $bh + 18)
$bubble.AddLine($bx + $bw - 8, $by + $bh + 18, $bx + $bw - 44, $by + $bh)
$bubble.AddArc($bx, $by + $bh - $br*2, $br*2, $br*2, 90, 90)
$bubble.CloseFigure()
$g.FillPath($whiteBrush, $bubble)

# Three dots inside bubble
$dotBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 30, 64, 175))
$dotR = 7
$dotY = $by + 30
$offsets = @(18, 38, 58)
foreach ($off in $offsets) {
    $dx = [int]($bx + $off)
    $g.FillEllipse($dotBrush, $dx, [int]$dotY, $dotR*2, $dotR*2)
}

$g.Dispose()
$bmp.Save($png, [System.Drawing.Imaging.ImageFormat]::Png)

# --- Wrap PNG into ICO container ---
$pngBytes = [System.IO.File]::ReadAllBytes($png)
$ms = New-Object System.IO.MemoryStream
$bw2 = New-Object System.IO.BinaryWriter $ms
$bw2.Write([uint16]0)        # reserved
$bw2.Write([uint16]1)        # type = icon
$bw2.Write([uint16]1)        # count
$bw2.Write([byte]0)          # width 0 = 256
$bw2.Write([byte]0)          # height 0 = 256
$bw2.Write([byte]0)          # palette
$bw2.Write([byte]0)          # reserved
$bw2.Write([uint16]1)        # planes
$bw2.Write([uint16]32)       # bpp
$bw2.Write([uint32]$pngBytes.Length)
$bw2.Write([uint32]22)       # data offset
$bw2.Write($pngBytes)
[System.IO.File]::WriteAllBytes($out, $ms.ToArray())
$bw2.Dispose()
$ms.Dispose()
$bmp.Dispose()

Write-Host "Icon created: $out"
