// Copyright 2019 The TensorFlow Authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import UIKit

/// Helper functions for the UIImage class that is useful for this sample app.
extension UIImage {

    /// Returns the data representation of the image after scaling to the given `size` and removing
    /// the alpha component.
    ///
    /// - Parameters
    ///   - size: Size to scale the image to (i.e. image size used while training the model).
    ///   - byteCount: The expected byte count for the scaled image data calculated using the values
    ///       that the model was trained on: `imageWidth * imageHeight * componentsCount * batchSize`.
    ///   - isQuantized: Whether the model is quantized (i.e. fixed point values rather than floating
    ///       point values).
    /// - Returns: The scaled image as data or `nil` if the image could not be scaled.
    func scaledData(with size: CGSize, byteCount: Int, isQuantized: Bool) -> Data? {
      guard let cgImage = self.cgImage, cgImage.width > 0, cgImage.height > 0 else { return nil }
      guard let imageData = imageData(from: cgImage, with: size) else { return nil }
      var scaledBytes = [UInt8](repeating: 0, count: byteCount)
      var index = 0
      for component in imageData.enumerated() {
        let offset = component.offset
        let isAlphaComponent = (offset % Constant.alphaComponent.baseOffset)
          == Constant.alphaComponent.moduloRemainder
        guard !isAlphaComponent else { continue }
        scaledBytes[index] = component.element
        index += 1
      }
      if isQuantized { return Data(scaledBytes) }
        
      var scaledFloats = [Float]()
        
        if size.width == 256 {
            
            for i in 0..<scaledBytes.count {
                scaledFloats.append(Float(scaledBytes[i]) / 255.0)
            }
            
        }else {
            for i in 0..<scaledBytes.count {
                scaledFloats.append(Float(scaledBytes[i]) / 1.0)
            }
        }
        
//        let cls = CVViewController()
//        cls.write(toCsv: scaledFloats)
      return Data(copyingBufferOf: scaledFloats)
    }
    
  /// Helper function to center-crop image.
  /// - Returns: Center-cropped copy of this image
  func cropCenter() -> UIImage? {
    let isPortrait = size.height > size.width
    let isLandscape = size.width > size.height
    let breadth = min(size.width, size.height)
    let breadthSize = CGSize(width: breadth, height: breadth)
    let breadthRect = CGRect(origin: .zero, size: breadthSize)

    UIGraphicsBeginImageContextWithOptions(breadthSize, false, scale)
    let croppingOrigin = CGPoint(
      x: isLandscape ? floor((size.width - size.height) / 2) : 0,
      y: isPortrait ? floor((size.height - size.width) / 2) : 0
    )
    guard let cgImage = cgImage?.cropping(to: CGRect(origin: croppingOrigin, size: breadthSize))
    else { return nil }
    UIImage(cgImage: cgImage).draw(in: breadthRect)
    let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return croppedImage
  }

  /// Overlay an image on top of current image with alpha component
  /// - Parameters
  ///   - alpha: Alpha component of the image to be drawn on the top of current image
  /// - Returns: The overlayed image or `nil` if the image could not be drawn.
  func overlayWithImage(image: UIImage, alpha: Float) -> UIImage? {
    let areaSize = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)

    UIGraphicsBeginImageContext(self.size)
    self.draw(in: areaSize)
    image.draw(in: areaSize, blendMode: .normal, alpha: CGFloat(alpha))
    let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return newImage
  }
    
  /// Creates and returns a new image scaled to the given size. The image preserves its original PNG
  /// or JPEG bitmap info.
  ///
  /// - Parameter size: The size to scale the image to.
  /// - Returns: The scaled image or `nil` if image could not be resized.
  func scaledImage(with size: CGSize) -> UIImage? {
    UIGraphicsBeginImageContextWithOptions(size, false, scale)
    defer { UIGraphicsEndImageContext() }
    draw(in: CGRect(origin: .zero, size: size))
    return UIGraphicsGetImageFromCurrentImageContext()?.data.flatMap(UIImage.init)
  }
    
  /// The PNG or JPEG data representation of the image or `nil` if the conversion failed.
  private var data: Data? {
    #if swift(>=4.2)
    return self.pngData() ?? self.jpegData(compressionQuality: 1.0)
    #else
      return UIImagePNGRepresentation(self)
        ?? UIImageJPEGRepresentation(self, Constant.jpegCompressionQuality)
    #endif  // swift(>=4.2)
  }
    
  /// Returns the image data for the given CGImage based on the given `size`.
  private func imageData(from cgImage: CGImage, with size: CGSize) -> Data? {
    let bitmapInfo = CGBitmapInfo(
      rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    )
    let width = Int(size.width)
    let scaledBytesPerRow = (cgImage.bytesPerRow / cgImage.width) * width
    guard
      let context = CGContext(
        data: nil,
        width: width,
        height: Int(size.height),
        bitsPerComponent: cgImage.bitsPerComponent,
        bytesPerRow: scaledBytesPerRow,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: bitmapInfo.rawValue)
    else {
      return nil
    }
    context.draw(cgImage, in: CGRect(origin: .zero, size: size))
    return context.makeImage()?.dataProvider?.data as Data?
  }
}

/// Helper functions for the UIKit class that is useful for this sample app.
extension UIColor {

  // Check if the color is light or dark, as defined by the injected lightness threshold.
  // A nil value is returned if the lightness couldn't be determined.
  func isLight(threshold: Float = 0.5) -> Bool? {
    let originalCGColor = self.cgColor

    // Convert the color to the RGB colorspace as some color such as UIColor.white and .black
    // are grayscale.
    let RGBCGColor = originalCGColor.converted(
      to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)

    guard let components = RGBCGColor?.components else { return nil }
    guard components.count >= 3 else { return nil }

    // Calculate color brightness according to Digital ITU BT.601.
    let brightness = Float(
      ((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000
    )

    return (brightness > threshold)
  }
}

// MARK: - Constants

private enum Constant {
  static let alphaComponent = (baseOffset: 4, moduloRemainder: 3)
}
