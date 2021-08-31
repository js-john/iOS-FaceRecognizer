//
//  UserAdminView.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/25.
//

import SwiftUI
struct UserAdminView: View {
    @StateObject var userAdminController: UserAdminController
    @State private var showNewUserSheet = false
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(content: {
                    ForEach(userAdminController.userList) { user in
                        HStack {
                            Text(user.name ?? "未设置名称")
                                .frame(width: 200, alignment: .leading)
                                .padding()
                            Image(uiImage: UIImage(data: user.avatar!) ?? UIImage.init(systemName: "person.crop.circle")!)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .cornerRadius(10)
                                .clipped()
                                .padding()
                            Spacer()
                        }
                        .border(Color.gray)
                    }
                }).padding()
            }
            .sheet(isPresented: $showNewUserSheet, content: {
                NewUserView(userAdminController: userAdminController, showNewUserSheet: $showNewUserSheet)
            })
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("新增用户") {
                            showNewUserSheet.toggle()
                        }
                        Button("清空数据库") {
                            userAdminController.drop()
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("用户库")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NewUserView: View {
    @StateObject var userAdminController: UserAdminController
    @State var genFeatureComplete: Bool = false
    @Binding var showNewUserSheet: Bool
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var userName: String = ""
    @State private var showSelectImageSource = false
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var errMsg: String?
    @State private var showMsg = false
    @State var features: [Double]?
    @State var enhancedImg: UIImage?
    @State var faceRect: CGRect = CGRect.zero
    @State var landmarks: [IdentifiablePoint] = []
    @State var imgQuality: ImageQualityResult!
    var body: some View {
        Form {
            TextField("姓名", text: $userName)
            Button(action: {
                showSelectImageSource.toggle()
            }, label: {
                if selectedImage != nil {
                    Image(uiImage: selectedImage!)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .cornerRadius(10)
                        .clipped()
                }
                else {
                    Text("选择图片")
                }
            })
            .actionSheet(isPresented: $showSelectImageSource, content: {
                ActionSheet(title: Text("选择图片"), message: nil, buttons: [
                    .default(Text("拍照"), action: {
                        sourceType = .camera
                        showImagePicker = true
                    }),
                    .default(Text("图库"), action: {
                        sourceType = .photoLibrary
                        showImagePicker = true
                    })
                ])
            })
            Button("计算人脸特征") {
                detectFaceInImage(img: selectedImage!, checkQuality: false) { result in
                    guard result.valid,
                          let faceFeatures = result.faceFeatures else {
                        var msg = ""
                        if result.faceRect == nil {
                            msg += " - 所选图片中未检测到人脸"
                        }
                        else if result.faceFeatures == nil {
                            msg += " - 检测到人脸，但无法计算人脸特征"
                        }
                        if result.error != nil {
                            msg += " - " + (result.error?.localizedDescription ?? "未知错误")
                        }
                        errMsg = msg;
                        showMsg.toggle()
                        return;
                    }
                    faceRect = result.faceRect!
                    features = result.faceFeatures?.features as? [Double]
                    enhancedImg = result.enhancedImg
                    imgQuality = result.imgQuality
                    var landmarks:[IdentifiablePoint] = []
                    for value in faceFeatures.landmarks {
                        let point = value as! CGPoint
                        landmarks.append(IdentifiablePoint(x: point.x, y: point.y))
                    }
                    self.landmarks = landmarks;
                    genFeatureComplete = true
                }
            }
            .disabled(selectedImage == nil)
            .alert(isPresented: $showMsg) {
                Alert(title: Text("无法计算人脸特征"), message: Text(errMsg ?? "未知错误"), dismissButton: .default(Text("好")))
            }
            if genFeatureComplete {
                DetectResultView(img: enhancedImg!, landmarks: landmarks, faceRect: faceRect)
            }
            Button("保存") {
                userAdminController.insertUser(name: userName, avatar: selectedImage!, features: features!)
                showNewUserSheet = false
            }
            .disabled(userName == "" || !genFeatureComplete)
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(selectedImage: $selectedImage, sourceType: sourceType)
                .onChange(of: selectedImage) { newValue in
                    genFeatureComplete = false;
                }
        }
    }
}
