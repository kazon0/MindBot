

import Foundation
import CoreData

class CoreDataViewModel: ObservableObject{
    let container : NSPersistentContainer
    @Published var savedEntities:[UserEntites] = []
    init(){
        container = NSPersistentContainer(name: "MyModel")
        container.loadPersistentStores{
            (description,error) in
            if let error = error {
                print("error loading core data.\(error)")
            }
        }
        fetchUsers()
    }
    func fetchUsers(){
        let request = NSFetchRequest<UserEntites>(entityName: "UserEntites")
        do{
            savedEntities = try container.viewContext.fetch(request)//保存实体在本地数组
        }catch let error{
            print("error fetching.\(error)")
        }
       
    }
    func addUsers(name: String, pwd: String) {
        let context = container.viewContext
        let newUser = UserEntites(context: context)
        newUser.name = name
        newUser.pwd = pwd
        newUser.id = UUID().uuidString
        saveData()
    }

    func updateData(entity:UserEntites){
        let currentName = entity.name ?? ""
        let newName = currentName + "!"
        let currentPwd = entity.pwd ?? ""
        let newPwd = currentPwd + "!"
        entity.name = newName
        entity.pwd = newPwd
        saveData()
        
    }
    func deleteData(indexSet : IndexSet){
        guard let index = indexSet.first else{return}
        let entity = savedEntities[index]
        container.viewContext.delete(entity)
        saveData()
    }
    func saveData() {
        do {
            try container.viewContext.save()
            print("✅ 数据保存成功")
            fetchUsers()
        } catch {
            print("❌ 保存数据时出错：\(error.localizedDescription)")
        }
    }
    func getUserIfValid(name: String, pwd: String) -> UserEntites? {
        return savedEntities.first { $0.name == name && $0.pwd == pwd }
    }

}
 
