//
//  FaceRecognizeView.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/21.
//

import SwiftUI

struct FaceRecognizeView: View {
    @StateObject private var cameraController = CameraController.init()
    @StateObject var userAdminController: UserAdminController
    @State private var showEnhancedImg = false;
    @State private var name: String = "未识别";
    @State private var distance: Double = 100;
    var body: some View {
        ZStack {
            CameraPreviewView(cameraController: cameraController)
                .ignoresSafeArea()
            ImageQualityMonitorView(cameraController: cameraController)
            VStack {
                HStack {
                    Spacer()
                    Toggle.init(isOn: $showEnhancedImg) {
                        Spacer()
                        Text("人脸追踪预览")
                    }.frame(width: 180)
                }
                Spacer()
            }.padding()
            if cameraController.enhancedImg != nil && showEnhancedImg {
                ZStack {
                    HStack {
                        Spacer()
                        VStack {
                            DetectResultView(img: cameraController.enhancedImg!, landmarks: cameraController.landmarks, faceRect: cameraController.faceRect)
                        }
                    }
                }
            }
            VStack {
                HStack {
                    Text(name)
                        .font(.title)
                        .foregroundColor(name == "未识别" ? .red : .green)
                        .padding()
                        .background(Color.white)
                }
                Spacer()
            }
        }
        .onChange(of: cameraController.features) { f1 in
            var minDistance = 100.0;
            var name = "未识别"
            for user in userAdminController.userList {
                guard let featureData = user.features else {
                    continue
                }
                let f2 = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(featureData) as? [Double]
                let d = calcDistance(features1: f1, features2: f2!)
                if d < minDistance && d < 0.6 {
                    minDistance = d
                    name = user.name!
                }
            }
            self.name = name
            self.distance = minDistance
        }
    }
}

struct DetectResultView: View {
    var img: UIImage
    var landmarks: [IdentifiablePoint]
    var faceRect: CGRect
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: img)
            Rectangle()
                .fill(Color.clear)
                .border(Color.red)
                .frame(width: faceRect.size.width, height: faceRect.size.height)
                .offset(x: faceRect.origin.x, y: faceRect.origin.y)
            ForEach(landmarks) { point in
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
                    .offset(x: point.x, y: point.y)
            }
        }
    }
}

struct ImageQualityMonitorView: View {
    @StateObject var cameraController: CameraController
    var body: some View {
        VStack {
            HStack {
                Text("清晰度：\(cameraController.imageQualityResult.blur) 亮度：\(cameraController.imageQualityResult.brightness)")
                    .fontWeight(.bold)
                    .foregroundColor(cameraController.imageQualityResult.passed ? .green : .red)
                    .padding()
                    .background(Color.white)
                Spacer()
            }
            Spacer()
        }
    }
}

