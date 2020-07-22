//
//  OCRViewController.swift
//  TensorFlowLite-Test
//
//  Created by 石嘉晨 on 2020/7/22.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class OCRViewController: UIViewController {

    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.ocrModelInfo)
    
    @IBOutlet weak var Label: UILabel!
    
    @objc var image: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard modelDataHandler != nil else {
          fatalError("Model set up failed")
        }
        
        let result = modelDataHandler!.runModel(onFrame:CVPixelBuffer.buffer(from: self.image!)!)
        print("result == \(String(describing: result?.dataResult))")
        
//        CVViewController.write(toCsv: result!.dataResult)
        
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
