import SwiftUI

struct CameraView: View {
    @EnvironmentObject var cameraManager: CameraManager
    @State private var selectedImage: UIImage?
    @State private var isShowingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    init(nutritionStore: NutritionStore) {}
    
    var body: some View {
        ZStack {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if cameraManager.isCameraAuthorized {
                    CameraPreview(cameraManager: cameraManager)
                        .ignoresSafeArea()
                        .overlay(
                            Group {
                                if !cameraManager.isCameraAuthorized {
                                    Text("Camera access is required")
                                        .foregroundColor(.white)
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(8)
                                }
                            }
                        )
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .overlay(
                            Text("Camera access is required")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .cornerRadius(8)
                        )
                }
            }
            
            VStack {
                Spacer()
                
                HStack(spacing: 60) {
                    Button(action: {
                        isShowingImagePicker = true
                        sourceType = .photoLibrary
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        cameraManager.capturePhoto { image in
                            selectedImage = image
                        }
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 80, height: 80)
                            .overlay(
                                Circle()
                                    .stroke(Color.black.opacity(0.8), lineWidth: 2)
                                    .padding(6)
                            )
                    }
                    
                    Button(action: {
                        cameraManager.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .sheet(isPresented: $isShowingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: sourceType)
        }
    }
} 