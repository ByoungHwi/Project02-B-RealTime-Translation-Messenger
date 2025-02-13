//
//  ChatViewReactor.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/25.
//

import Foundation
import ReactorKit

final class ChatViewReactor: Reactor {
    
    enum Action {
        case subscribeChatRoom
        case fetchMissingMessages
        case sendMessage(String)
        case chatDrawerButtonTapped
        case micButtonSizeChanged(MicButtonSize)
    }
    
    enum Mutation {
        case appendNewMessage([Message])
        case setSendResult(Bool)
        case toggleDrawerState
        case setMicButtonSize(MicButtonSize)
        case connectSocket
        case reconnectSocket
    }
    
    struct State {
        var messageBox: MessageBox
        var sendResult: Bool = true
        var roomCode: String
        var presentDrawer: Bool
        var isSubscribingMessage: Bool = false
        var micButtonSize: MicButtonSize
        var roomTitle: String
    }
    
    private let networkService: NetworkServiceProviding
    private let messageParser: MessageParseProviding
    private let chatWebSocket: WebSocketServiceProviding
    private let historyManager: HistoryServiceProviding
    private let roomID: Int
    private var userData: UserDataProviding
    
    let initialState: State
    
    init(networkService: NetworkServiceProviding,
         userData: UserDataProviding,
         messageParser: MessageParseProviding,
         chatWebSocket: WebSocketServiceProviding,
         historyManager: HistoryServiceProviding,
         roomID: Int,
         code: String) {
        
        self.networkService = networkService
        self.userData = userData
        self.messageParser = messageParser
        self.chatWebSocket = chatWebSocket
        self.historyManager = historyManager
        self.roomID = roomID
        initialState = State(messageBox: MessageBox(),
                             roomCode: code,
                             presentDrawer: false,
                             micButtonSize: userData.micButtonSize,
                             roomTitle: code.prefix(3) + "-" + code.suffix(3))
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .subscribeChatRoom:
            return currentState.isSubscribingMessage ?
                .just(.reconnectSocket) : .merge([.just(.connectSocket), subscribeMessages()])
        case .fetchMissingMessages:
            return fetchMissingMessages()
        case .sendMessage(let message):
            return requestSendMessage(message: message)
        case .chatDrawerButtonTapped:
            return .just(.toggleDrawerState)
        case .micButtonSizeChanged(let size):
            userData.micButtonSize = size
            return .just((.setMicButtonSize(size)))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .appendNewMessage(let messages):
            state.messageBox.append(messages)
        case .setSendResult(let isSuccess):
            state.sendResult = isSuccess
        case .toggleDrawerState:
            state.presentDrawer.toggle()
        case .connectSocket:
            state.isSubscribingMessage = true
        case .reconnectSocket:
            chatWebSocket.reconnect()
        case .setMicButtonSize(let size):
            state.micButtonSize = size
        }
        return state
    }
        
    private func subscribeMessages() -> Observable<Mutation> {
        networkService.sendSystemMessage(type: "in")
        saveHistory()
        return chatWebSocket.getMessage()
            .compactMap { $0.newMessage }
            .compactMap { [weak self] in
                self?.messageParser.parse(newMessage: $0)
            }
            .map { Mutation.appendNewMessage($0) }
    }
    
    private func fetchMissingMessages() -> Observable<Mutation> {
        let lastMessageTimeStamp = currentState.messageBox.lastMessageTimeStamp
        return networkService.getMissingMessage(timeStamp: lastMessageTimeStamp)
            .asObservable()
            .compactMap { $0.allMessagesByTime }
            .compactMap { [weak self] in
                self?.messageParser.parse(missingMessages: $0)
            }
            .map { Mutation.appendNewMessage($0) }
    }
    
    private func requestSendMessage(message: String) -> Observable<Mutation> {
        return networkService.sendMessage(text: message)
            .asObservable()
            .map { Mutation.setSendResult($0.createMessage) }
    }
    
    private func saveHistory() {
        historyManager.insert(of: ChatRoomHistory(roomID: roomID,
                                                  code: currentState.roomCode,
                                                  title: currentState.roomTitle,
                                                  userData: userData))
    }
}
