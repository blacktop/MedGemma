import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Conversation.updatedAt, order: .reverse) private var conversations: [Conversation]
    @State private var selectedConversation: Conversation?
    @State private var showingChat = false
    
    var body: some View {
        NavigationView {
            Group {
                if conversations.isEmpty {
                    VStack {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                            .padding()
                        
                        Text("No Conversations Yet")
                            .font(.title)
                            .bold()
                        
                        Text("Your chat history will appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                        
                        Spacer()
                    }
                } else {
                    List(conversations) { conversation in
                        ConversationRow(conversation: conversation)
                            .onTapGesture {
                                selectedConversation = conversation
                                showingChat = true
                            }
                    }
                }
            }
            .navigationTitle("History")
            .sheet(isPresented: $showingChat) {
                if let conversation = selectedConversation {
                    NavigationView {
                        ChatViewWithHistory(conversation: conversation)
                    }
                }
            }
        }
    }
}

struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.headline)
                .lineLimit(1)
            
            if let messages = conversation.messages, let lastMessage = messages.last {
                Text(lastMessage.content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Text(conversation.updatedAt, style: .relative)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct ChatViewWithHistory: View {
    let conversation: Conversation
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ChatView()
            .environmentObject(viewModel)
            .onAppear {
                viewModel.setupModelContext(modelContext)
                viewModel.loadConversation(conversation)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
    }
}