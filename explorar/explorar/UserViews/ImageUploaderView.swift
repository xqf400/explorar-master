//
//  UploadImages.swift
//  explorar
//
//  Created by Fabian Kuschke on 11.08.25.
//

import SwiftUI
import PhotosUI
import FirebaseStorage
import Drops

struct ImageUploaderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var uploadedImageNamesText: String
    @State private var selectedImages: [UIImage] = []
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var imageNames: [String] = []
    @State private var isUploading = false
    @State private var message = ""
    @State var cityName: String
    let challengeID: Int
    @State private var uploadRecImage: Bool = false
    @State private var recImage: UIImage?

    var body: some View {
        VStack {
            if challengeID == 5 {
                Spacer()
                Button("Select Recogintion Image") {
                    uploadRecImage = true
                    showingImagePicker = true
                }
                if recImage != nil {
                    Image(uiImage: recImage!)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            Spacer()
            HStack {
                Button("Select Photos") {
                    uploadRecImage = false
                    showingImagePicker = true
                }
                Spacer()
                Button("Take Photo") {
                    uploadRecImage = false
                    showingCamera = true
                }
            }
            .padding()

            ScrollView(.horizontal) {
                HStack {
                    ForEach(selectedImages.indices, id: \.self) { index in
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipped()
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
            if challengeID == 5 {
                Button(action: uploadAllImages) {
                    Text(isUploading ? "Uploading..." : "Upload All")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUploading || selectedImages.isEmpty || recImage == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isUploading || selectedImages.isEmpty || recImage == nil)
                .padding()
            } else {
                Button(action: uploadAllImages) {
                    Text(isUploading ? "Uploading..." : "Upload All")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isUploading || selectedImages.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(isUploading || selectedImages.isEmpty)
                .padding()
            }
            Text(message)
                    .padding(.horizontal)
            Spacer()
        }
        .overlay{
            if isUploading {
                ProgressView("Uploading Images...")
                    .padding()
            }
        }

        // Present photo library picker
        .sheet(isPresented: $showingImagePicker) {
            PhotoPicker(selectedImages: $selectedImages, recImage: $recImage, uploadRecImage: $uploadRecImage)
        }
        // Present camera capture
        .sheet(isPresented: $showingCamera) {
            CameraPicker(selectedImage: $selectedImages, recImage: $recImage, uploadRecImage: $uploadRecImage)
        }
    }
// MARK: Upload all images
    func uploadAllImages() {
        isUploading = true

        let storage = Storage.storage()
        let group = DispatchGroup()
        if recImage != nil {
            let imageName = "\(cityName)_image\(1).jpg"
            guard let imageData = recImage!.jpegData(compressionQuality: 1.0) else {
                message = "Failed to convert image to data."
                group.leave()
                return
            }
            let storageRef = storage.reference().child("images/\(cityName)/\(imageName)")

            storageRef.putData(imageData, metadata: nil) { metadata, error in
                if let error = error {
                    message = "Upload error: \(error.localizedDescription)"
                } else {
                    imageNames.append(imageName)
                    print("Uploaded rec image: \(imageName)")
                    for (index, image) in selectedImages.enumerated() {
                        group.enter()
                        var newIndex = index
                        if challengeID == 5 {
                            newIndex += 2
                        }
                        let imageName = "\(cityName)_image\(newIndex).jpg"
                        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                            message = "Failed to convert image to data."
                            group.leave()
                            continue
                        }
                        
                        let storageRef = storage.reference().child("images/\(cityName)/\(imageName)")

                        storageRef.putData(imageData, metadata: nil) { metadata, error in
                            if let error = error {
                                message = "Upload error: \(error.localizedDescription)"
                            } else {
                                imageNames.append(imageName)
                                print("Uploaded \(imageName)")
                            }
                            group.leave()
                        }
                    }

                    group.notify(queue: .main) {
                        isUploading = false
                        uploadedImageNamesText = imageNames.joined(separator: ", ")
                        print("uploaded images")
                        message = "uploaded images"
                        selectedImages = []
                        dismiss()
                    }
                }
            }
        } else {
            for (index, image) in selectedImages.enumerated() {
                group.enter()
                var newIndex = index
                if challengeID == 5 {
                    newIndex += 2
                }
                let imageName = "\(cityName)_image\(newIndex).jpg"
                guard let imageData = image.jpegData(compressionQuality: 1.0) else {
                    message = "Failed to convert image to data."
                    group.leave()
                    continue
                }
                
                let storageRef = storage.reference().child("images/\(cityName)/\(imageName)")

                storageRef.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        message = "Upload error: \(error.localizedDescription)"
                    } else {
                        imageNames.append(imageName)
                        print("Uploaded \(imageName)")
                    }
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                isUploading = false
                uploadedImageNamesText = imageNames.joined(separator: ", ")
                print("uploaded images")
                message = "uploaded images"
                selectedImages = []
                Drops.show(Drop(title: "Images uploaded"))
                dismiss()
            }
        }


    }
}

// MARK: PHPickerViewController
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var recImage: UIImage?
    @Binding var uploadRecImage: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 0
        if uploadRecImage {
            config.selectionLimit = 1
        }
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: PHPickerViewControllerDelegate {
        let parent: PhotoPicker

        init(_ parent: PhotoPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                        if let image = object as? UIImage {
                            DispatchQueue.main.async {
                                if self.parent.uploadRecImage {
                                    self.parent.recImage = image
                                } else {
                                    self.parent.selectedImages.append(image)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: camera
struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) private var presentationMode
    @Binding var selectedImage: [UIImage]
    @Binding var recImage: UIImage?
    @Binding var uploadRecImage: Bool

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                if self.parent.uploadRecImage {
                    self.parent.recImage = image
                } else {
                    self.parent.selectedImage.append(image)
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
