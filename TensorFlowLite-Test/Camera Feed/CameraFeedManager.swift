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
import AVFoundation

// MARK: CameraFeedManagerDelegate Declaration
protocol CameraFeedManagerDelegate: class {

  /**
   This method delivers the Photo of the current frame seen by the device's camera.
  */
  func didOutputPhotoCapture(image: UIImage)
    
  /**
   This method delivers the pixel buffer of the current frame seen by the device's camera.
   */
  func didOutput(pixelBuffer: CVPixelBuffer)

  /**
   This method initimates that the camera permissions have been denied.
   */
  func presentCameraPermissionsDeniedAlert()

  /**
   This method initimates that there was an error in video configurtion.
   */
  func presentVideoConfigurationErrorAlert()

  /**
   This method initimates that a session runtime error occured.
   */
  func sessionRunTimeErrorOccured()

  /**
   This method initimates that the session was interrupted.
   */
  func sessionWasInterrupted(canResumeManually resumeManually: Bool)

  /**
   This method initimates that the session interruption has ended.
   */
  func sessionInterruptionEnded()

}

/**
 This enum holds the state of the camera initialization.
 */
enum CameraConfiguration {

  case success
  case failed
  case permissionDenied
}

enum CameraMode {

  case video
  case photo
  case photo2x
}

/**
 This class manages all camera related functionality
 */
class CameraFeedManager: NSObject {

  // MARK: Camera Related Instance Variables
  private let session: AVCaptureSession = AVCaptureSession()
  private let previewView: AITeamPreviewView
  private let sessionQueue = DispatchQueue(label: "sessionQueue")
  private var cameraConfiguration: CameraConfiguration = .failed
  var cameraMode: CameraMode = .video
  private lazy var videoDataOutput = AVCaptureVideoDataOutput()
  private lazy var photoOutput = AVCapturePhotoOutput()
  private var isSessionRunning = false

  // MARK: CameraFeedManagerDelegate
  weak var delegate: CameraFeedManagerDelegate?

  // MARK: Initializer
  init(previewView: AITeamPreviewView) {
    self.previewView = previewView
    super.init()

    // Initializes the session
    session.sessionPreset = .high
    self.previewView.session = session
    self.previewView.previewLayer.connection?.videoOrientation = .portrait
    self.previewView.previewLayer.videoGravity = .resizeAspectFill
    self.attemptToConfigureSession()
  }

  // MARK: Session Start and End methods

  /**
   This method starts an AVCaptureSession based on whether the camera configuration was successful.
   */
  func checkCameraConfigurationAndStartSession() {
    sessionQueue.async {
      switch self.cameraConfiguration {
      case .success:
        self.addObservers()
        self.startSession()
      case .failed:
        DispatchQueue.main.async {
          self.delegate?.presentVideoConfigurationErrorAlert()
        }
      case .permissionDenied:
        DispatchQueue.main.async {
          self.delegate?.presentCameraPermissionsDeniedAlert()
        }
      }
    }
  }

  /**
   This method stops a running an AVCaptureSession.
   */
  func stopSession() {
    self.removeObservers()
    sessionQueue.async {
      if self.session.isRunning {
        self.session.stopRunning()
        self.isSessionRunning = self.session.isRunning
      }
    }

  }

  /**
   This method resumes an interrupted AVCaptureSession.
   */
  func resumeInterruptedSession(withCompletion completion: @escaping (Bool) -> ()) {

    sessionQueue.async {
      self.startSession()

      DispatchQueue.main.async {
        completion(self.isSessionRunning)
      }
    }
  }

  /**
   This method starts the AVCaptureSession
   **/
  private func startSession() {
    self.session.startRunning()
    self.isSessionRunning = self.session.isRunning
  }
    
    func getPhotoCapture() {
      
        var photoSetting : AVCapturePhotoSettings?
        photoSetting = AVCapturePhotoSettings(format: [AVVideoCodecKey:AVVideoCodecType.jpeg])
        if let setting = photoSetting{
            
            photoOutput.capturePhoto(with: setting, delegate: self)
        }
    }

