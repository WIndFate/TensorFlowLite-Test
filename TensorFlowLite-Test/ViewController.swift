//
//  ViewController.swift
//  TensorFlowLite-Test
//
//  Created by Kou Syui on 2020/06/30.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TZImagePickerControllerDelegate, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    private var modelDataHandler: ModelDataHandler?
    private var location: CLLocation?
    private lazy var imagePickerVc: UIImagePickerController = {
        
        let imagePickerVc = UIImagePickerController()
        imagePickerVc.delegate = self
        imagePickerVc.navigationBar.barTintColor = self.navigationController?.navigationBar.barTintColor
        imagePickerVc.navigationBar.tintColor = self.navigationController?.navigationBar.tintColor
        
        let tzBarItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [TZImagePickerController.self])
        let BarItem = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIImagePickerController.self])
        
        let titleTextAttributes = tzBarItem.titleTextAttributes(for: UIControl.State.normal)
        BarItem.setTitleTextAttributes(titleTextAttributes, for: UIControl.State.normal)
        
        return imagePickerVc;
    }()
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var opencvBtn: UIButton!
    
    var image: UIImage?
    
    var array: [Float]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if BarCodeModel {
            
            modelDataHandler = ModelDataHandler(modelFileInfo: MobileNet.barCodeModelInfo, labelsFileInfo: MobileNet.labelsInfo)
            
            guard modelDataHandler != nil else {
              fatalError("Model set up failed")
            }
            
//            self.image = UIImage(named: "37477")?.scaledImage(with: CGSize(width: 512.0, height: 768.0))
            
        }else {
            
            modelDataHandler = ModelDataHandler(modelFileInfo: MobileNet.testModelInfo, labelsFileInfo: MobileNet.labelsInfo)
            
            guard modelDataHandler != nil else {
              fatalError("Model set up failed")
            }
            
            self.image = UIImage(named: "test_5")?.scaledImage(with: CGSize(width: 1280, height: 1792.0))
        }
        self.imageView.image = self.image
        
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
        cls.oriImage = self.image!
        cls.array = self.array!
    }
    
    func takePhoto() {
    
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        if authStatus == .restricted || authStatus == .denied {
            
            let alertController = UIAlertController(title: "カメラは利用できません",
                                                            message: "設定ーappーカメラーオン", preferredStyle: .alert)
            let settingAction = UIAlertAction(title: "設定", style: .default, handler:{
                action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [ : ]) { (Success) in
                    
                }
            })
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: {
                action in
                
            })
            alertController.addAction(settingAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        } else if authStatus == .notDetermined {
            
            AVCaptureDevice.requestAccess(for: .video) { (granted : Bool) in
                
                if granted {
                    DispatchQueue.main.async {
                        self.takePhoto()
                    }
                }
            }
        } else if PHPhotoLibrary.authorizationStatus().rawValue == 2 {
            
            let alertController = UIAlertController(title: "アルバムは利用できません",
                                                            message: "設定ーappーアルバムーオン", preferredStyle: .alert)
            let settingAction = UIAlertAction(title: "設定", style: .default, handler:{
                action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [ : ]) { (Success) in
                    
                }
            })
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: {
                action in
                
            })
            alertController.addAction(settingAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        } else if PHPhotoLibrary.authorizationStatus().rawValue == 0 {
            
            TZImageManager().requestAuthorization {
                self.takePhoto()
            }
        
        } else {
            
            self.pushImagePickerController()
        }
    }
    
    func pushImagePickerController() {
        
        // 提前定位
//        weak var weakSelf = self
        
        TZLocationManager().startLocation(successBlock: { (locations : [CLLocation]?) in
            
            self.location = locations?.first
        }) { (error : Error?) in
            self.location = nil
        }
        
        let sourceType = UIImagePickerController.SourceType.camera
        if UIImagePickerController .isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            self.imagePickerVc.sourceType = sourceType
//            var mediaTypes = [Any]()
            self.present(imagePickerVc, animated: true) {
                
            }
        } else {
            print("模拟器中无法打开照相机,请在真机中使用")
        }
    }
    
    func pushTZImagePickerController() {
        
        guard let imagePickerVc = TZImagePickerController(maxImagesCount: 1, columnNumber: 4, delegate: self, pushPhotoPickerVc: true) else {
            
            return
        }
        
        imagePickerVc.didFinishPickingPhotosHandle = {(photos : [UIImage]?, assets : [Any]?, isSelectOriginalPhoto : Bool) in
            
            print(photos as Any)
            
            let image = photos?.first!.scaledImage(with: CGSize(width: 512.0, height: 768.0))
            self.imageView.image = image
            self.image = image;
        }
        
        imagePickerVc.modalPresentationStyle = .fullScreen
        self.present(imagePickerVc, animated: true) {
            
        }
    }
    
    @IBAction func alertSheet(_ sender: Any) {
        
        let alertController = UIAlertController(title: "写真",
                                                message: "写真を選択してください", preferredStyle: .actionSheet)
        
        let scanAction = UIAlertAction(title: "Scan Buffer", style: .default, handler:{
            action in
            
            guard let sacnVc = self.storyboard?.instantiateViewController(withIdentifier: String(describing: type(of: ScanViewController()))) else {
                
                return
            }
            
            self.navigationController?.pushViewController(sacnVc, animated: true)
        })
        
        let cameraAction = UIAlertAction(title: "カメラ", style: .default, handler:{
            action in
            
            self.takePhoto()
        })
        
        let albumsAction = UIAlertAction(title: "アルバム", style: .default, handler: {
            action in
            
            self.pushTZImagePickerController()
        })
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: {
            action in
            
        })
        
