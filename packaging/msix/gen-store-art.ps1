# Generates the Microsoft Store display images into docs\store\ (same design language as the app icon):
#   box-art-1080x1080.png     1:1  box art (also used as the main logo when no poster art is given)
#   box-art-300x300.png       1:1  small version (Store logo / title-card minimum size)
#   poster-720x1080.png       9:16 poster art (main logo on Windows 10/11, required for Xbox display)
#   hero-1920x1080.png        16:9 super hero art (optional promo image)
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot '..\..\docs\store'
New-Item -ItemType Directory -Force $out | Out-Null
$out = (Resolve-Path $out).Path

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.InterpolationMode = 'HighQualityBicubic'
    $rect = New-Object System.Drawing.Rectangle 0, 0, $w, $h
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, ([System.Drawing.Color]::FromArgb(255, 37, 99, 235)), ([System.Drawing.Color]::FromArgb(255, 124, 58, 237)), 45.0
    $g.FillRectangle($grad, $rect)
    # soft highlight in the corner for depth
    $glow = New-Object System.Drawing.Drawing2D.GraphicsPath
    $glow.AddEllipse([int](-0.3 * $w), [int](-0.4 * $h), [int](0.9 * $w), [int](0.9 * $w))
    $pg = New-Object System.Drawing.Drawing2D.PathGradientBrush $glow
    $pg.CenterColor = [System.Drawing.Color]::FromArgb(60, 255, 255, 255)
    $pg.SurroundColors = [System.Drawing.Color[]]@([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
    $g.FillPath($pg, $glow)
    [pscustomobject]@{ Bmp = $bmp; G = $g }
}

# The page-with-"M↓" glyph from the icon (design grid 128x128, centre of the page at 65,64), drawn at scale $s centred on ($cx,$cy)
function Draw-Glyph($g, [double]$cx, [double]$cy, [double]$s) {
    $st = $g.Save()
    $g.TranslateTransform([single]$cx, [single]$cy)
    $g.ScaleTransform([single]$s, [single]$s)
    $g.TranslateTransform(-65, -64)
    # drop shadow
    $shadow = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(50, 0, 0, 40))
    $g.FillPolygon($shadow, [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF 38, 25), (New-Object System.Drawing.PointF 78, 25), (New-Object System.Drawing.PointF 100, 47),
        (New-Object System.Drawing.PointF 100, 113), (New-Object System.Drawing.PointF 38, 113)))
    $page = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF 34, 20), (New-Object System.Drawing.PointF 74, 20), (New-Object System.Drawing.PointF 96, 42),
        (New-Object System.Drawing.PointF 96, 108), (New-Object System.Drawing.PointF 34, 108))
    $g.FillPolygon([System.Drawing.Brushes]::White, $page)
    $g.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 199, 210, 254))),
        [System.Drawing.PointF[]]@((New-Object System.Drawing.PointF 74, 20), (New-Object System.Drawing.PointF 74, 42), (New-Object System.Drawing.PointF 96, 42)))
    $font = New-Object System.Drawing.Font('Segoe UI', 40.0, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'; $sf.FormatFlags = 'NoWrap'
    $g.DrawString('M' + [char]0x2193, $font, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 37, 99, 235))),
        (New-Object System.Drawing.RectangleF 14, 52, 100, 54), $sf)
    $g.Restore($st)
}

function Draw-Text($g, [string]$text, [double]$cx, [double]$y, [double]$size, [bool]$bold, [int]$alpha, [string]$align = 'Center') {
    $style = if ($bold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
    $font = New-Object System.Drawing.Font('Segoe UI', [single]$size, $style, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = $align; $sf.FormatFlags = 'NoWrap'
    $g.DrawString($text, $font, (New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($alpha, 255, 255, 255))), [single]$cx, [single]$y, $sf)
}

function Save($c, $name) {
    $c.G.Dispose()
    $c.Bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $c.Bmp.Dispose()
}

# 1:1 box art
$c = New-Canvas 1080 1080
Draw-Glyph $c.G 540 540 6.6
Save $c 'box-art-1080x1080.png'

# 1:1 small
$c = New-Canvas 300 300
Draw-Glyph $c.G 150 150 1.85
Save $c 'box-art-300x300.png'

# 9:16 poster
$c = New-Canvas 720 1080
Draw-Glyph $c.G 360 390 4.4
Draw-Text $c.G 'My Markdown' 360 720 78 $true 255
Draw-Text $c.G 'Viewer' 360 810 78 $true 255
Draw-Text $c.G "LaTeX math  $([char]0x00B7)  Mermaid diagrams" 360 930 33 $false 230
Draw-Text $c.G "HTML  $([char]0x00B7)  SVG  $([char]0x00B7)  MathML" 360 978 33 $false 230
Save $c 'poster-720x1080.png'

# 16:9 hero
$c = New-Canvas 1920 1080
Draw-Glyph $c.G 400 540 6.6
Draw-Text $c.G 'My Markdown Viewer' 780 410 92 $true 255 'Near'
Draw-Text $c.G 'Markdown with real math and real diagrams.' 784 540 46 $false 235 'Near'
Draw-Text $c.G "LaTeX equations  $([char]0x00B7)  Mermaid diagrams  $([char]0x00B7)  HTML, SVG, MathML" 784 620 34 $false 215 'Near'
Draw-Text $c.G 'Tiny. Fast. Private.' 784 700 38 $true 255 'Near'
Save $c 'hero-1920x1080.png'

Get-ChildItem $out | Select-Object Name, Length
