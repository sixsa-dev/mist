Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -TypeDefinition '
using System;
using System.Runtime.InteropServices;
public class C {
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetWindowDisplayAffinity(IntPtr h, uint a);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}'

# 1. Find the main visible window, ignoring background console processes
$procs = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 -and $_.ProcessName -notmatch "powershell|cmd|conhost|explorer|telegram|dllhost" } | Sort-Object MainWindowTitle -Descending

if ($procs.Count -gt 0) {
    $target = $procs[0]
    $h = $target.MainWindowHandle
    
    # 2. Force the window to restore (if minimized) and come to the absolute front
    [C]::ShowWindow($h, 9) # 9 = SW_RESTORE
    [C]::SetForegroundWindow($h)
    
    # 3. Strip any screenshot protection flags (WDA_NONE = 0)
    [C]::SetWindowDisplayAffinity($h, 0) | Out-Null
    
    # 4. Wait for DWM to composite the frame on the physical screen
    Start-Sleep -Milliseconds 1000
    
    # 5. Get window dimensions
    $r = New-Object C+RECT
    [C]::GetWindowRect($h, [ref]$r) | Out-Null
    
    $w = $r.R - $r.L
    $ht = $r.B - $r.T
    
    if ($w -gt 0 -and $ht -gt 0) {
        $b = New-Object System.Drawing.Bitmap($w, $ht)
        $g = [System.Drawing.Graphics]::FromImage($b)
        
        # Capture the physical screen area where the window is located
        $g.CopyFromScreen($r.L, $r.T, 0, 0, $b.Size)
        
        $g.Dispose()
        $p = 'C:\Windows\Temp\scr.png'
        $b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
        $b.Dispose()
        Write-Output "Success: $p (Captured: $($target.ProcessName))"
    } else {
        Write-Output "Error: Window has no dimensions. It might be minimized or hidden."
    }
} else {
    Write-Output "Error: No suitable target window found."
}
