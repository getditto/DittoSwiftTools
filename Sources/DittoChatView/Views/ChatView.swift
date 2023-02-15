//
//  ChatView.swift
//  DittoChatView
//
//  Created by Shunsuke Kondo on 2023/02/14.
//

import SwiftUI
import Combine

@available(iOS 15.0, *)
public struct ChatView: View {

    @State private var typingMessage = ""
    @State private var showUserNameChangeAlert = false
    @State private var userName = ""
    @EnvironmentObject private var chatManager: DittoChatManager
    @ObservedObject private var keyboard = KeyboardResponder()

    private var cancellables = Set<AnyCancellable>()

    public var body: some View {
        NavigationView {
            VStack {

                // MARK: - Messages List
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack {
                            ForEach(chatManager.messages, id: \.self) { message in
                                MessageView(message: message, localPeerUserID: chatManager.dataManager.localPeerUserID, userName: userName(message))
                                    .id(message.id)
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.hidden)
                                    .padding(.vertical, 4)
                            }
                            .onChange(of: chatManager.messages.count) { _ in
                                withAnimation {
                                    scrollView.scrollTo(chatManager.messages[chatManager.messages.count - 1].id, anchor: .bottom)
                                }
                                chatManager.hasUnreadMessage = false
                            }
                            .onAppear {
                                scrollView.scrollTo(chatManager.messages[chatManager.messages.count - 1].id, anchor: .bottom)
                            }
                        }
                        .padding()
                    }
                }

                // MARK: - TextField
                HStack {
                    TextField("Message...", text: $typingMessage)
                        .textFieldStyle(.roundedBorder)
                        .frame(minHeight: 40)
                        .font(.system(size: 18))
                    Button(action: sendMessage) {
                        Text("Send").font(.system(size: 18, weight: .semibold))
                    }
                }
                .padding()
            }
            .padding(.bottom, keyboard.currentHeight)
            .edgesIgnoringSafeArea(keyboard.currentHeight == 0 ? .leading : .bottom)
            .background(Color(.systemGray6))
            // NavigationBar
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text(chatManager.roomTitle))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(userNameText) {
                        showUserNameChangeAlert = true
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .onTapGesture {
            hideKeyboard()
        }
        // Change user name
        .alert("User Name", isPresented: $showUserNameChangeAlert) {
            TextField("Username", text: $userName)
            Button("Save") {
                showUserNameChangeAlert = false
                chatManager.change(userName: userName)
            }
        }
        .onAppear {
            userName = chatManager.userName

            chatManager.hasUnreadMessage = false
        }
    }
}


// MARK: - Private Access

@available(iOS 15.0, *)
extension ChatView {

    private func userName(_ message: Message) -> String? {
        return message.getUserName(users: chatManager.users)
    }

    private func sendMessage() {
        guard !typingMessage.isEmpty else { hideKeyboard(); return }

        chatManager.send(messege: typingMessage)

        DispatchQueue.main.async {
            typingMessage = ""
            hideKeyboard()
        }
    }

    private func hideKeyboard() {
        let scenes = UIApplication.shared.connectedScenes
        guard let windowScene = scenes.first as? UIWindowScene else { return }
        let windows = windowScene.windows
        windows.forEach { $0.endEditing(true)}
    }

    private var userNameText: String {
        if chatManager.userName.count < 18 {
            return chatManager.userName
        } else {
            return chatManager.userName.prefix(15) + "..."
        }
    }
}