  func turnOnLight() {
    
    guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
        return
    }
    if device.hasTorch && device.isTorchAvailable{
        
        try? device.lockForConfiguration()
        device.torchMode = .on
        device.unlockForConfiguration()

    }
  }
    
  func turnOffLight() {
    
    guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
        return
    }
    if device.hasTorch && device.isTorchAvailable{
        
        try? device.lockForConfiguration()
        device.torchMode = .off
        device.unlockForConfiguration()

    }
  }

  // MARK: Session Configuration Methods.
  /**
   This method requests for camera permissions and handles the configuration of the session and stores the result of configuration.
   */
  private func attemptToConfigureSession() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      self.cameraConfiguration = .success
    case .notDetermined:
      self.sessionQueue.suspend()
      self.requestCameraAccess(completion: { (granted) in
        self.sessionQueue.resume()
      })
    case .denied:
      self.cameraConfiguration = .permissionDenied
    default:
      break
    }

    self.sessionQueue.async {
      self.configureSession()
    }
  }

  /**
   This method requests for camera permissions.
   */
  private func requestCameraAccess(completion: @escaping (Bool) -> ()) {
    AVCaptureDevice.requestAccess(for: .video) { (granted) in
      if !granted {
        self.cameraConfiguration = .permissionDenied
      }
      else {
        self.cameraConfiguration = .success
      }
      completion(granted)
    }
  }


  /**
   This method handles all the steps to configure an AVCaptureSession.
   */
  private func configureSession() {

    guard cameraConfiguration == .success else {
      return
    }
    session.beginConfiguration()

    // Tries to add an AVCaptureDeviceInput.
    guard addVideoDeviceInput() == true else {
      self.session.commitConfiguration()
      self.cameraConfiguration = .failed
      return
    }

    switch cameraMode {
    case .video: do {
        
        guard addVideoDataOutput() else {
          self.session.commitConfiguration()
          self.cameraConfiguration = .failed
          return
        }
        
        }
    case .photo,.photo2x: do {
        
        guard addCapturePhotoOutput() else {
          self.session.commitConfiguration()
          self.cameraConfiguration = .failed
          return
        }
        
        }
    }
    // Tries to add an AVCaptureVideoDataOutput.
    

    session.commitConfiguration()
    self.cameraConfiguration = .success
  }

  /**
   This method tries to an AVCaptureDeviceInput to the current AVCaptureSession.
   */
  private func addVideoDeviceInput() -> Bool {

    /**Tries to get the default back camera.
     */
    guard let camera  = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
      fatalError("Cannot find camera")
    }

    do {
      let videoDeviceInput = try AVCaptureDeviceInput(device: camera)
      if session.canAddInput(videoDeviceInput) {
        session.addInput(videoDeviceInput)
        
        if cameraMode == .photo2x {
            
            do {
                try videoDeviceInput.device.lockForConfiguration()
                defer { videoDeviceInput.device.unlockForConfiguration() }
                videoDeviceInput.device.videoZoomFactor = 2.0
                
                } catch {
                    debugPrint(error)
                }
        }
        
        return true
      }
      else {
        return false
      }
    }
    catch {
      fatalError("Cannot create video device input")
    }
  }

  /**
   This method tries to an AVCaptureVideoDataOutput to the current AVCaptureSession.
   */
  private func addVideoDataOutput() -> Bool {

    let sampleBufferQueue = DispatchQueue(label: "sampleBufferQueue")
    videoDataOutput.setSampleBufferDelegate(self, queue: sampleBufferQueue)
    videoDataOutput.alwaysDiscardsLateVideoFrames = true
    videoDataOutput.videoSettings = [ String(kCVPixelBufferPixelFormatTypeKey) : kCMPixelFormat_32BGRA]

    if session.canAddOutput(videoDataOutput) {
      session.addOutput(videoDataOutput)
      videoDataOutput.connection(with: .video)?.videoOrientation = .portrait
      return true
    }
    return false
  }
    
    private func addCapturePhotoOutput() -> Bool {

        if session.canAddOutput(photoOutput as AVCaptureOutput)==true{
            
            session.addOutput(photoOutput as AVCaptureOutput)
            photoOutput.connection(with: .video)?.videoOrientation = .portrait
            return true
        }
      return false
    }

  // MARK: Notification Observer Handling
  private func addObservers() {
    NotificationCenter.default.addObserver(self, selector: #selector(CameraFeedManager.sessionRuntimeErrorOccured(notification:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
    NotificationCenter.default.addObserver(self, selector: #selector(CameraFeedManager.sessionWasInterrupted(notification:)), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
    NotificationCenter.default.addObserver(self, selector: #selector(CameraFeedManager.sessionInterruptionEnded), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
  }

  private func removeObservers() {
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
    NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
  }

  // MARK: Notification Observers
  @objc func sessionWasInterrupted(notification: Notification) {

    if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
      let reasonIntegerValue = userInfoValue.integerValue,
      let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
      print("Capture session was interrupted with reason \(reason)")

      var canResumeManually = false
      if reason == .videoDeviceInUseByAnotherClient {
        canResumeManually = true
      } else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
        canResumeManually = false
      }

      self.delegate?.sessionWasInterrupted(canResumeManually: canResumeManually)

    }
  }

  @objc func sessionInterruptionEnded(notification: Notification) {

    self.delegate?.sessionInterruptionEnded()
  }

  @objc func sessionRuntimeErrorOccured(notification: Notification) {
    guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else {
      return
    }

    print("Capture session runtime error: \(error)")

    if error.code == .mediaServicesWereReset {
      sessionQueue.async {
        if self.isSessionRunning {
          self.startSession()
        } else {
          DispatchQueue.main.async {
            self.delegate?.sessionRunTimeErrorOccured()
          }
        }
      }
    } else {
      self.delegate?.sessionRunTimeErrorOccured()

    }
  }
}


/**
 AVCaptureVideoDataOutputSampleBufferDelegate
 */
extension CameraFeedManager: AVCaptureVideoDataOutputSampleBufferDelegate {

  /** This method delegates the CVPixelBuffer of the frame seen by the camera currently.
   */
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

    // Converts the CMSampleBuffer to a CVPixelBuffer.
    let pixelBuffer: CVPixelBuffer? = CMSampleBufferGetImageBuffer(sampleBuffer)

    guard let imagePixelBuffer = pixelBuffer else {
      return
    }

    // Delegates the pixel buffer to the ViewController.
    delegate?.didOutput(pixelBuffer: imagePixelBuffer)
  }

}

extension CameraFeedManager: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        
        if let soundURL = Bundle.main.url(forResource: "photoShutter2", withExtension: "caf") {
            var mySound: SystemSoundID = 0
            AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
            AudioServicesPlaySystemSound(mySound);
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?){

        let imageData = photo.fileDataRepresentation()

        guard let image = UIImage(data:  imageData!) else {
          return
        }

        // Delegates the pixel buffer to the ViewController.
        delegate?.didOutputPhotoCapture(image: image)

    }
    
//    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
//
//        print(photoSampleBuffer as Any)
//    }
    
}
