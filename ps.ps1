Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class C{[DllImport("user32.dll")]public static extern IntPtr GetForegroundWindow();[DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr d,uint f);[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);[DllImport("user32.dll")]public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);[StructLayout(LayoutKind.Sequential)]public struct RECT{public int L,T,R,B;}}'
$h=[C]::GetForegroundWindow()
[C]::SetWindowDisplayAffinity($h,0)|Out-Null
$r=New-Object C+RECT
[C]::GetWindowRect($h,[ref]$r)|Out-Null
$w=$r.R-$r.L
$ht=$r.B-$r.T
$b=New-Object System.Drawing.Bitmap($w,$ht)
$g=[System.Drawing.Graphics]::FromImage($b)
$dc=$g.GetHdc()
[C]::PrintWindow($h,$dc,2)
$g.ReleaseHdc($dc)
$g.Dispose()
$p='C:\Windows\Temp\scr.png'
$b.Save($p,[System.Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()
Write-Output "Success: $p"
