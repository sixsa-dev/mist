Add-Type -AssemblyName System.Drawing
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
using SharpDX;
using SharpDX.DXGI;

public class ScreenCapture {
    public static void Capture(string path) {
        var factory = new Factory1();
        var adapter = factory.GetAdapter1(0);
        var device = new SharpDX.Direct3D11.Device(adapter);
        var context = device.ImmediateContext;
        var output = adapter.GetOutput(0);
        var output1 = output.QueryOutput<Output1>();
        
        var desc = new OutputDescription();
        output.GetDescription(out desc);
        int width = desc.DesktopBounds.Right - desc.DesktopBounds.Left;
        int height = desc.DesktopBounds.Bottom - desc.DesktopBounds.Top;
        
        var duplication = output1.DuplicateOutput(device);
        var texture = new Texture2D(device, new SharpDX.Direct3D11.Texture2DDescription {
            Width = width,
            Height = height,
            MipLevels = 1,
            ArraySize = 1,
            SampleDescription = new SampleDescription(1, 0),
            Usage = SharpDX.Direct3D11.ResourceUsage.Staging,
            Format = Format.B8G8R8A8_UNorm,
            BindFlags = SharpDX.Direct3D11.BindFlags.None,
            CpuAccessFlags = SharpDX.Direct3D11.CpuAccessFlags.Read,
            OptionFlags = SharpDX.Direct3D11.ResourceOptionFlags.None
        });
        
        SharpDX.DXGI.Resource screenResource;
        OutputDuplicateFrameInformation duplicateFrameInformation;
        
        try {
            duplication.TryAcquireNextFrame(5000, out duplicateFrameInformation, out screenResource);
            var screenTexture2D = screenResource.QueryInterface<Texture2D>();
            context.CopyResource(screenTexture2D, texture);
            screenResource.Dispose();
            duplication.ReleaseFrame();
            
            var mapSource = context.MapSubresource(texture, 0, MapMode.Read, true);
            var bitmap = new System.Drawing.Bitmap(width, height, System.Drawing.Imaging.PixelFormat.Format32bppPArgb);
            var rect = new System.Drawing.Rectangle(0, 0, width, height);
            var bitmapData = bitmap.LockBits(rect, System.Drawing.Imaging.ImageLockMode.WriteOnly, bitmap.PixelFormat);
            
            int bytesPerPixel = 4;
            for (int y = 0; y < height; y++) {
                IntPtr sourcePtr = IntPtr.Add(mapSource.DataPointer, y * mapSource.RowPitch);
                IntPtr destPtr = IntPtr.Add(bitmapData.Scan0, y * bitmapData.Stride);
                for (int x = 0; x < width; x++) {
                    byte* src = (byte*)sourcePtr + x * bytesPerPixel;
                    byte* dst = (byte*)destPtr + x * bytesPerPixel;
                    dst[0] = src[2];
                    dst[1] = src[1];
                    dst[2] = src[0];
                    dst[3] = src[3];
                }
            }
            
            bitmap.UnlockBits(bitmapData);
            context.UnmapSubresource(texture, 0);
            bitmap.Save(path, System.Drawing.Imaging.ImageFormat.Png);
            bitmap.Dispose();
        } catch (Exception e) {
            Console.WriteLine("Error: " + e.Message);
        }
    }
}
"@ -ReferencedAssemblies "SharpDX.dll", "SharpDX.DXGI.dll", "SharpDX.Direct3D11.dll"

$filePath = 'C:\Windows\Temp\scr.png'
[ScreenCapture]::Capture($filePath)
Write-Output "Success: $filePath (DXGI Capture)"
