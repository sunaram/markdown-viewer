# Renders the app icon (blue-violet gradient tile, white page with folded corner, "M↓") to
#   packaging\msix\Assets\*.png   (MSIX tiles/logos)
#   assets\mdv.ico                (embedded in mdv.exe by build.rs)
# The same design is packaging\linux\mdv.svg (used for Linux and, via rsvg, the macOS .icns).
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot 'Assets'
$ico = Join-Path $PSScriptRoot '..\..\assets\mdv.ico'
New-Item -ItemType Directory -Force $out | Out-Null

function New-IconBitmap([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $side = [Math]::Min($w, $h)
    $ox = ($w - $side) / 2.0; $oy = ($h - $side) / 2.0
    $u = $side / 128.0                       # design grid is 128 x 128
    $P = { param($x, $y) New-Object System.Drawing.PointF ([single]($ox + $x * $u)), ([single]($oy + $y * $u)) }

    # tile
    $r = 27 * $u; $x = $ox + 4 * $u; $y = $oy + 4 * $u; $s = 120 * $u
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, 2 * $r, 2 * $r, 180, 90)
    $path.AddArc($x + $s - 2 * $r, $y, 2 * $r, 2 * $r, 270, 90)
    $path.AddArc($x + $s - 2 * $r, $y + $s - 2 * $r, 2 * $r, 2 * $r, 0, 90)
    $path.AddArc($x, $y + $s - 2 * $r, 2 * $r, 2 * $r, 90, 90)
    $path.CloseFigure()
    $grad = New-Object System.Drawing.Drawing2D.LinearGradientBrush (& $P 4 4), (& $P 124 124), ([System.Drawing.Color]::FromArgb(255, 37, 99, 235)), ([System.Drawing.Color]::FromArgb(255, 124, 58, 237))
    $g.FillPath($grad, $path)

    $font = $null
    if ($side -ge 40) {
        # page with folded corner
        $page = [System.Drawing.PointF[]]@((& $P 34 20), (& $P 74 20), (& $P 96 42), (& $P 96 108), (& $P 34 108))
        $g.FillPolygon([System.Drawing.Brushes]::White, $page)
        $fold = [System.Drawing.PointF[]]@((& $P 74 20), (& $P 74 42), (& $P 96 42))
        $g.FillPolygon((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 199, 210, 254))), $fold)
        $font = New-Object System.Drawing.Font('Segoe UI', [single](40 * $u), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 37, 99, 235))
        $rect = New-Object System.Drawing.RectangleF ([single]($ox + 14 * $u)), ([single]($oy + 52 * $u)), ([single](100 * $u)), ([single](54 * $u))
    } else {
        # too small for a page: just a big white "M"
        $font = New-Object System.Drawing.Font('Segoe UI', [single](84 * $u), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
        $brush = [System.Drawing.Brushes]::White
        $rect = New-Object System.Drawing.RectangleF ([single]($ox)), ([single]($oy + 4 * $u)), ([single]$side), ([single](120 * $u))
    }
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = "Center"; $sf.LineAlignment = "Center"; $sf.FormatFlags = "NoWrap"
    $txt = if ($side -ge 40) { 'M' + [char]0x2193 } else { 'M' }
    $g.DrawString($txt, $font, $brush, $rect, $sf)
    $g.Dispose()
    $bmp
}

function Save-Png($name, $w, $h) {
    $b = New-IconBitmap $w $h
    $b.Save((Join-Path $out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
}

Save-Png 'StoreLogo' 50 50
Save-Png 'Square44x44Logo' 44 44
Save-Png 'Square71x71Logo' 71 71
Save-Png 'Square150x150Logo' 150 150
Save-Png 'Wide310x150Logo' 310 150
Save-Png 'Square310x310Logo' 310 310
# unplated variants: shown on the taskbar/Start without a coloured plate behind them
foreach ($t in 16, 24, 32, 48, 256) {
    Save-Png "Square44x44Logo.targetsize-${t}" $t $t
    Save-Png "Square44x44Logo.targetsize-${t}_altform-unplated" $t $t
}

# multi-size .ico with PNG-compressed entries
$sizes = 16, 24, 32, 48, 64, 128, 256
$pngs = foreach ($sz in $sizes) {
    $b = New-IconBitmap $sz $sz
    $ms = New-Object System.IO.MemoryStream
    $b.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
    , $ms.ToArray()
}
$fs = [System.IO.File]::Create($ico)
$bw = New-Object System.IO.BinaryWriter $fs
$bw.Write([uint16]0); $bw.Write([uint16]1); $bw.Write([uint16]$sizes.Count)
$offset = 6 + 16 * $sizes.Count
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz = $sizes[$i]; $wh = if ($sz -ge 256) { 0 } else { $sz }
    $bw.Write([byte]$wh); $bw.Write([byte]$wh); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([uint16]1); $bw.Write([uint16]32)
    $bw.Write([uint32]$pngs[$i].Length); $bw.Write([uint32]$offset)
    $offset += $pngs[$i].Length
}
foreach ($p in $pngs) { $bw.Write($p) }
$bw.Close(); $fs.Close()
Get-ChildItem $out, $ico | Select-Object Name, Length | Format-Table -AutoSize | Out-String -Width 100
