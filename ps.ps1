Add-Type -AssemblyName System.Drawing, System.Windows.Forms

# Get primary screen resolution
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
$w = $screen.Width
$ht = $screen.Height

$b = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($b)

# Capture the entire physical screen
$g.CopyFromScreen(0, 0, 0, 0, $b.Size)

$g.Dispose()
$p = 'C:\Windows\Temp\scr.png'
$b.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
$b.Dispose()
Write-Output "Success: $p (Full Screen Capture)"
