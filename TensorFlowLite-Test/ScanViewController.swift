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
    // MARK: Controllers that manage functionality
    private lazy var cameraFeedManager = CameraFeedManager(previewView: previewView)
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cameraFeedManager.delegate = self
        
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
      super.viewWillAppear(animated)
        
      cameraFeedManager.checkCameraConfigurationAndStartSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)

      cameraFeedManager.stopSession()
    }

    @IBAction func closeAction(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }

}

// MARK: CameraFeedManagerDelegate Methods
extension ScanViewController: CameraFeedManagerDelegate {

  func didOutput(pixelBuffer: CVPixelBuffer) {
//    runModel(onPixelBuffer: pixelBuffer)
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

}
