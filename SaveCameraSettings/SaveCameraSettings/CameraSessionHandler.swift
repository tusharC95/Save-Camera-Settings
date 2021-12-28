//
//  CameraSessionHandler.swift
//  SaveCameraSettings
//
//  Created by Tushar Chitnavis on 25/12/21.
//

import UIKit
import AVFoundation
import Photos
import MobileCoreServices
protocol SessionHandlerDelegate {
}

class CameraSessionHandler: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate , AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
    
    @objc let session = AVCaptureSession()
    @objc var cameraDevice : AVCaptureDevice?
    @objc var videoLayer = AVCaptureVideoPreviewLayer()
    let videoOutput = AVCaptureVideoDataOutput()
    let photoOutput = AVCapturePhotoOutput()
    private var photoQualityPrioritizationMode: AVCapturePhotoOutput.QualityPrioritization = .quality
    let sampleQueue = DispatchQueue(label: "com.tchitnavis.SaveCameraSettings.sampleQueue", attributes: [])
    var currentBuffer : CMSampleBuffer?
    let layer = AVSampleBufferDisplayLayer()
    
    var currentMetadata: [AnyObject]
    
    var sessionHandlerDelegate: SessionHandlerDelegate!
    let showRect = true
    var myDevice: AVCaptureDevice! = nil
    
    var delegate: SessionHandlerDelegate?
    
    override init() {
        currentMetadata = []
        super.init()
    }
    
    
    func configure() throws {
        
        do {
            myDevice = try getCameraDevice()
        } catch  {
            throw ErrorMessage(description: error.localizedDescription)
        }
        
        configureSession()
    }
    
    private func getCameraDevice() throws -> AVCaptureDevice {
        
        let camera = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: .video, position: .front)
        
        if let valideValue = camera {
            return valideValue
        }
        else{
            throw ErrorMessage(description: "Failed to get camera")
        }
    }
    
    private func configureSession() {
        
        session.sessionPreset = .photo
        let output = AVCaptureVideoDataOutput()
                
        output.setSampleBufferDelegate(self, queue: sampleQueue)
        
        let input = try! AVCaptureDeviceInput(device: myDevice!)
        session.beginConfiguration()
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        if session.canAddOutput(photoOutput) {
            
            session.addOutput(photoOutput)
            photoOutput.isHighResolutionCaptureEnabled = true
            photoQualityPrioritizationMode = .quality
            photoOutput.maxPhotoQualityPrioritization = .quality
            
            if photoOutput.isDepthDataDeliverySupported {
                photoOutput.isDepthDataDeliveryEnabled = true
                
            }
            
            if photoOutput.isPortraitEffectsMatteDeliverySupported {
                photoOutput.isPortraitEffectsMatteDeliveryEnabled = true
                
            }
        }
        
        session.commitConfiguration()
        
        let settings: [AnyHashable: Any] = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: Int(kCVPixelFormatType_32BGRA)]
        output.videoSettings = settings as? [String : Any]
    }
    
    func stopCamera()  {
        session.stopRunning()
    }
    
    func takephoto(){
        
        var photoSettings = AVCapturePhotoSettings()
        
        // Capture HEIF photos when supported. Enable auto-flash and high-resolution photos.
        if  self.photoOutput.availablePhotoCodecTypes.contains(.hevc) {
            photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        }
        
        if !photoSettings.__availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.__availablePreviewPhotoPixelFormatTypes.first!]
        }
        //
        photoSettings.isDepthDataDeliveryEnabled = self.photoOutput.isDepthDataDeliveryEnabled
        //
        photoSettings.isPortraitEffectsMatteDeliveryEnabled = self.photoOutput.isPortraitEffectsMatteDeliveryEnabled
        
        photoSettings.photoQualityPrioritization = self.photoQualityPrioritizationMode
        
        photoSettings.isHighResolutionPhotoEnabled = true
        
        photoSettings.flashMode = .off
        self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
    }
    
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        if let connection = output.connection(with: AVMediaType.video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation =  .portrait
            }
        }
        self.currentBuffer = sampleBuffer
        
        layer.enqueue(sampleBuffer)
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        currentMetadata = metadataObjects as [AnyObject]
    }
    
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            NSLog("Error capturing photo: \(error)")
        } else {
            
            NSLog("Gone")
            
            let  photoData = photo.fileDataRepresentation()
            
            guard let _ = photoData else {
                NSLog("No photo data resource")
                return
            }
            
            session.stopRunning()
            
            PHPhotoLibrary.shared().performChanges({
                
                let assetRequest = PHAssetCreationRequest.forAsset()
                
                assetRequest.addResource(with: .photo, data: photoData!, options: nil)
            }
                                                   
            ) { (success, error) in
                
                print(success)
                
                print(error as Any)
                
            }
            
            NSLog("Back again")
        }
    }
}

public struct ErrorMessage: Error {
    let description: String
    
}

extension ErrorMessage: LocalizedError {
    public var errorDescription: String? {
        return NSLocalizedString(description, comment: "")
    }
}
