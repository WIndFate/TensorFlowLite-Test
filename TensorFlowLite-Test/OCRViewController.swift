//
//  OCRViewController.swift
//  TensorFlowLite-Test
//
//  Created by 石嘉晨 on 2020/7/22.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class OCRViewController: UIViewController {

    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.ocrModelInfo, labelsFileInfo: MobileNet.labelsInfo)
    
    @IBOutlet weak var Label: UILabel!
    
    @objc var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard modelDataHandler != nil else {
          fatalError("Model set up failed")
        }
        
        guard let img = self.image?.scaledImage(with: CGSize(width: 32.0, height: 256.0)) else {
            return
        }
//
//        let imgData = img.pngData()
//        let imgPath = "/Users/shijiachen/Desktop/local.png"
//        NSData(data: imgData!).write(toFile: imgPath, atomically: true)
        
        let start = CFAbsoluteTimeGetCurrent()
        
//        let result = modelDataHandler!.runModel(onFrame:CVPixelBuffer.buffer(from: self.image!)!)
        let result = modelDataHandler!.runModel(withImage: img, isOcrModel: true)
        
        let end = CFAbsoluteTimeGetCurrent()
        
        guard let inferencesArr = result?.inferences else {
            print("inferences == nil")
            return
        }
        let stringArr = inferencesArr.map({$0.label})
        Label.text = stringArr.joined()
        
        print("OCR time  == \(end - start)")
        
//        let cls = CVViewController()
//        cls.write(toCsv: result!.dataResult)
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
