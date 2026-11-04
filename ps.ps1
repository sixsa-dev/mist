Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public class MagCapture {
    [DllImport("user32.dll")] public static extern IntPtr GetDesktopWindow();
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
    [DllImport("Magnification.dll")] public static extern bool MagInitialize();
    [DllImport("Magnification.dll")] public static extern bool MagUninitialize();
    [DllImport("Magnification.dll")] public static extern bool MagGetImage(IntPtr hWnd, IntPtr hdcDest, ref RECT pRect);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }
}
"@

$desktop = [MagCapture]::GetDesktopWindow()
$rect = New-Object MagCapture+RECT
[MagCapture]::GetWindowRect($desktop, [ref]$rect) | Out-Null

$w = $rect.Right - $rect.Left
$ht = $rect.Bottom - $rect.Top

if ([MagCapture]::MagInitialize()) {
    try {
        $b = New-Object System.Drawing.Bitmap($w, $ht)
        $g = [System.Drawing.Graphics]::FromImage($b)
        $hdc = $g.GetHdc()
        
        # Attempt to capture via the Magnification engine
        [MagCapture]::MagGetImage($desktop, $hdc, [ref]$rect) | Out-Null
        
        $g.ReleaseHdc($hdc)
        $g.Dispose()
        
        $p = 'C:\Windows\Temp\scr.png'
        $b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $b.Dispose()
        Write-Output "Success: $p (Magnification API Capture)"
    } finally {
        [MagCapture]::MagUninitialize()
    }
} else {
    Write-Output "Error: Could not initialize Magnification API."
}
