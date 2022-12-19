//
//  ViewController.swift
//  BVision
//
//  Created by gitaeklee on 12/5/22.
//

import UIKit
import SwiftUI
import AVFoundation
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVSpeechSynthesizerDelegate {
    
    let accelerationView = UIHostingController(rootView: AccelerationView())
  
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil

    // for detector
    private var videoOutput = AVCaptureVideoDataOutput()
    var requests = [VNRequest]()

    var detectionLayer: CALayer! = nil
    var firstLabel: String = ""
    var firstConfidence: Float = 0.0
    var laneImageView: UIImageView!
    
    // for tracking signal
    var trackingLayer: CALayer! = nil
    var isRedSignal: Bool = false
    var carPos: CGFloat = 0.0
    var isAlert: Bool = false
    
    override func viewDidLoad() {
        checkPermission()

        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            self.setupLayers()
            self.setupDetector()
            self.setupSignalTracker()

            self.setupTextTracker()
            self.captureSession.startRunning()
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        self.previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        switch UIDevice.current.orientation {
            // Home button on top
            case UIDeviceOrientation.portraitUpsideDown:
                self.previewLayer.connection?.videoOrientation = .portraitUpsideDown
                     
            // Home button on right
            case UIDeviceOrientation.landscapeLeft:
                self.previewLayer.connection?.videoOrientation = .landscapeRight
                    
            // Home button on left
            case UIDeviceOrientation.landscapeRight:
                self.previewLayer.connection?.videoOrientation = .landscapeLeft
                     
            // Home button at bottom
            case UIDeviceOrientation.portrait:
                self.previewLayer.connection?.videoOrientation = .portrait
                        
            default:
                break
        }
        
        updateLayers()
    }

    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                self.permissionGranted = true
            case .notDetermined:
                requestPermission()
            default:
                self.permissionGranted = false
        }
    }
    
    func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video, completionHandler: { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        })
    }
    
    fileprivate func setupConstraintsDisplay() {
        accelerationView.view.backgroundColor = UIColor.clear // Needed to not hide other layers
        accelerationView.view.translatesAutoresizingMaskIntoConstraints = false
        accelerationView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        accelerationView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        accelerationView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        accelerationView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func setupCaptureSession() {
        guard let videoDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) else { return }
        guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice) else { return }
        
        guard captureSession.canAddInput(videoDeviceInput) else { return }
        captureSession.addInput(videoDeviceInput)
        
        // Preview layer
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen
        previewLayer.connection?.videoOrientation = .portrait

        // Detector
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        // Updates to UI must be on main queue
        DispatchQueue.main.async { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
            if self!.detectionLayer != nil {
                self!.previewLayer.addSublayer(self!.detectionLayer)
            }
            self!.addChild(self!.accelerationView)
            self!.view.addSubview(self!.accelerationView.view)
            self!.setupConstraintsDisplay()
        }
    }
}

struct HostedViewController: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        return ViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
}
