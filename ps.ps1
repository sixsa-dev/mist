Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class C{[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h, int nCmdShow);[StructLayout(LayoutKind.Sequential)]public struct RECT{public int L,T,R,B;}}'

$procs = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.ProcessName -notmatch "powershell|cmd|conhost|explorer|telegram" } | Sort-Object MainWindowTitle -Descending

if ($procs.Count -gt 0) {
    $target = $procs[0]
    $h = $target.MainWindowHandle
    
    [C]::ShowWindow($h, 9) 
    [C]::SetForegroundWindow($h)
    Start-Sleep -Milliseconds 800
    
    $r = New-Object C+RECT
    [C]::GetWindowRect($h, [ref]$r) | Out-Null
    
    $w = $r.R - $r.L
    $ht = $r.B - $r.T
    
    if ($w -gt 0 -and $ht -gt 0) {
        $b = New-Object System.Drawing.Bitmap($w, $ht)
        $g = [System.Drawing.Graphics]::FromImage($b)
        
        # Replaced PrintWindow with CopyFromScreen
        $g.CopyFromScreen($r.L, $r.T, 0, 0, $b.Size)
        
        $g.Dispose()
        $p = 'C:\Windows\Temp\scr.png'
        $b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $b.Dispose()
        Write-Output "Success: $p (Captured: $($target.ProcessName))"
    } else {
        Write-Output "Error: Window has no dimensions."
    }
} else {
    Write-Output "Error: No suitable target window found."
}