//        okAction.setValue(UIColor.red, forKey:"titleTextColor")//alertController按钮颜色
        alertController.addAction(scanAction)
        alertController.addAction(cameraAction)
        alertController.addAction(albumsAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    @IBAction func runModel(_ sender: Any) {
        
        let start = CFAbsoluteTimeGetCurrent()

//        let result = modelDataHandler!.runModel(onFrame:CVPixelBuffer.buffer(from: self.image!)!)
        let result = modelDataHandler!.runModel(withImage: self.image!.scaledImage(with: CGSize(width: 512.0, height: 768.0))!)

        let end = CFAbsoluteTimeGetCurrent()

        print("barCode time  == \(end - start)")

        self.array = result!.dataResult
        

        let cls = self.storyboard?.instantiateViewController(withIdentifier: String(describing: type(of: CVViewController())))
        as! CVViewController
        cls.write(toCsv: result!.dataResult)
        
        cls.image = self.image!
        cls.oriImage = self.image!
        cls.array = self.array!
        
        self.navigationController?.pushViewController(cls, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) {
            
        }
        let type = info[UIImagePickerController.InfoKey.mediaType] as! String
        let tzImagePickerVc = TZImagePickerController(maxImagesCount: 1, delegate: self)
        tzImagePickerVc?.showProgressHUD()
        
        if type == "public.image" {
            
            let image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage
            let meta = info[UIImagePickerController.InfoKey.mediaMetadata]
            
            TZImageManager().savePhoto(with: image, meta: (meta as! [AnyHashable : Any]), location: self.location) { (asset : PHAsset?, error : Error?) in
                
                tzImagePickerVc?.hideProgressHUD()
                
                if error != nil{
                    print(error as Any)
                } else {
//                    let assetModel = TZImageManager().createModel(with: asset)
                    let finalImage = image.scaledImage(with: CGSize(width: 512.0, height: 768.0))
                    self.imageView.image = finalImage
                    self.image = finalImage;
                }
            }
        }
        
    }
    
}

extension UIImage {

    public func imageRotatedByDegrees(degrees: CGFloat) -> UIImage {
        
        let scaleRate : CGFloat = 1.0
        
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
