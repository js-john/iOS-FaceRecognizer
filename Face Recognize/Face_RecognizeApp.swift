//
//  Face_RecognizeApp.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/20.
//

import SwiftUI

@main
struct Face_RecognizeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject var userAdminController = UserAdminController.init()
    var body: some Scene {
        WindowGroup {
            TabView {
                FaceRecognizeView(userAdminController: userAdminController)
                    .tabItem {
                        Image(systemName: "faceid")
                        Text("人脸识别")
                    }
                UserAdminView(userAdminController: userAdminController)
                    .tabItem {
                        Image(systemName: "square.3.stack.3d")
                        Text("用户库")
                    }
            }
            .onAppear(perform: {
                userAdminController.fetchUserList();
            })
            .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
