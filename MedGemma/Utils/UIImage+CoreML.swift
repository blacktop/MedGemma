import UIKit
import CoreVideo
import VideoToolbox

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
             kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                       Int(self.size.width),
                                       Int(self.size.height),
                                       kCVPixelFormatType_32ARGB,
                                       attrs,
                                       &pixelBuffer)
        
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData,
                              width: Int(self.size.width),
                              height: Int(self.size.height),
                              bitsPerComponent: 8,
                              bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                              space: rgbColorSpace,
                              bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }
    
    // Resize image to specific dimensions for model input
    func resized(to size: CGSize) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
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