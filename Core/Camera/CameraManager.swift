import AVFoundation
import UIKit
import SwiftUI

public class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published public private(set) var session = AVCaptureSession()
    @Published public private(set) var preview: AVCaptureVideoPreviewLayer!
    @Published public private(set) var output = AVCapturePhotoOutput()
    @Published public private(set) var isCameraAuthorized = false
    @Published public private(set) var isCameraUnavailable = false
    @Published public private(set) var isFlashAvailable = false
    @Published public private(set) var isBackCameraActive = true
    private var photoCompletion: ((UIImage?) -> Void)?
    
    public override init() {
        super.init()
        checkPermissions()
    }
    
    private func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    }
                }
            }
        case .denied, .restricted:
            isCameraAuthorized = false
        @unknown default:
            isCameraAuthorized = false
        }
    }
    
    private func setupCamera() {
        do {
            session.beginConfiguration()
            
            // Add video input
            let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                     for: .video,
                                                     position: .back)
            
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice!),
                  session.canAddInput(videoDeviceInput) else {
                isCameraUnavailable = true
                return
            }
            
            session.addInput(videoDeviceInput)
            
            // Add photo output
            guard session.canAddOutput(output) else {
                isCameraUnavailable = true
                return
            }
            
            session.addOutput(output)
            session.commitConfiguration()
            
            // Setup preview layer
            preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            
            // Check flash availability
            isFlashAvailable = videoDevice?.hasFlash ?? false
            
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.session.startRunning()
            }
            
        } catch {
            isCameraUnavailable = true
            print("Error setting up camera: \(error.localizedDescription)")
        }
    }
    
    public func switchCamera() {
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                    for: .video,
                                                    position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
        
        session.beginConfiguration()
        session.removeInput(currentInput)
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            isBackCameraActive.toggle()
        }
        
        session.commitConfiguration()
    }
    
    // MARK: - AVCapturePhotoCaptureDelegate
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCompletion?(nil)
            return
        }
        
        // If front camera is active, flip the image
        if !isBackCameraActive {
            if let cgImage = image.cgImage {
                let flippedImage = UIImage(cgImage: cgImage, scale: image.scale, orientation: .leftMirrored)
                photoCompletion?(flippedImage)
            } else {
                photoCompletion?(image)
            }
        } else {
            photoCompletion?(image)
        }
    }
    
    public func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        let settings = AVCapturePhotoSettings()
        
        if isFlashAvailable {
            settings.flashMode = .auto
        }
        
        photoCompletion = completion
        output.capturePhoto(with: settings, delegate: self)
    }
} 