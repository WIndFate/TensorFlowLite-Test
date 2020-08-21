//
//  PlateNumberDetailsViewController.swift
//  TensorFlowLite-Test
//
//  Created by Shi Jiachen on 2020/08/19.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class PlateNumberDetailsViewController: UIViewController {

    @IBOutlet weak var topNumber: UILabel!
    @IBOutlet weak var bottomNumber: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var imageArr = [Any]()
    
    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.plateNumberOcrModelInfo, labelsFileInfo: MobileNet.plateNumberLabelsInfo)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard modelDataHandler != nil else {
          fatalError("Model set up failed")
        }
        
        if imageArr.first is String {
            topNumber.text = "No Result"
        }else {
            topNumber.text = ocrStringFromImage(image: imageArr.first as! UIImage)
        }
        
        if imageArr.last is String {
            bottomNumber.text = "No Result"
        }else {
            bottomNumber.text = ocrStringFromImage(image: imageArr.last as! UIImage)
        }
        
    }
    

    func ocrStringFromImage(image : UIImage) -> String {
        
        let start = CFAbsoluteTimeGetCurrent()
        let result = modelDataHandler!.runModel(withImage: image.scaledImage(with: CGSize(width: 32.0, height: 160.0))!, isOcrModel: true)
        
        let end = CFAbsoluteTimeGetCurrent()
        
        print("OCR time  == \(end - start)")
        
        guard let inferencesArr = result?.inferences else {
            print("inferences == nil")
            return "---Error---"
        }
        let stringArr = inferencesArr.map({$0.label})
        
        let resultStr = stringArr.joined()
        
        return resultStr
    }

}
