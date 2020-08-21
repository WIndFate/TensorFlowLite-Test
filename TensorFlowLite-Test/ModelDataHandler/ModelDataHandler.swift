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

import CoreImage
import TensorFlowLite
import UIKit
import Accelerate

/// A result from invoking the `Interpreter`.
struct Result {
  let tensor: Tensor
  let dataResult: [Float]
  let inferences: [Inference]?
}

struct Inference {
  let confidence: Float
  let label: String
}

/// Information about a model file or labels file.
typealias FileInfo = (name: String, extension: String)

/// Information about the MobileNet model.
enum MobileNet {
    static let testModelInfo: FileInfo = (name: "rental_model_sized_big", extension: "tflite")
    static let barCodeModelInfo: FileInfo = (name: "barcode_model_768_512_even_shallower", extension: "tflite")
    static let ocrModelInfo: FileInfo = (name: "ocr_barcode_model_99_accu", extension: "tflite")
    static let labelsInfo: FileInfo = (name: "labelsMap", extension: "txt")
    static let plateNumberOcrModelInfo: FileInfo = (name: "plate_number_ocr_model_input_sized", extension: "tflite")
    static let plateNumberLabelsInfo: FileInfo = (name: "plateNumberLabelsMap", extension: "txt")
    static let topNumberModelInfo: FileInfo = (name: "plate_number_top_768_512", extension: "tflite")
    static let bottomNumberModelInfo: FileInfo = (name: "plate_number_bottom_768_512", extension: "tflite")
}

/// This class handles all data preprocessing and makes calls to run inference on a given frame
/// by invoking the `Interpreter`. It then formats the inferences obtained and returns the top N
/// results for a successful inference.
class ModelDataHandler {

  // MARK: - Internal Properties

  /// The current thread count used by the TensorFlow Lite Interpreter.
  let threadCount: Int

  let resultCount = 1
  let threadCountLimit = 10

  // MARK: - Model Parameters
    
  var batchSize : Int
  var inputChannels : Int
  var inputWidth : Int
  var inputHeight : Int
    
  var ocrLabelTotal = 1

  // MARK: - Private Properties

  /// List of labels from the given labels file.
  private var labels: [String] = []
    
  /// TensorFlow Lite `Interpreter` object for performing inference on a given model.
  private var interpreter: Interpreter

  /// Information about the alpha component in RGBA data.
  private let alphaComponent = (baseOffset: 4, moduloRemainder: 3)

  // MARK: - Initialization

  /// A failable initializer for `ModelDataHandler`. A new instance is created if the model and
  /// labels files are successfully loaded from the app's main bundle. Default `threadCount` is 1.
  init?(modelFileInfo: FileInfo, labelsFileInfo: FileInfo, threadCount: Int = 1) {
    
    var modelFilename : String
    
    modelFilename = modelFileInfo.name
    
    if modelFilename == "barcode_model_768_512_even_shallower" || modelFilename == "plate_number_top_768_512" || modelFilename == "plate_number_bottom_768_512"{
        
        self.batchSize = 1
        self.inputChannels = 3
        self.inputWidth = 512
        self.inputHeight = 768
        
    }else if modelFilename == "ocr_barcode_model_99_accu" {
        
        self.batchSize = 1
        self.inputChannels = 3
        self.inputWidth = 32
        self.inputHeight = 256
        self.ocrLabelTotal = 37
        
    }else if modelFilename == "plate_number_ocr_model_input_sized" {
        
        self.batchSize = 1
        self.inputChannels = 3
        self.inputWidth = 32
        self.inputHeight = 160
        self.ocrLabelTotal = 15
        
    }else {
        
        self.batchSize = 1
        self.inputChannels = 3
        self.inputWidth = 1280
        self.inputHeight = 1792
    }

    // Construct the path to the model file.
    guard let modelPath = Bundle.main.path(
      forResource: modelFilename,
      ofType: modelFileInfo.extension
    ) else {
      print("Failed to load the model file with name: \(modelFilename).")
      return nil
    }

    // Specify the options for the `Interpreter`.
    self.threadCount = threadCount
    var options = Interpreter.Options()
    options.threadCount = threadCount
    do {
      // Create the `Interpreter`.
      interpreter = try Interpreter(modelPath: modelPath, options: options)
      // Allocate memory for the model's input `Tensor`s.
      try interpreter.allocateTensors()
    } catch let error {
      print("Failed to create the interpreter with error: \(error.localizedDescription)")
      return nil
    }
    
    if modelFilename == "ocr_barcode_model_99_accu" || modelFilename == "plate_number_ocr_model_input_sized" {
        
        // Load the classes listed in the labels file.
        loadLabels(fileInfo: labelsFileInfo)
        
    }
  }

