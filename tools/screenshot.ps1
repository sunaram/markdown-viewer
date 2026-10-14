<#
 Captures a real mdv window to a PNG (Windows). Uses PrintWindow, so the window may be larger than the screen.
   .\tools\screenshot.ps1 -Md samples\01-math.md -Out docs\screenshots\math.png [-Theme dark] [-Width 1920] [-Height 1080] [-Zoom 1.1]
 Runs mdv with a throw-away APPDATA so your own settings (theme, recent files) are untouched.
#>
param(
    [Parameter(Mandatory)][string]$Md,
    [Parameter(Mandatory)][string]$Out,
    [ValidateSet('', 'light', 'dark')][string]$Theme = '',
    [int]$Width = 1920,
    [int]$Height = 1080,
    [double]$Zoom = 1.0,
    [int]$WaitSeconds = 7,
    [string]$Exe = "$PSScriptRoot\..\target\release\mdv.exe"
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type @'
using System; using System.Runtime.InteropServices;
public class Win {
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int hh, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
'@
[void][Win]::SetProcessDPIAware()

$tmp = Join-Path $env:TEMP ("mdv-shot-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force "$tmp\mdv" | Out-Null
Set-Content "$tmp\mdv\settings.txt" "theme=$Theme`nzoom=$Zoom`n"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = (Resolve-Path $Exe).Path
$psi.Arguments = '"' + (Resolve-Path $Md).Path + '"'
$psi.UseShellExecute = $false
$psi.EnvironmentVariables['APPDATA'] = $tmp
$p = [System.Diagnostics.Process]::Start($psi)
try {
    for ($i = 0; $i -lt 50 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 200; $p.Refresh() }
    $h = $p.MainWindowHandle
    if ($h -eq 0) { throw 'mdv window did not appear' }
    [void][Win]::SetWindowPos($h, [IntPtr]::Zero, 0, 0, $Width, $Height, 0x0044)   # SWP_NOZORDER | SWP_SHOWWINDOW
    Start-Sleep -Seconds $WaitSeconds                                                # let mermaid finish
    $r = New-Object Win+RECT
    [void][Win]::GetWindowRect($h, [ref]$r)
    $w = $r.R - $r.L; $ht = $r.B - $r.T
    $bmp = New-Object System.Drawing.Bitmap $w, $ht
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $hdc = $g.GetHdc()
    $ok = [Win]::PrintWindow($h, $hdc, 2)                                            # PW_RENDERFULLCONTENT
    $g.ReleaseHdc($hdc); $g.Dispose()
    New-Item -ItemType Directory -Force (Split-Path -Parent $Out) | Out-Null
    $bmp.Save((Join-Path (Resolve-Path (Split-Path -Parent $Out)) (Split-Path -Leaf $Out)), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    "captured ${w}x${ht} printwindow=$ok -> $Out"
} finally {
    if (-not $p.HasExited) { $p.Kill() }
    $p.WaitForExit()
    Start-Sleep -Milliseconds 500
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
