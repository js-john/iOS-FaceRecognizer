//
//  UserAdminController.swift
//  Face Recognize
//
//  Created by John Smith on 2021/8/25.
//

import Foundation
import CoreData
class UserAdminController: ObservableObject {
    @Published var userList: [User] = []
    let container = PersistenceController.shared.container
    func fetchUserList() {
        let context = container.viewContext
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        do {
            let list = try context.fetch(request)
            DispatchQueue.main.async {
                self.userList = list
            }
        } catch {
            print("fetch user list error...")
        }
    }
    
    func insertUser(name: String, avatar: UIImage, features: [Double]) {
        let context = container.newBackgroundContext()
        guard let featureData = try? NSKeyedArchiver.archivedData(withRootObject: features, requiringSecureCoding: false),
              let avatarData = avatar.jpegData(compressionQuality: 0.8)
        else {
            return;
        }
        let user = User(context: context)
        user.avatar = avatarData
        user.features = featureData
        user.name = name
        do {
            try context.save()
        } catch {
            print("无法保存数据")
        }
        fetchUserList()
    }
    
    func drop() {
        let context = container.newBackgroundContext()
        let request = NSBatchDeleteRequest(fetchRequest: NSFetchRequest(entityName: User.entity().name ?? ""))
        _ = try? context.execute(request)
        self.fetchUserList()
    }
}
