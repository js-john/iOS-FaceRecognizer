//
//  Util.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/26.
//

import Foundation
import UIKit
import Vision

struct DetectResult {
    var imgQuality: ImageQualityResult
    var enhancedImg: UIImage?
    var faceFeatures: FaceFeatures?
    var faceRect: CGRect?
    var valid: Bool = false
    var error: Error?
}

func calcDistance(features1: [Double], features2: [Double]) -> Double {
    let faceRecognizer = FaceRecognizer.shared()
    return faceRecognizer.calcDistance(features1, with: features2)
}

func detectFaceInImage(img: UIImage, checkQuality: Bool, callback: @escaping ((_ result: DetectResult) -> Void)) {
    let faceRecognizer = FaceRecognizer.shared()
    let rotatedImg = img.fixOrientation();
    var detectResult: DetectResult!
    if checkQuality {
        let imgQuality = faceRecognizer.checkImageQuality(rotatedImg)
        detectResult = DetectResult.init(imgQuality: imgQuality)
        detectResult.imgQuality = imgQuality
        guard imgQuality.passed else {
            callback(detectResult)
            return
        }
    } else {
        detectResult = DetectResult.init(imgQuality: ImageQualityResult.init(passed: true, brightness: 0, blur: 0, minSize: 0))
    }
    let enhancedImg = faceRecognizer.enhanceImage(rotatedImg)
    guard let enhancedCgImage = enhancedImg.cgImage else {
        callback(detectResult)
        return;
    }
    detectResult.enhancedImg = enhancedImg
    let imageRequestHandler = VNImageRequestHandler(cgImage: enhancedCgImage, options: [:]);
    let request = VNDetectFaceRectanglesRequest(completionHandler: {(request, error) in
        if error != nil {
            detectResult.error = error
            callback(detectResult)
            return;
        }
        guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
              let results = faceDetectionRequest.results as? [VNFaceObservation],
              results.count > 0
        else {
            callback(detectResult)
            return
        }
        let face = results[0];
        //检测到的 face.boundingBox 即为人脸的位置。
        //由于VNFaceObservation结果中的Y轴方向是反向的，且他们的值相当于图片中长高的比例，需转换后使用。
        let x = face.boundingBox.origin.x * enhancedImg.size.width,
            y = (1 - face.boundingBox.origin.y - face.boundingBox.size.height) * enhancedImg.size.height,
            w = face.boundingBox.size.width * enhancedImg.size.width,
            h = face.boundingBox.size.height * enhancedImg.size.height
        let faceRect = CGRect.init(x: x, y: y, width: w, height: h)
        detectResult.faceRect = faceRect
        let faceFeatures = faceRecognizer.genFeatures(enhancedImg, withFace: faceRect)
        if (faceFeatures.features.count == 0 || faceFeatures.landmarks.count == 0) {
            callback(detectResult)
            return
        }
        detectResult.faceFeatures = faceFeatures
        detectResult.valid = true
        callback(detectResult)
    })
    do {
        try imageRequestHandler.perform([request])
    } catch let error as NSError {
        detectResult.error = error
        callback(detectResult)
    }
}


extension UIImage {
    func fixOrientation() -> UIImage {
        
        // No-op if the orientation is already correct
        if ( self.imageOrientation == .up ) {
            return self;
        }
        
        // We need to calculate the proper transformation to make the image upright.
        // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
        var transform: CGAffineTransform = .identity
        
        if ( self.imageOrientation == .down || self.imageOrientation == .downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: self.size.height)
            transform = transform.rotated(by: .pi)
        }
        
        if ( self.imageOrientation == .left || self.imageOrientation == .leftMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.rotated(by: .pi/2)
        }
        
        if ( self.imageOrientation == .right || self.imageOrientation == .rightMirrored ) {
            transform = transform.translatedBy(x: 0, y: self.size.height);
            transform = transform.rotated(by: -.pi/2);
        }
        
        if ( self.imageOrientation == .upMirrored || self.imageOrientation == .downMirrored ) {
            transform = transform.translatedBy(x: self.size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        }
        
        if ( self.imageOrientation == .leftMirrored || self.imageOrientation == .rightMirrored ) {
            transform = transform.translatedBy(x: self.size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1);
        }
        
        // Now we draw the underlying CGImage into a new context, applying the transform
        // calculated above.
        let ctx: CGContext = CGContext(data: nil, width: Int(self.size.width), height: Int(self.size.height),
                                       bitsPerComponent: self.cgImage!.bitsPerComponent, bytesPerRow: 0,
                                       space: self.cgImage!.colorSpace!,
                                       bitmapInfo: self.cgImage!.bitmapInfo.rawValue)!;
        
        ctx.concatenate(transform)
        
        if ( self.imageOrientation == .left ||
                self.imageOrientation == .leftMirrored ||
                self.imageOrientation == .right ||
                self.imageOrientation == .rightMirrored ) {
            ctx.draw(self.cgImage!, in: CGRect(x: 0.0,y: 0.0,width: self.size.height,height: self.size.width))
        } else {
            ctx.draw(self.cgImage!, in: CGRect(x: 0.0,y: 0.0,width: self.size.width,height: self.size.height))
        }
        
        // And now we just create a new UIImage from the drawing context and return it
        return UIImage(cgImage: ctx.makeImage()!)
    }
}
