//
//  CameraView.swift
//  LiquidVision
//
//  Created by Yassine Lamtalaa on 10/14/25.
//
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    var onCapture: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        init(_ parent: CameraView) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            picker.dismiss(animated: true)
            if let image = info[.originalImage] as? UIImage {
                DispatchQueue.main.async {
                    self.parent.selectedImage = image
                    self.parent.onCapture(image)
                }
            }
        }
    }
}
