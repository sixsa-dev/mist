Add-Type -AssemblyName System.Drawing

# 1. Try loading System.Windows.Forms to get exact screen bounds
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $w = $bounds.Width
    $ht = $bounds.Height
} catch {
    # 2. Fallback: Use WMI to get the primary monitor's resolution
    $video = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $w = [int]$video.CurrentHorizontalResolution
    $ht = [int]$video.CurrentVerticalResolution
    
    # 3. Ultimate fallback if WMI returns null (e.g., driver quirks)
    if ($w -le 0 -or $ht -le 0) {
        $w = 1920
        $ht = 1080
    }
}

# Create bitmap with validated dimensions
$b = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($b)

# Capture the entire physical screen starting from top-left (0,0)
$g.CopyFromScreen(0, 0, 0, 0, $b.Size)

$g.Dispose()
$p = 'C:\Windows\Temp\scr.png'
$b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()

Write-Output "Success: $p (Full Screen Capture - ${w}x${ht})"
