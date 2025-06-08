import UIKit
import CoreVideo
import VideoToolbox

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        // Use smaller size to reduce memory usage
        let targetSize = CGSize(width: 224, height: 224)
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(targetSize.width),
                                       Int(targetSize.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        let pixelData = CVPixelBufferGetBaseAddress(buffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: pixelData,
                                    width: Int(targetSize.width),
                                    height: Int(targetSize.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
                                    space: rgbColorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: targetSize.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        // Draw resized image
        context.draw(self.cgImage!, in: CGRect(origin: .zero, size: targetSize))
        
        return buffer
    }
    
    // Resize image to specific dimensions for model input
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    // Crop image to square aspect ratio
    func squareCropped() -> UIImage {
        let minDimension = min(size.width, size.height)
        let cropRect = CGRect(
            x: (size.width - minDimension) / 2,
            y: (size.height - minDimension) / 2,
            width: minDimension,
            height: minDimension
        )
        
        guard let cgImage = self.cgImage?.cropping(to: cropRect) else {
            return self
        }
        
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }
}