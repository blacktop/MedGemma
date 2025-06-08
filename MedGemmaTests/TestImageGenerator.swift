import UIKit
import CoreGraphics

class TestImageGenerator {
    
    // Generate a test image that simulates melanoma characteristics
    static func createMelanomaSimulation() -> UIImage {
        let size = CGSize(width: 224, height: 224)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background skin color
            cgContext.setFillColor(UIColor(red: 0.92, green: 0.8, blue: 0.7, alpha: 1.0).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Create irregular, asymmetric lesion
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Irregular border path (ABCDE: Asymmetry, Border irregularity)
            let path = UIBezierPath()
            path.move(to: CGPoint(x: centerX - 30, y: centerY - 25))
            
            // Create jagged, irregular borders
            let points = [
                CGPoint(x: centerX - 15, y: centerY - 35),
                CGPoint(x: centerX + 10, y: centerY - 30),
                CGPoint(x: centerX + 35, y: centerY - 15),
                CGPoint(x: centerX + 40, y: centerY + 5),
                CGPoint(x: centerX + 25, y: centerY + 25),
                CGPoint(x: centerX + 5, y: centerY + 35),
                CGPoint(x: centerX - 20, y: centerY + 30),
                CGPoint(x: centerX - 35, y: centerY + 10),
                CGPoint(x: centerX - 30, y: centerY - 25)
            ]
            
            for point in points {
                path.addLine(to: point)
            }
            path.close()
            
            // Multiple colors (ABCDE: Color variation)
            cgContext.setFillColor(UIColor.black.cgColor)
            cgContext.addPath(path.cgPath)
            cgContext.fillPath()
            
            // Add brown/dark brown variations
            cgContext.setFillColor(UIColor.brown.cgColor)
            let innerPath = UIBezierPath(ovalIn: CGRect(x: centerX - 15, y: centerY - 10, width: 20, height: 15))
            cgContext.addPath(innerPath.cgPath)
            cgContext.fillPath()
            
            // Add some reddish areas (potential inflammation)
            cgContext.setFillColor(UIColor.red.withAlphaComponent(0.6).cgColor)
            let redArea = UIBezierPath(ovalIn: CGRect(x: centerX + 5, y: centerY - 5, width: 12, height: 8))
            cgContext.addPath(redArea.cgPath)
            cgContext.fillPath()
            
            // Add texture/scaling
            cgContext.setStrokeColor(UIColor.darkGray.cgColor)
            cgContext.setLineWidth(1.0)
            for i in 0..<5 {
                let x = centerX - 10 + CGFloat(i * 4)
                cgContext.move(to: CGPoint(x: x, y: centerY - 5))
                cgContext.addLine(to: CGPoint(x: x, y: centerY + 5))
                cgContext.strokePath()
            }
        }
    }
    
    // Generate a benign mole for comparison
    static func createBenignMole() -> UIImage {
        let size = CGSize(width: 224, height: 224)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background skin color
            cgContext.setFillColor(UIColor(red: 0.92, green: 0.8, blue: 0.7, alpha: 1.0).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Create regular, symmetric lesion
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            // Regular circular border (ABCDE: Symmetry, regular Border)
            let radius: CGFloat = 20
            let circle = UIBezierPath(arcCenter: CGPoint(x: centerX, y: centerY), 
                                    radius: radius, 
                                    startAngle: 0, 
                                    endAngle: .pi * 2, 
                                    clockwise: true)
            
            // Uniform color (ABCDE: consistent Color)
            cgContext.setFillColor(UIColor.brown.cgColor)
            cgContext.addPath(circle.cgPath)
            cgContext.fillPath()
            
            // Smooth, well-defined border
            cgContext.setStrokeColor(UIColor.brown.darkened().cgColor)
            cgContext.setLineWidth(1.0)
            cgContext.addPath(circle.cgPath)
            cgContext.strokePath()
        }
    }
    
    // Generate image with inflammatory characteristics
    static func createInflammatoryLesion() -> UIImage {
        let size = CGSize(width: 224, height: 224)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            let cgContext = context.cgContext
            
            // Background skin color
            cgContext.setFillColor(UIColor(red: 0.92, green: 0.8, blue: 0.7, alpha: 1.0).cgColor)
            cgContext.fill(CGRect(origin: .zero, size: size))
            
            // Create red, inflamed area
            let centerX = size.width / 2
            let centerY = size.height / 2
            
            let inflammedArea = UIBezierPath(ovalIn: CGRect(x: centerX - 25, y: centerY - 20, width: 50, height: 40))
            
            cgContext.setFillColor(UIColor.red.withAlphaComponent(0.8).cgColor)
            cgContext.addPath(inflammedArea.cgPath)
            cgContext.fillPath()
            
            // Add scaling/texture
            cgContext.setFillColor(UIColor.white.withAlphaComponent(0.7).cgColor)
            for i in 0..<8 {
                let angle = CGFloat(i) * .pi / 4
                let x = centerX + cos(angle) * 15
                let y = centerY + sin(angle) * 12
                let scale = UIBezierPath(ovalIn: CGRect(x: x - 2, y: y - 2, width: 4, height: 4))
                cgContext.addPath(scale.cgPath)
                cgContext.fillPath()
            }
        }
    }
}

extension UIColor {
    func darkened(by percentage: CGFloat = 0.3) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(red: red * (1 - percentage), 
                      green: green * (1 - percentage), 
                      blue: blue * (1 - percentage), 
                      alpha: alpha)
    }
}