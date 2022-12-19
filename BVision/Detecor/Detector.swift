//
//  Detector.swift
//  BVision
//
//  Created by gitaeklee on 12/5/22.
//

import Vision
import AVFoundation
import UIKit
import CoreFoundation

extension ViewController {
    
    func setupDetector() {
        /*
         VNCoreMLModel: A container for a Core ML model used with Vision requests.
             ** class VNCoreMLModel : NSObject
             - init(for: MLModel)
                Creates a model container to be used with VNCoreMLRequest.
             - init(model: VNCoreMLModel)
                Creates a model container to be used with VNCoreMLRequest based on a Core ML model.
         
             - var featureProvider: MLFeatureProvider?
                An optional object to support inputs outside Vision.
             - var inputImageFeatureName: String
                The name of the MLFeatureValue that Vision sets from the request handler.
         
         VNCoreMLRequest
             * VNRequest
                - The abstract superclass for analysis requests.
         
                Canceling a Request
                 - func cancel()
                    Cancels the request before it can finish executing.
         
                Type Alias
                    VNRequestCompletionHandler
                    ** typealias VNRequestCompletionHandler = (VNRequest, Error?) -> Void
                    - A type alias to encapsulate the syntax for the completion handler block that's invoked after the request has finished processing.
         
            ** class VNImageBasedRequest : VNRequest
                - The abstract superclass for image analysis requests that focus on a specific part of an image.
                - Other Vision request handlers that operate on still images inherit from this abstract base class. Don’t use it directly.
            ** class VNCoreMLRequest : VNImageBasedRequest
                - An image analysis request that uses a Core ML model to process images.
         
            - init(model: VNCoreMLModel, completionHandler: VNRequestCompletionHandler?)
                Creates a model container to be used with VNCoreMLRequest based on a Core ML model,
                with an optional completion handler.

         
         */
        let modelURL = Bundle.main.url(forResource: "yolov7", withExtension: "mlmodelc")
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            /*
             Parameters
                model
                    The Core ML model on which to base the Vision request.
                completionHandler
                    An optional block of code to execute after model initialization
             */
            self.requests = [recognitions]
            // [VNRequest]() (recognitions == VNRequest)
        } catch let error {
            print(error)
        }
    }
    
    func setupTextTracker() {
        // TODO: VNTextObservation > SwiftOCR
    }
    
    func setupSignalTracker() {
        let modelURL = Bundle.main.url(forResource: "yolov5sTraffic", withExtension: "mlmodelc")
        do {
            let visionModel = try VNCoreMLModel(for: MLModel(contentsOf: modelURL!))
            let recognitions = VNCoreMLRequest(model: visionModel, completionHandler: detectionDidComplete)
            /*
             Parameters
                model
                    The Core ML model on which to base the Vision request.
                completionHandler
                    An optional block of code to execute after model initialization
             */
            self.requests = [recognitions]
            // [VNRequest]() (recognitions == VNRequest)
        } catch let error {
            print(error)
        }
    }

    func detectionDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async(execute: {
            if let results = request.results {
                self.extractDetections(results)
            }
        })
    }

    func extractDetections(_ results: [VNObservation]) {
        detectionLayer.sublayers = nil
        
        for observation in results where observation is VNRecognizedObjectObservation {
            /*
                 Class
                 VNRecognizedObjectObservation
                 - A detected object observation with an array of classification labels that classify the recognized object.
             */
            guard let objectObservation = observation as? VNRecognizedObjectObservation else { continue }
            
            let topLabelObservation = objectObservation.labels[0]

            firstLabel = topLabelObservation.identifier
            firstConfidence = topLabelObservation.confidence
            
            let objectBounds = VNImageRectForNormalizedRect(objectObservation.boundingBox, Int(screenRect.size.width), Int(screenRect.size.height))
            /*
             VNImageRectForNormalizedRect
             
                parameters
             
                func VNImageRectForNormalizedRect(
                     _ normalizedRect: CGRect,
                     _ imageWidth: Int,
                     _ imageHeight: Int
                 ) -> CGRect
             
                Return Value
                The input rect projected into image (pixel) coordinates.
             
                - var boundingBox: CGRect
                    The bounding box of the object that the request detects.
             **/
            let transformedBounds = CGRect(x: objectBounds.minX, y: screenRect.size.height - objectBounds.maxY, width: objectBounds.maxX - objectBounds.minX, height: objectBounds.maxY - objectBounds.minY)
            print("acc : \(firstConfidence) , \(firstLabel)")
            
            if firstLabel == "car" || firstLabel == "person" || firstLabel == "bus" {
                if firstConfidence >= 0.8 {
                    let boxLayer = self.drawBoundingBox(transformedBounds, firstLabel)
                    detectionLayer.addSublayer(boxLayer)
                }
            } else if firstLabel == "traffic_light_green" || firstLabel == "traffic_light_red" {
                if firstConfidence >= 0.8 {
                    let boxLayer = self.drawBoundingBox(transformedBounds, firstLabel)
                    detectionLayer.addSublayer(boxLayer)
                }
            } else if firstLabel == "stop sign" && firstConfidence >= 0.9 {
                let boxLayer = self.drawBoundingBox(transformedBounds, firstLabel)
                detectionLayer.addSublayer(boxLayer)
            }
            
        }
    }
    
    func setupLayers() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        self.view.layer.addSublayer(detectionLayer)
    }
    
    func updateLayers() {
        detectionLayer?.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
    }
    
    func drawBoundingBox(_ bounds: CGRect, _ label: String) -> CALayer {
        let boxLayer = CALayer()
        let textLayer = CATextLayer()
        textLayer.name = "Object Label"
        textLayer.backgroundColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1.0)
  
        let font = UIFont.systemFont(ofSize: 15)
        let colour = UIColor.black.cgColor
        
        // Place the labels
        let labelHeight: CGFloat = 20.0
        let yPosOffset: CGFloat = 10.0
        
        let attribute = [NSAttributedString.Key.font: font, NSAttributedString.Key.foregroundColor: colour] as [NSAttributedString.Key : Any]
        let formattedString = NSMutableAttributedString(string: String(format: "\(label)"), attributes: attribute)
        textLayer.string = formattedString
        
        let boxWidth: CGFloat = CGFloat(formattedString.length * 8)
        textLayer.bounds = CGRect(x: 0, y: 0, width: boxWidth, height: labelHeight)
        textLayer.position = CGPoint(x: bounds.maxX/2, y: -yPosOffset)
        
        textLayer.foregroundColor = CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [0.0, 0.0, 0.0, 1.0])
        
        if (label == "car" || label == "person" || label == "bus") && (bounds.width > 15 && bounds.width < 260) {
            boxLayer.frame = bounds
            boxLayer.borderWidth = 3.0
            boxLayer.borderColor = CGColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            boxLayer.cornerRadius = 4
            boxLayer.backgroundColor = UIColor.white.cgColor
            boxLayer.opacity = 0.7
            // boxLayer.addSublayer(textLayer)
            self.carPos = bounds.maxY
            
        } else if label == "traffic_light_red" && carPos > bounds.minY &&
                    (bounds.width > 5 && bounds.width < bounds.height) {
            boxLayer.frame = bounds
            boxLayer.borderWidth = 2.0
            boxLayer.borderColor = CGColor.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
            boxLayer.cornerRadius = 2
            // boxLayer.addSublayer(textLayer)
            boxLayer.backgroundColor = UIColor.red.cgColor
            boxLayer.opacity = 0.7
            isRedSignal = true
            isAlert = false
            
        } else if label == "traffic_light_green" && isRedSignal && carPos > bounds.minY
                && (bounds.width > 5 && bounds.width < bounds.height) {
            boxLayer.frame = bounds
            boxLayer.borderWidth = 2.0
            boxLayer.borderColor = CGColor.init(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0)
            boxLayer.cornerRadius = 2
            // boxLayer.addSublayer(textLayer)
            boxLayer.backgroundColor = UIColor.green.cgColor
            boxLayer.opacity = 0.7
            
            if isRedSignal && !isAlert {
                isRedSignal = !isRedSignal
                isAlert = true
                AudioServicesPlaySystemSound(1016)
            }
            
        } else if label == "stop sign" {
            self.accelerationView.rootView.isStopSign = true
        }
        
        if label != "stop sign" {
            self.accelerationView.rootView.isStopSign = false
        }
        
        if label == "traffic_light_green" && label != "traffic_light_red" {
            isRedSignal = !isRedSignal
        }

        /*
         traffic_light_na = disable
         */
       
        return boxLayer
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:]) // Create handler to perform request on the buffer
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let quartzImage = convertCIImageToCGImage(inputImage: ciimage) else { return }
        let image = UIImage(cgImage: quartzImage)
        let imageWithLaneOverlay = LaneDetectorBridge().detectLane(in: image)
        
        DispatchQueue.main.async {
            // self.accelerationView.rootView.laneImage = imageWithLaneOverlay
            self.detectionLayer.contents = imageWithLaneOverlay?.cgImage
            // self.laneImg.image = imageWithLaneOverlay
        }

        do {
            try imageRequestHandler.perform(self.requests) // Schedules vision requests to be performed
        } catch {
            print(error)
        }
    }

    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }
}

extension CGImage {
    func copyContext() -> CGContext? {
        if let ctx = CGContext(
            data: nil,
            width: self.width,
            height: self.height,
            bitsPerComponent: self.bitsPerComponent,
            bytesPerRow: self.bytesPerRow,
            space: self.colorSpace!,
            bitmapInfo: self.bitmapInfo.rawValue
        ) {
            ctx.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
            return ctx
        } else {
            return nil
        }
    }
}
