//
//  MockHistoryManager.swift
//  ReactorTests
//
//  Created by 송민관 on 2020/12/17.
//

import Foundation
@testable import PapagoTalk

class MockHistoryManager: HistoryServiceProviding {
    func fetch() -> [ChatRoomHistory] {
        var history = [
            ChatRoomHistory(roomID: 0,
                            code: "",
                            title: "",
                            usedNickname: "",
                            usedLanguage: Language.codeToLanguage(of: "ko"),
                            usedImage: "",
                            enterDate: Date())
        ]
        return history
    }
    
    func insert(of history: ChatRoomHistory) {
        
    }
}
