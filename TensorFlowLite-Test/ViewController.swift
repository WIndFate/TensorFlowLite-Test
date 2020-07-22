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
        
        if BarCodeModel {
            self.image = UIImage(named: "barcode_test_1_orig")?.scaledImage(with: CGSize(width: 1792.0, height: 1280.0))
        }else {
            self.image = UIImage(named: "test_5")?.scaledImage(with: CGSize(width: 1280, height: 1792.0))
        }
        self.imageView.image = self.image
        let result = modelDataHandler!.runModel(onFrame:CVPixelBuffer.buffer(from: self.image!)!)
        
        print("result == \(String(describing: result?.tensor.shape.dimensions)))")
        
        self.array = result!.dataResult
        
        
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
    
    func resizeImage(_ width: CGFloat, _ height: CGFloat) -> UIImage {

        let renderFormat = UIGraphicsImageRendererFormat.default()

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)

        return renderer.image {

            (context) in

            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))

        }

    }
}


// MARK: - Constants
private enum Constants {

  static let inputImageSize = CGSize(width: 80, height: 40)

}
