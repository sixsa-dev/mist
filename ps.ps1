Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class KeyInput {
    [DllImport("user32.dll")]
    public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
    public const byte VK_SNAPSHOT = 0x2C;
    public const uint KEYEVENTF_KEYUP = 0x0002;
}
"@

# 1. Simulate pressing the PrintScreen key at the system level
[KeyInput]::keybd_event([KeyInput]::VK_SNAPSHOT, 0, 0, [UIntPtr]::Zero)
[KeyInput]::keybd_event([KeyInput]::VK_SNAPSHOT, 0, [KeyInput]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)

# 2. Wait for Windows to process the GPU capture into the clipboard
Start-Sleep -Milliseconds 1000

# 3. Save the clipboard image to a file
if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
    $img = [System.Windows.Forms.Clipboard]::GetImage()
    $p = 'C:\Windows\Temp\scr.png'
    $img.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    $img.Dispose()
    Write-Output "Success: $p (Clipboard Capture)"
} else {
    Write-Output "Error: PrintScreen was blocked by the system or clipboard is empty."
}
