//
//  ScanViewController.swift
//  TensorFlowLite-Test
//
//  Created by Shi Jiachen on 2020/08/07.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class ScanViewController: UIViewController {

    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var finalImageView: UIImageView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var bottomViewY: NSLayoutConstraint!
    @IBOutlet weak var lightBtn: UIButton!
    
    var timer = Timer()
    var oriImage = UIImage()
    let finderViewRect = CGRect(x: 30, y: 150, width: SCREEN_WIDTH - 60, height: 400)
    let scanLineImageViewOriginalFrame = CGRect(x: 30, y: 150, width: SCREEN_WIDTH - 60, height: 10)
    lazy var scanView = KOFinderView(frame: finderViewRect)
    lazy var backgroundView : UIView = {
        
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor =  UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.6)

        let maskLayer = CAShapeLayer()
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd //  奇偶层显示规则
        
        let basicPath = UIBezierPath(rect: self.view.frame) // 底层
        let maskPath = UIBezierPath(rect: self.finderViewRect) //自定义的遮罩图形
        basicPath.append(maskPath) // 重叠
        
        maskLayer.path = basicPath.cgPath
        backgroundView.layer.mask = maskLayer
        
        return backgroundView
    }()
    
    private lazy var scanLineImageView = UIImageView(frame: scanLineImageViewOriginalFrame)
    
    private var modelDataHandler: ModelDataHandler? = ModelDataHandler(modelFileInfo: MobileNet.barCodeModelInfo, labelsFileInfo: MobileNet.labelsInfo)
    
    // MARK: Controllers that manage functionality
    private lazy var cameraFeedManager = CameraFeedManager(previewView: previewView)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraFeedManager.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
        
      self.navigationController?.navigationBar.isHidden = true
        
      clearAllUserDefaultsData()
      cameraFeedManager.checkCameraConfigurationAndStartSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if self.finalImageView.image == nil {
            self.setupSubviewsAndLines()
        }else {
            
            self.finalImageView.image = nil
            self.previewView.isHidden = false
            self.scanLineImageView.isHidden = false
            timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(moveScannerLayer(_:)), userInfo: nil, repeats: true)
            timer.fire()
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)

      self.bottomViewY.constant = -200
      cameraFeedManager.stopSession()
      previewView.isHidden = true
      timer.invalidate()
    }

    @IBAction func closeAction(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }

    //让扫描线滚动
    @objc func moveScannerLayer(_ timer : Timer) {
        self.scanLineImageView.frame = self.scanLineImageViewOriginalFrame
      UIView.animate(withDuration: 2) {
        self.scanLineImageView.frame = CGRect(x: self.scanLineImageView.frame.origin.x, y: self.scanLineImageView.frame.origin.y + self.finderViewRect.size.height - 10, width: self.scanLineImageView.frame.size.width, height: self.scanLineImageView.frame.size.height)
      }
    }
    
    func setupSubviewsAndLines() {
        
//        view.addSubview(scanView)
//        view.addSubview(backgroundView)
//        backgroundView.addSubview(closeBtn)
        
        previewView.isHidden = false
        scanLineImageView.image = UIImage(named: "qr_scan_line")
        self.view.addSubview(scanLineImageView)
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(moveScannerLayer(_:)), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func clearAllUserDefaultsData() {
        
        let userDefaults = UserDefaults.standard
        let dics = userDefaults.dictionaryRepresentation()
        for key in dics {
            userDefaults.removeObject(forKey: key.key)
            
        }
        userDefaults.synchronize()
    }
    
    
    @IBAction func rescan(_ sender: Any) {
        
        clearAllUserDefaultsData()
        
        self.bottomViewY.constant = -200
        self.finalImageView.image = nil
        self.previewView.isHidden = false
        self.scanLineImageView.isHidden = false
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(moveScannerLayer(_:)), userInfo: nil, repeats: true)
        timer.fire()
        cameraFeedManager.checkCameraConfigurationAndStartSession()
    }
    
    
    @IBAction func confirm(_ sender: Any) {
        
        let cls = CVViewController()
        let image = cls.clipImage(oriImage)
        clearAllUserDefaultsData()
        
        guard let ocrClass = self.storyboard?.instantiateViewController(withIdentifier: String(describing: type(of: OCRViewController()))) as! OCRViewController? else {
            
            return
        }
         ocrClass.image = image
        
        self.navigationController?.pushViewController(ocrClass, animated: true)
    }
    @IBAction func lightAction(_ sender: Any) {
        
        if !lightBtn.isSelected {
            cameraFeedManager.turnOnLight()
        }else {
            cameraFeedManager.turnOffLight()
        }
        lightBtn.isSelected = !lightBtn.isSelected
    }
}

