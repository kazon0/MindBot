import Foundation
import CoreData

class CoreDataViewModel: ObservableObject {
    static let shared = CoreDataViewModel()

    let container: NSPersistentContainer
    @Published var savedEntities: [UserEntites] = []

    init() {
        container = NSPersistentContainer(name: "MyModel")
        container.loadPersistentStores { (description, error) in
            if let error = error {
                print("❌ Core Data 加载失败: \(error)")
            }
        }
        fetchUsers()
    }

    func fetchUsers() {
        let request = NSFetchRequest<UserEntites>(entityName: "UserEntites")
        do {
            savedEntities = try container.viewContext.fetch(request)
        } catch {
            print("❌ 获取用户数据失败: \(error)")
        }
    }

    func addUsers(name: String, pwd: String) {
        let context = container.viewContext
        let newUser = UserEntites(context: context)
        newUser.name = name
        newUser.pwd = pwd
        newUser.id = UUID().uuidString
        newUser.isGuest = false
        saveData()
    }

    func updateData(entity: UserEntites) {
        entity.name = (entity.name ?? "") + "!"
        entity.pwd = (entity.pwd ?? "") + "!"
        saveData()
    }

    func deleteData(indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        let entity = savedEntities[index]
        container.viewContext.delete(entity)
        saveData()
    }

    func saveData() {
        do {
            try container.viewContext.save()
            fetchUsers()
        } catch {
            print("❌ 保存失败: \(error)")
        }
    }

    func getUserIfValid(name: String, pwd: String) -> UserEntites? {
        return savedEntities.first { $0.name == name && $0.pwd == pwd }
    }
}