  // MARK: - Internal Methods

  /// Performs image preprocessing, invokes the `Interpreter`, and processes the inference results.
    func runModel(withImage image: UIImage, isOcrModel: Bool = false) -> Result? {
        
        let outputTensor: Tensor
        var topNInferences = [Inference]()
        do {
          let inputTensor = try interpreter.input(at: 0)
            
            // Remove the alpha component from the image buffer to get the RGB data.
//            guard let rgbData = image.scaledData(
//              with: CGSize(width: inputWidth, height: inputHeight),
//              byteCount: batchSize * inputWidth * inputHeight * inputChannels,
//              isQuantized: inputTensor.dataType == .uInt8
//            ) else {
//              print("Failed to convert the image buffer to RGB data.")
//              return nil
//            }
            
            let pixelBuffer = CVPixelBuffer.buffer(from: image.scaledImage(with: CGSize(width: inputWidth, height: inputHeight))!)!
            guard let rgbData = rgbDataFromBuffer(
              pixelBuffer,
              byteCount: batchSize * inputWidth * inputHeight * inputChannels,
              isModelQuantized: inputTensor.dataType == .uInt8
            ) else {
              print("Failed to convert the image buffer to RGB data.")
              return nil
            }

          // Copy the RGB data to the input `Tensor`.
          try interpreter.copy(rgbData, toInputAt: 0)

          // Run inference by invoking the `Interpreter`.
          let start = CFAbsoluteTimeGetCurrent()

          try interpreter.invoke()
            
          let end = CFAbsoluteTimeGetCurrent()

          print("invoke time  == \(end - start)")

          // Get the output `Tensor` to process the inference results.
          outputTensor = try interpreter.output(at: 0)
        } catch let error {
          print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
          return nil
        }
        
        var results: [Float]
        switch outputTensor.dataType {
        case .uInt8:
          guard let quantization = outputTensor.quantizationParameters else {
            print("No results returned because the quantization values for the output tensor are nil.")
            return nil
          }
          let quantizedResults = [UInt8](outputTensor.data)
          results = quantizedResults.map {
            quantization.scale * Float(Int($0) - quantization.zeroPoint)
          }
        case .float32:
          results = [Float32](unsafeData: outputTensor.data) ?? []
        default:
          print("Output tensor data type \(outputTensor.dataType) is unsupported for this example app.")
          return nil
        }
        
        // Process the results.
        if isOcrModel {
            topNInferences = getTopN(results: results, total: ocrLabelTotal)
        }
        
        // Return the inference time and inference results.
        return Result(tensor: outputTensor, dataResult: results, inferences: topNInferences)
      }
    