// MARK: CameraFeedManagerDelegate Methods
extension ScanViewController: CameraFeedManagerDelegate {

  func didOutput(pixelBuffer: CVPixelBuffer) {
    
    let resizeBuffer = pixelBuffer.resized(to: CGSize(width: 512.0, height: 768.0))
    let result = modelDataHandler!.runModel(withBuffer: resizeBuffer!)
    let image = self.pixelBufferToImage(pixelBuffer: resizeBuffer!)
//    let cutImage = self.clipWithImageRect(clipFrame: finderViewRect, bgImage: image!).scaledImage(with: CGSize(width: 512.0, height: 768.0))
//    let result = modelDataHandler!.runModel(withImage: cutImage!)

    DispatchQueue.main.async {
        guard let imageArr = CVViewController.findBarCode(image!, withData: result!.dataResult) else {

            print("no result")
            return;
        }
        
        if imageArr.count == 0 {
            
            print("imageArr count = 0")
            return;
        }
        
        let cutImage = imageArr.first as! UIImage
        self.oriImage = imageArr.last as! UIImage
        
        if self.finalImageView.image != nil {
            return;
        }
        self.finalImageView.image = cutImage.scaledImage(with: CGSize(width: 1080.0, height: 1920.0))
        self.lightBtn.isSelected = false
        self.cameraFeedManager.turnOffLight()
        self.cameraFeedManager.stopSession()
//        self.scanView.removeFromSuperview()
//        self.backgroundView.removeFromSuperview()
        self.previewView.isHidden = true
        self.scanLineImageView.isHidden = true
        self.timer.invalidate()
        self.bottomViewY.constant = 0
        
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
  }

  // MARK: Session Handling Alerts
  func sessionRunTimeErrorOccured() {

    // Handles session run time error by updating the UI and providing a button if session can be manually resumed.
  }

  func sessionWasInterrupted(canResumeManually resumeManually: Bool) {

    
  }

  func sessionInterruptionEnded() {

    // Updates UI once session interruption has ended.
   
  }

  func presentVideoConfigurationErrorAlert() {

    let alertController = UIAlertController(title: "Confirguration Failed", message: "Configuration of camera has failed.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
    alertController.addAction(okAction)

    present(alertController, animated: true, completion: nil)
  }

  func presentCameraPermissionsDeniedAlert() {

    let alertController = UIAlertController(title: "Camera Permissions Denied", message: "Camera permissions have been denied for this app. You can change this by going to Settings", preferredStyle: .alert)

    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let settingsAction = UIAlertAction(title: "Settings", style: .default) { (action) in

      UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }

    alertController.addAction(cancelAction)
    alertController.addAction(settingsAction)

    present(alertController, animated: true, completion: nil)

  }
    
    func clipWithImageRect(clipFrame: CGRect, bgImage: UIImage) -> UIImage {
        
        let rect_Scale = CGRect(x: clipFrame.origin.x, y: clipFrame.origin.y, width: clipFrame.size.width, height: clipFrame.size.height)
        
        let cgImageCorpped = bgImage.cgImage?.cropping(to: rect_Scale)
        let img_Clip = UIImage.init(cgImage: cgImageCorpped!, scale: 1, orientation: UIImage.Orientation.up)
        
        return img_Clip
    }
    
    func pixelBufferToImage(pixelBuffer: CVPixelBuffer) -> UIImage? {
    //        let type = CVPixelBufferGetPixelFormatType(pixelBuffer)
            
            let width = CVPixelBufferGetWidth(pixelBuffer)
            let height = CVPixelBufferGetHeight(pixelBuffer)
            let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
            
            CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
            guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.noneSkipFirst.rawValue),
                let imageRef = context.makeImage() else
            {
                    return nil
            }
            
            let newImage = UIImage(cgImage: imageRef)
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            
            return newImage
        }

}
