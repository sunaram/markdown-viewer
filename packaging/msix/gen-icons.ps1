# Generates PLACEHOLDER tile/logo PNGs into .\Assets. Replace with real artwork before a Store release.
Add-Type -AssemblyName System.Drawing
$out = Join-Path $PSScriptRoot 'Assets'
New-Item -ItemType Directory -Force $out | Out-Null

function New-Icon($name, $w, $h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::FromArgb(0, 0, 0, 0))
    $side = [Math]::Min($w, $h)
    $pad = [int]($side * 0.08)
    $r = [int]($side * 0.2)
    $x = [int](($w - $side) / 2) + $pad; $y = [int](($h - $side) / 2) + $pad; $s = $side - 2 * $pad
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, 2 * $r, 2 * $r, 180, 90)
    $path.AddArc($x + $s - 2 * $r, $y, 2 * $r, 2 * $r, 270, 90)
    $path.AddArc($x + $s - 2 * $r, $y + $s - 2 * $r, 2 * $r, 2 * $r, 0, 90)
    $path.AddArc($x, $y + $s - 2 * $r, 2 * $r, 2 * $r, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 9, 105, 218))), $path)
    $font = New-Object System.Drawing.Font('Segoe UI', [single]($s * 0.42), [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $g.DrawString('M' + [char]0x2193, $font, [System.Drawing.Brushes]::White, (New-Object System.Drawing.RectangleF ($w / 2 - $s / 2), ($h / 2 - $s / 2), $s, $s), $sf)
    $g.Dispose()
    $bmp.Save((Join-Path $out "$name.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

New-Icon 'StoreLogo' 50 50
New-Icon 'Square44x44Logo' 44 44
New-Icon 'Square71x71Logo' 71 71
New-Icon 'Square150x150Logo' 150 150
New-Icon 'Wide310x150Logo' 310 150
New-Icon 'Square310x310Logo' 310 310
# unplated variants used by the taskbar / Start so the icon is not shown on a coloured plate
foreach ($t in 16, 24, 32, 48, 256) {
    New-Icon "Square44x44Logo.targetsize-${t}" $t $t
    New-Icon "Square44x44Logo.targetsize-${t}_altform-unplated" $t $t
}
Get-ChildItem $out | Select-Object Name, Length
