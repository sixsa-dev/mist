Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -TypeDefinition 'using System;using System.Runtime.InteropServices;public class C{[DllImport("user32.dll")]public static extern bool SetForegroundWindow(IntPtr h);[DllImport("user32.dll")]public static extern bool PrintWindow(IntPtr h,IntPtr d,uint f);[DllImport("user32.dll")]public static extern bool GetWindowRect(IntPtr h,out RECT r);[DllImport("user32.dll")]public static extern bool SetWindowDisplayAffinity(IntPtr h,uint a);[DllImport("user32.dll")]public static extern bool ShowWindow(IntPtr h, int nCmdShow);[StructLayout(LayoutKind.Sequential)]public struct RECT{public int L,T,R,B;}}'

# 1. Find the main visible window, ignoring background console processes
$procs = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.ProcessName -notmatch "powershell|cmd|conhost|explorer|telegram" } | Sort-Object MainWindowTitle -Descending

if ($procs.Count -gt 0) {
    $target = $procs[0]
    $h = $target.MainWindowHandle
    
    # 2. Force the window to restore (if minimized) and come to the absolute front
    [C]::ShowWindow($h, 9) # 9 = SW_RESTORE
    [C]::SetForegroundWindow($h)
    
    # 3. Wait briefly for the GPU to render the window on screen
    Start-Sleep -Milliseconds 800
    
    # 4. Strip screenshot protection and capture
    [C]::SetWindowDisplayAffinity($h, 0) | Out-Null
    $r = New-Object C+RECT
    [C]::GetWindowRect($h, [ref]$r) | Out-Null
    
    $w = $r.R - $r.L
    $ht = $r.B - $r.T
    
    if ($w -gt 0 -and $ht -gt 0) {
        $b = New-Object System.Drawing.Bitmap($w, $ht)
        $g = [System.Drawing.Graphics]::FromImage($b)
        $dc = $g.GetHdc()
        
        # Flag 2 (PW_RENDERFULLCONTENT) forces rendering of hardware overlays
        [C]::PrintWindow($h, $dc, 2)
        
        $g.ReleaseHdc($dc)
        $g.Dispose()
        $p = 'C:\Windows\Temp\scr.png'
        $b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $b.Dispose()
        Write-Output "Success: $p (Captured: $($target.ProcessName))"
    } else {
        Write-Output "Error: Window has no dimensions. It might be completely hidden or minimized."
    }
} else {
    Write-Output "Error: No suitable target window found."
}
