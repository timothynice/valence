import Foundation
import SwiftData

@Model
final class User {
    var id: UUID
    var name: String
    var email: String
    var createdAt: Date
    var updatedAt: Date

    init(name: String = "", email: String = "") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
