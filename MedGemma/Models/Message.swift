import Foundation
import SwiftData

@Model
final class Message {
    var id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    
    var conversation: Conversation?
    
    init(content: String, isUser: Bool) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
    }
}