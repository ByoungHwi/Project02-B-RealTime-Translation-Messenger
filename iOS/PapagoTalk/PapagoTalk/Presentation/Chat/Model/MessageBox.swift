//
//  MessageBox.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/26.
//

import Foundation

final class MessageBox {
    
    var messages = [Message]()
    
    var lastMessageTimeStamp: String {
        guard let lastMessage = messages.last else {
            return Date.presentTimeStamp()
        }
        return lastMessage.timeStamp
    }
    
    func append(_ messages: [Message]) {
        messages.forEach { append($0) }
    }
    
    func append(_ message: Message) {
        var message = message
        
        guard let lastMessage = messages.last else {
            message.shouldImageShow = message.type == .receivedOrigin ? true : false
            messages.append(message)
            return
        }
        
        guard isAppropriateMessage(of: message, comparedBy: lastMessage) else {
            return
        }
        
        message = setMessageIsFirst(of: message, comparedBy: lastMessage)
        message = setShouldImageShow(of: message, comparedBy: lastMessage)
        setShouldTimeShow(of: message, comparedBy: lastMessage)
        messages.append(message)
    }
    
    private func isAppropriateMessage(of newMessage: Message, comparedBy lastMessage: Message) -> Bool {
        lastMessage.time <= newMessage.time
    }
    
    private func setMessageIsFirst(of newMessage: Message, comparedBy lastMessage: Message) -> Message {
        let isNotFirstOfDay = Calendar.isSameDate(of: newMessage.time, with: lastMessage.time)
        var message = newMessage
        message.setIsFirst(with: !isNotFirstOfDay)
        return message
    }
    
    private func setShouldImageShow(of newMessage: Message, comparedBy lastMessage: Message) -> Message {
        guard newMessage.type == .receivedOrigin else {
            return newMessage
        }
        var message = newMessage
        
        if lastMessage.type != .receivedOrigin {
            message.shouldImageShow = true
            return message
        }
        
        message.shouldImageShow = !isSameTime(of: newMessage, comparedBy: lastMessage)
        return message
    }
    
    private func setShouldTimeShow(of newMessage: Message, comparedBy lastMessage: Message) {
        guard isSameSender(of: newMessage, comparedBy: lastMessage),
              isSameTime(of: newMessage, comparedBy: lastMessage)
        else {
            return
        }
        var lastMessage = messages.removeLast()
        lastMessage.shouldTimeShow = false
        messages.append(lastMessage)
    }
    
    private func isSameMessageType(of newMessage: Message, comparedBy lastMessage: Message, type: MessageType) -> Bool {
        newMessage.type == type && lastMessage.type == type
    }
    
    private func isSameSender(of newMessage: Message, comparedBy lastMessage: Message) -> Bool {
        newMessage.sender.id == lastMessage.sender.id
    }
    
    private func isSameTime(of newMessage: Message, comparedBy lastMessage: Message) -> Bool {
        Calendar.isSameTime(of: newMessage.time, with: lastMessage.time)
    }
}
