import Foundation
import Combine
import SwiftData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var currentConversation: Conversation?
    
    private let modelManager = ModelManager.shared
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Add welcome message
        messages.append(Message(
            content: "Hello! I'm MedGemma, your AI medical assistant. I can help answer general medical questions, provide information about symptoms, and offer health guidance. How can I assist you today?",
            isUser: false
        ))
    }
    
    func setupModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func sendMessage(_ text: String) async {
        // Add user message
        let userMessage = Message(content: text, isUser: true)
        messages.append(userMessage)
        
        // Start loading
        isLoading = true
        
        do {
            // Get AI response
            let response = try await modelManager.generateResponse(for: text, context: messages)
            
            // Add AI message
            let aiMessage = Message(content: response, isUser: false)
            messages.append(aiMessage)
            
            // Save to history
            await saveToHistory()
        } catch {
            // Handle error
            let errorMessage = Message(
                content: "I apologize, but I encountered an error: \(error.localizedDescription). Please try again.",
                isUser: false
            )
            messages.append(errorMessage)
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages = [Message(
            content: "Chat cleared. How can I help you with your medical questions?",
            isUser: false
        )]
        currentConversation = nil
    }
    
    private func saveToHistory() async {
        guard let modelContext = modelContext else { return }
        
        // Create or update conversation
        if currentConversation == nil {
            let conversation = Conversation(title: generateConversationTitle())
            modelContext.insert(conversation)
            currentConversation = conversation
        }
        
        // Add messages to conversation
        if let conversation = currentConversation {
            // Clear existing messages and add all current messages
            conversation.messages = messages
            conversation.updatedAt = Date()
            
            // Save context
            do {
                try modelContext.save()
            } catch {
                print("Failed to save conversation: \(error)")
            }
        }
    }
    
    private func generateConversationTitle() -> String {
        // Generate title from first user message
        if let firstUserMessage = messages.first(where: { $0.isUser }) {
            let title = String(firstUserMessage.content.prefix(50))
            return title.count < firstUserMessage.content.count ? title + "..." : title
        }
        return "New Conversation"
    }
    
    func loadConversation(_ conversation: Conversation) {
        self.currentConversation = conversation
        self.messages = conversation.messages ?? []
    }
}