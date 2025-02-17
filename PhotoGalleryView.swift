import SwiftUI
import Photos
import UIKit

public struct PhotoGalleryView: View {
    let onImageSelected: (UIImage) -> Void
    @State private var selectedImage: UIImage?
    
    public init(onImageSelected: @escaping (UIImage) -> Void) {
        self.onImageSelected = onImageSelected
    }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
            }
            .padding(.horizontal)
        }
    }
} 