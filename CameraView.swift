import SwiftUI
import AVFoundation
import UIKit

public struct CameraView: View {
    @Binding var image: UIImage?
    let onImageCaptured: (UIImage) -> Void
    @Environment(\.presentationMode) var presentationMode
    
    public init(image: Binding<UIImage?>, onImageCaptured: @escaping (UIImage) -> Void) {
        self._image = image
        self.onImageCaptured = onImageCaptured
    }
    
    public var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                Button(action: {
                    // This is a placeholder. In a real app, you would implement camera functionality
                    if let image = UIImage(systemName: "photo") {
                        self.image = image
                        onImageCaptured(image)
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Circle()
                                .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                .padding(4)
                        )
                }
                .padding(.bottom, 30)
            }
        }
    }
} 