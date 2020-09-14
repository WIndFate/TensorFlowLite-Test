//
//  VideoViewController.swift
//  TensorFlowLite-Test
//
//  Created by Shi Jiachen on 2020/08/14.
//  Copyright © 2020 WIndFate. All rights reserved.
//

import UIKit

class VideoViewController: UIViewController {

    @IBOutlet weak var containerView: UIImageView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    var player = ZFPlayerController()
    var assetURLs : [URL] = []
    var allRects : [Any] = []
    var oriImage : UIImage?
    lazy var controlView : ZFPlayerControlView = {
        
        let controlView = ZFPlayerControlView()
        controlView.fastViewAnimated = true;
        controlView.autoHiddenTimeInterval = 5;
        controlView.autoFadeTimeInterval = 0.5;
        controlView.prepareShowLoading = true;
        controlView.prepareShowControlView = true;
        
        return controlView
    }()
    
    private var topModelHandler: ModelDataHandler?
    private var bottomModelHandler: ModelDataHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        containerView.addSubview(playBtn)
        containerView.image = UIImage.init(named: "videobg")
        
        let playerManager = ZFAVPlayerManager()
        player = ZFPlayerController.init(playerManager: playerManager, containerView: containerView)
        player.controlView = controlView
        player.pauseWhenAppResignActive = false;
        
        let path = Bundle.main.path(forResource: "IMG_0600", ofType: "mp4")
        assetURLs.append(URL.init(fileURLWithPath: path!))
        player.assetURLs = assetURLs;
        
        topModelHandler = ModelDataHandler(modelFileInfo: MobileNet.topNumberModelInfo, labelsFileInfo: MobileNet.labelsInfo)
        
        guard topModelHandler != nil else {
          fatalError("Top Model set up failed")
        }
        
        bottomModelHandler = ModelDataHandler(modelFileInfo: MobileNet.bottomNumberModelInfo, labelsFileInfo: MobileNet.labelsInfo)
        
        guard bottomModelHandler != nil else {
          fatalError("Bottom Model set up failed")
        }
    }
    

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        player.isViewControllerDisappear = false;
        
        self.playClick((Any).self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player.isViewControllerDisappear = true;
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        if player.isFullScreen {
            return .lightContent;
        }
        return .default;
    }
    
    override var prefersStatusBarHidden: Bool {
        return true;
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    override var shouldAutorotate: Bool {
        return player.shouldAutorotate
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if (self.player.isFullScreen && self.player.orientationObserver.fullScreenMode == .landscape) {
            return .landscape;
        }
        return .portrait;
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        guard segue.identifier == "PlateNumberDetailsViewController" else {
            return
        }
        
        if oriImage == nil {
            return
        }
        
        let opencvCls = CVViewController()
        let topRect = allRects.first
        let bottomRect = allRects.last
        let cls = segue.destination as! PlateNumberDetailsViewController
        
        var topCutImage : UIImage
        var bottomCutImage : UIImage
        
        if topRect is String {
            cls.imageArr.append(topRect as Any)
        }else {
            topCutImage = opencvCls.clipImage(oriImage, bgImageSize: "160x32", withCurrentRects: (allRects.first as! [Any]))
            cls.imageArr.append(topCutImage)
        }
        
        if bottomRect is String {
            cls.imageArr.append(bottomRect as Any)
        }else {
            bottomCutImage = opencvCls.clipImage(oriImage, bgImageSize: "160x32", withCurrentRects: (allRects.last as! [Any]))
            cls.imageArr.append(bottomCutImage)
        }
        
//        let test = CVViewController()
//        test.saveImage(cls.image)
    }
    
    func clearAllUserDefaultsData() {
        
        let userDefaults = UserDefaults.standard
        let dics = userDefaults.dictionaryRepresentation()
        for key in dics {
            userDefaults.removeObject(forKey: key.key)
            
        }
        userDefaults.synchronize()
    }
    
    func getBoxRectsResult(image : UIImage, isTopModel : Bool) {
        
        let start = CFAbsoluteTimeGetCurrent()

        var result : Result?;
        if isTopModel {
            result = self.topModelHandler!.runModel(withImage: image)
        }else {
            result = self.bottomModelHandler!.runModel(withImage: image)
        }
        
        let end = CFAbsoluteTimeGetCurrent()

        print("barCode time  == \(end - start)")
        
        guard let rect = CVViewController.findRects(image, withData: result!.dataResult) else {

            print("no result")
            return
        }
        
        if rect.count == 0 {
            
            print("rect count = 0")
            allRects.append("No Image")
            return
        }
        
        rect.forEach { allRects.append($0)}
        
    }
    
    @IBAction func playClick(_ sender: Any) {
        
        player.playTheIndex(0)
        controlView.showTitle("テスト", cover: UIImage.init(named: "videobg"), fullScreenMode: .landscape)
    }
    
    @IBAction func findRectangle(_ sender: Any) {
        
        SVProgressHUD.show(withStatus: "認識中...")
        
        allRects.removeAll()
        imageView.image = nil
        oriImage = nil
        //是否处理图片时暂停视频
        player.isPauseByEvent = true
        player.currentPlayerManager.thumbnailImage?(atCurrentTime: { (image : UIImage) in
            
            DispatchQueue.main.async {
                //视频一帧原图
                let showImge = image.imageRotatedByDegrees(degrees: 90.0).scaledImage(with: CGSize(width: 512.0, height: 768.0))!
//                let showImge = UIImage(named: "56438")!.scaledImage(with: CGSize(width: 512.0, height: 768.0))!
                self.oriImage = showImge
                //top model result
                self.getBoxRectsResult(image: showImge, isTopModel: true)
                
                //bottom model result
                self.getBoxRectsResult(image: showImge, isTopModel: false)
                
                guard let finalImageArr = CVViewController.drawBox(showImge, withRects: self.allRects) else {

                    print("no finalImage")
                    return
                }
                
                self.imageView.image = (finalImageArr.first as! UIImage)
                
                let opencvCls = CVViewController()
                let topRect = self.allRects.first
                let bottomRect = self.allRects.last
                guard let cls = self.storyboard?.instantiateViewController(withIdentifier: String(describing: type(of: PlateNumberDetailsViewController()))) as! PlateNumberDetailsViewController? else {
                    
                    return
                }
                
                cls.resultImage = self.imageView.image!
                var topCutImage : UIImage
                var bottomCutImage : UIImage
                
                if topRect is String {
                    cls.imageArr.append(topRect as Any)
                }else {
                    topCutImage = opencvCls.clipImage(self.oriImage, bgImageSize: "160x32", withCurrentRects: (self.allRects.first as! [Any]))
                    cls.imageArr.append(topCutImage)
                }
                
                if bottomRect is String {
                    cls.imageArr.append(bottomRect as Any)
                }else {
                    bottomCutImage = opencvCls.clipImage(self.oriImage, bgImageSize: "160x32", withCurrentRects: (self.allRects.last as! [Any]))
                    cls.imageArr.append(bottomCutImage)
                }
                
                SVProgressHUD.dismiss()
                
                self.navigationController?.pushViewController(cls, animated: true)

            }
        })
        
    }
}