  func runModel(withBuffer pixelBuffer: CVPixelBuffer, isOcrModel: Bool = false) -> Result? {

    let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
    assert(sourcePixelFormat == kCVPixelFormatType_32ARGB ||
             sourcePixelFormat == kCVPixelFormatType_32BGRA ||
               sourcePixelFormat == kCVPixelFormatType_32RGBA)

    var topNInferences = [Inference]()
    let imageChannels = 4
    assert(imageChannels >= inputChannels)

    // Crops the image to the biggest square in the center and scales it down to model dimensions.
//    let scaledSize = CGSize(width: inputWidth, height: inputHeight)
//    guard let thumbnailPixelBuffer = pixelBuffer.centerThumbnail(ofSize: scaledSize) else {
//      return nil
//    }

    let outputTensor: Tensor
    do {
      let inputTensor = try interpreter.input(at: 0)

      // Remove the alpha component from the image buffer to get the RGB data.
      guard let rgbData = rgbDataFromBuffer(
        pixelBuffer,
        byteCount: batchSize * inputWidth * inputHeight * inputChannels,
        isModelQuantized: inputTensor.dataType == .uInt8
      ) else {
        print("Failed to convert the image buffer to RGB data.")
        return nil
      }

      // Copy the RGB data to the input `Tensor`.
      try interpreter.copy(rgbData, toInputAt: 0)

      // Run inference by invoking the `Interpreter`.
      try interpreter.invoke()

      // Get the output `Tensor` to process the inference results.
      outputTensor = try interpreter.output(at: 0)
    } catch let error {
      print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
      return nil
    }

    var results: [Float]
    switch outputTensor.dataType {
    case .uInt8:
      guard let quantization = outputTensor.quantizationParameters else {
        print("No results returned because the quantization values for the output tensor are nil.")
        return nil
      }
      let quantizedResults = [UInt8](outputTensor.data)
      results = quantizedResults.map {
        quantization.scale * Float(Int($0) - quantization.zeroPoint)
      }
    case .float32:
      results = [Float32](unsafeData: outputTensor.data) ?? []
    default:
      print("Output tensor data type \(outputTensor.dataType) is unsupported for this example app.")
      return nil
    }

    // Process the results.
    if isOcrModel {
        topNInferences = getTopN(results: results, total: ocrLabelTotal)
    }
    
    // Return the inference time and inference results.
    return Result(tensor: outputTensor, dataResult: results, inferences: topNInferences)
  }

  /// Returns the top N inference results sorted in descending order.
    private func getTopN(results: [Float], total: Int) -> [Inference] {
    
    var confidenceArr = [Inference]()
    var resultArr = [Inference]()
    var tempArr = [Float]()
    
    //拆分成每组包含37个元素的小数组
    for (index,_) in results.enumerated() {
        
        tempArr.append(results[index])
        if (index + 1) % total == 0 {
            
            let zippedResults = zip(labels.indices, tempArr)
            
            let sortedResults = zippedResults.sorted { $0.1 > $1.1 }.prefix(resultCount)
            
            confidenceArr.append(contentsOf: sortedResults.map { result in Inference(confidence: result.1, label: labels[result.0]) })
            tempArr.removeAll()
        }
    }
    
    //去除每个小数组相邻重复元素
    for (index,value) in confidenceArr.enumerated() {
        
        if index > 0 {
            
            if value.label != resultArr.last?.label {

                resultArr.append(value)
                
                }
        }
        else{
            resultArr.append(value)
        }
    }

    // Return the `Inference` results.
    return resultArr.filter { $0.label != "" }
  }
    
