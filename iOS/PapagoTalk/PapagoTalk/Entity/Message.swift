//
//  Message.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/26.
//

import Foundation

struct Message: Codable {
    let id: Int?
    let text: String
    let sender: User
    let language: String
    let timeStamp: String
    
    var type: MessageType
    var isTranslated: Bool = false
    var isFirstOfDay: Bool = true
    var shouldTimeShow: Bool = true
    var shouldImageShow: Bool = false
    
    var time: Date {
        return timeStamp.toDate()
    }
    
    init(of text: String, by sender: User) {
        self.id = nil
        self.text = text
        self.sender = sender
        self.language = sender.language.code
        self.timeStamp = Date.presentTimeStamp()
        self.type = .sentOrigin
    }
    
    init(data: MessageData, with text: TranslatedResult, timeStamp: String, isTranslated: Bool = false) {
        self.id = data.id
        self.text = isTranslated ? text.translatedText : text.originText
        self.sender = User(data: data.userData)
        self.language = data.source
        self.timeStamp = timeStamp
        self.type = isTranslated ? .receivedTranslated : .receivedOrigin
        self.isTranslated = isTranslated
    }
    
    init(systemText: String, timeStamp: String) {
        self.id = 0
        self.text = systemText
        self.sender = User()
        self.language = ""
        self.timeStamp = timeStamp
        self.type = .system
    }
    
    mutating func setIsFirst(with isFirst: Bool) {
        isFirstOfDay = isFirst
    }
    
    mutating func setType(by userID: Int) {
        guard sender.id != userID else {
            type = isTranslated ? .sentTranslated : .sentOrigin
            return
        }
        type = isTranslated ? .receivedTranslated : .receivedOrigin
    }
}
