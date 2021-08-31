//
//  CameraPreviewView.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/21.
//

import SwiftUI
import AVFoundation

struct CameraPreviewView: UIViewRepresentable {
    @StateObject var cameraController: CameraController
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraController.preview = AVCaptureVideoPreviewLayer(session: cameraController.session)
        cameraController.preview.frame = view.frame
        cameraController.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(cameraController.preview)
        cameraController.check();
        cameraController.session.startRunning()
        return view;
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
