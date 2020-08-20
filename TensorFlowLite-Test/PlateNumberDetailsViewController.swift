//
//  PlateNumberDetailsViewController.swift
//  TensorFlowLite-Test
//
//  Created by Shi Jiachen on 2020/08/19.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class PlateNumberDetailsViewController: UIViewController {

    @IBOutlet weak var plateNumber: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var image: UIImage!
    
    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.plateNumberOcrModelInfo, labelsFileInfo: MobileNet.plateNumberLabelsInfo)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard modelDataHandler != nil else {
          fatalError("Model set up failed")
        }
        
        let start = CFAbsoluteTimeGetCurrent()
        let result = modelDataHandler!.runModel(withImage: image.scaledImage(with: CGSize(width: 32.0, height: 160.0))!, isOcrModel: true)
        
        let cls = CVViewController()
        cls.write(toCsv: result?.dataResult)
        
        let end = CFAbsoluteTimeGetCurrent()
        
        guard let inferencesArr = result?.inferences else {
            print("inferences == nil")
            return
        }
        let stringArr = inferencesArr.map({$0.label})
        plateNumber.text = "NO：\(stringArr.joined())"
        
        print("OCR time  == \(end - start)")
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