  /// Loads the labels from the labels file and stores them in the `labels` property.
  private func loadLabels(fileInfo: FileInfo) {
    let filename = fileInfo.name
    let fileExtension = fileInfo.extension
    guard let fileURL = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
      fatalError("Labels file not found in bundle. Please add a labels file with name " +
                   "\(filename).\(fileExtension) and try again.")
    }
    do {
      let contents = try String(contentsOf: fileURL, encoding: .utf8)
      labels = contents.components(separatedBy: .newlines)
    } catch {
      fatalError("Labels file named \(filename).\(fileExtension) cannot be read. Please add a " +
                   "valid labels file and try again.")
    }
  }
    
    
  // MARK: - Private Methods

  /// Returns the RGB data representation of the given image buffer with the specified `byteCount`.
  ///
  /// - Parameters
  ///   - buffer: The pixel buffer to convert to RGB data.
  ///   - byteCount: The expected byte count for the RGB data calculated using the values that the
  ///       model was trained on: `batchSize * imageWidth * imageHeight * componentsCount`.
  ///   - isModelQuantized: Whether the model is quantized (i.e. fixed point values rather than
  ///       floating point values).
  /// - Returns: The RGB data representation of the image buffer or `nil` if the buffer could not be
  ///     converted.
  private func rgbDataFromBuffer(
    _ buffer: CVPixelBuffer,
    byteCount: Int,
    isModelQuantized: Bool
  ) -> Data? {
    CVPixelBufferLockBaseAddress(buffer, .readOnly)
    defer {
      CVPixelBufferUnlockBaseAddress(buffer, .readOnly)
    }
    guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else {
      return nil
    }
    
    let width = CVPixelBufferGetWidth(buffer)
    let height = CVPixelBufferGetHeight(buffer)
    let sourceBytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
    let destinationChannelCount = 3
    let destinationBytesPerRow = destinationChannelCount * width
    
    var sourceBuffer = vImage_Buffer(data: sourceData,
                                     height: vImagePixelCount(height),
                                     width: vImagePixelCount(width),
                                     rowBytes: sourceBytesPerRow)
    
    guard let destinationData = malloc(height * destinationBytesPerRow) else {
      print("Error: out of memory")
      return nil
    }
    
    defer {
        free(destinationData)
    }

    var destinationBuffer = vImage_Buffer(data: destinationData,
                                          height: vImagePixelCount(height),
                                          width: vImagePixelCount(width),
                                          rowBytes: destinationBytesPerRow)

    let pixelBufferFormat = CVPixelBufferGetPixelFormatType(buffer)

    switch (pixelBufferFormat) {
    case kCVPixelFormatType_32BGRA:
        vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    case kCVPixelFormatType_32ARGB:
        vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    case kCVPixelFormatType_32RGBA:
        vImageConvert_RGBA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
    default:
        // Unknown pixel format.
        return nil
    }

    let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
    if isModelQuantized {
        return byteData
    }

    // Not quantized, convert to floats
    let bytes = Array<UInt8>(unsafeData: byteData)!
    var floats = [Float]()
//    for i in 0..<bytes.count {
//        floats.append(Float(bytes[i]) / 1.0)
//    }
    if width == 32 {
        
        for i in 0..<bytes.count {
            floats.append(Float(bytes[i]) / 255.0)
        }
        
    }else {
        for i in 0..<bytes.count {
            floats.append(Float(bytes[i]) / 1.0)
        }
    }
    
//    let cls = CVViewController()
//    cls.write(toCsv: floats)
    return Data(copyingBufferOf: floats)
  }
}

// MARK: - Extensions

extension Data {
  /// Creates a new buffer by copying the buffer pointer of the given array.
  ///
  /// - Warning: The given array's element type `T` must be trivial in that it can be copied bit
  ///     for bit with no indirection or reference-counting operations; otherwise, reinterpreting
  ///     data from the resulting buffer has undefined behavior.
  /// - Parameter array: An array with elements of type `T`.
  init<T>(copyingBufferOf array: [T]) {
    self = array.withUnsafeBufferPointer(Data.init)
  }
}

extension Array {
  /// Creates a new array from the bytes of the given unsafe data.
  ///
  /// - Warning: The array's `Element` type must be trivial in that it can be copied bit for bit
  ///     with no indirection or reference-counting operations; otherwise, copying the raw bytes in
  ///     the `unsafeData`'s buffer to a new array returns an unsafe copy.
  /// - Note: Returns `nil` if `unsafeData.count` is not a multiple of
  ///     `MemoryLayout<Element>.stride`.
  /// - Parameter unsafeData: The data containing the bytes to turn into an array.
  init?(unsafeData: Data) {
    guard unsafeData.count % MemoryLayout<Element>.stride == 0 else { return nil }
    #if swift(>=5.0)
    self = unsafeData.withUnsafeBytes { .init($0.bindMemory(to: Element.self)) }
    #else
    self = unsafeData.withUnsafeBytes {
      .init(UnsafeBufferPointer<Element>(
        start: $0,
        count: unsafeData.count / MemoryLayout<Element>.stride
      ))
    }
    #endif  // swift(>=5.0)
  }
}

