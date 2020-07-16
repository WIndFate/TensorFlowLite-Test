//
//  ViewController.swift
//  TensorFlowLite-Test
//
//  Created by Kou Syui on 2020/06/30.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.modelInfo)
    
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage?
    
    var array: [Float]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard modelDataHandler != nil else {
          fatalError("Model set up failed")
        }
        
        let result = modelDataHandler!.runModel(onFrame: buffer(from: UIImage(named: "test_5")!)!)
        
        print("result == \(String(describing: result?.tensor.shape.dimensions)))")
        
        let cgImage = self.imageFromSRGBColorArray(pixels: result!.dataResult, width: 320, height: 448)
        
        self.image = UIImage(cgImage: cgImage!)
        self.array = result!.dataResult
        
//        self.imageView.image = self.image
        
        
        
//        let image = UIImage(named: "testImage")!
//
//        let rect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
//
//        UIGraphicsBeginImageContext(rect.size)
//        let currentContext =  UIGraphicsGetCurrentContext()!
//        currentContext.clip(to: rect)
//        currentContext.draw(image.cgImage!, in: rect)
//
//        let drawImage =  UIGraphicsGetImageFromCurrentImageContext()!;
//
//        imageView.image = drawImage.imageRotatedByDegrees(degrees: 90)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "CVViewController" else {
            return
        }
        
        let cls = segue.destination as! CVViewController
        
        cls.image = self.image!
        cls.array = self.array!
    }
    
    func imageFromSRGBColorArray(pixels: [Float32], width: Int, height: Int) -> CGImage?
    {
        guard width > 0 && height > 0 else { return nil }
        guard pixels.count == width * height else { return nil }

        // Make a mutable copy
        var data = pixels

        // Convert array of pixels to a CGImage instance.
        let cgImage = data.withUnsafeMutableBytes { (ptr) -> CGImage in
          let ctx = CGContext(
            data: ptr.baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: MemoryLayout<UInt32>.size * width,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue
              + CGImageAlphaInfo.premultipliedFirst.rawValue
          )!
          return ctx.makeImage()!
        }

        // Convert the CGImage instance to an UIImage instance.
        return cgImage
      }

    func buffer(from image: UIImage) -> CVPixelBuffer? {
      let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
      var pixelBuffer : CVPixelBuffer?
      let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
      guard (status == kCVReturnSuccess) else {
        return nil
      }

      CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
      let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)

      let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
      let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)

      context?.translateBy(x: 0, y: image.size.height)
      context?.scaleBy(x: 1.0, y: -1.0)

      UIGraphicsPushContext(context!)
      image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
      UIGraphicsPopContext()
      CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))

      return pixelBuffer
    }

}

extension UIImage {

    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        
        let scaleRate = 66 / self.size.height
        
        let rotatedSize: CGSize = CGRect(x: 0, y: 0, width: self.size.height * scaleRate, height: self.size.width * scaleRate).size

        //Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext = UIGraphicsGetCurrentContext()!
        //Move the origin to the middle of the image so we will rotate and scale around the center.
        bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        //Rotate the image context
        bitmap.rotate(by: (degrees * CGFloat.pi / 180))
        //Now, draw the rotated/scaled image into the context
        bitmap.scaleBy(x: 1.0 * scaleRate, y: -1.0 * scaleRate)
        bitmap.draw(self.cgImage!, in: CGRect(x: -self.size.width / 2, y: -self.size.height / 2, width: self.size.width, height: self.size.height))

        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!

        UIGraphicsEndImageContext()
        return newImage
    }
}


// MARK: - Constants
private enum Constants {

  static let inputImageSize = CGSize(width: 80, height: 40)

}
