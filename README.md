# iOS-FaceRecognizer
A demo of face recognition SwiftUI app on iOS, build for iPad. Based on Vision, OpenCV, Dlib and ResNet.

# Features
- Add face image and name into database.
- Real-time Face tracking.
- Real-time face recognize.

# Build
## OpenCV
Install opencv dependency with cocoapods.
```shell
pod install
```
## Dlib
Clone Dlib to anywhere you like. For example ~/project/Framework.
```shell
mkdir Framework
cd Framework
git clone https://github.com/davisking/dlib.git
```
Download "libdlib.a" from release page and copy it to Framework/lib folder.
Add libdlib.a into the "Build Phases > Link Binary With Libraries" list in Xcode project.
Add dlib header path into "Build Settings > Header Search Paths". For example "/Users/js/project/Framework/dlib"
Add Framework path into "Build Settings > Library Serch Path". For example "/Users/js/project/Framework/lib" 

Download shape_predictor_68_face_landmarks.dat from here: 

http://dlib.net/files/shape_predictor_68_face_landmarks.dat.bz2

Download dlib_face_recognition_resnet_model_v1.dat from here: 

http://dlib.net/files/dlib_face_recognition_resnet_model_v1.dat.bz2

Drag & Drop these dat files into the project and add them into the "Build Phases > Copy Bundle Resources" list.

# Preview
[https://www.bilibili.com/video/BV1rv411A7AX?zw](https://www.bilibili.com/video/BV1rv411A7AX?zw)

----------
# iOS-FaceRecognizer
这是一个用 SwiftUI 为 iPad 编写的人脸识别 App。基于 Vison，OpenCV，Dlib 和 ResNet。

# 功能
- 向数据库添加人脸图片和姓名
- 实时人脸追踪
- 实时人脸识别

# 中文教程
我的博客：
[在 iOS 中实现人脸识别](https://blog.isign.ren/index.php/archives/20/)

