import SwiftUI
import AVFoundation

public struct CameraPreview: UIViewRepresentable {
    @ObservedObject public var cameraManager: CameraManager
    
    public init(cameraManager: CameraManager) {
        self.cameraManager = cameraManager
    }
    
    public func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraManager.preview.frame = view.frame
        view.layer.addSublayer(cameraManager.preview)
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {
        cameraManager.preview.frame = uiView.frame
    }
} 