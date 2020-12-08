//
//  ChatReactorTests.swift
//  PapagoTalkTests
//
//  Created by 송민관 on 2020/11/19.
//

import XCTest

class ChatReactorTests: XCTestCase {
    
    func test_subscribeMessages_success() throws {
        // Given
        let reactor = ChatViewReactor(networkService: ApolloNetworkServiceMockSuccess(),
                                      userData: UserDataProviderMock(),
                                      messageParser: MessageParserMock(),
                                      roomID: 8,
                                      code: "")
        
        // When
        reactor.action.onNext(.subscribeNewMessages)
        
        // Then
        XCTAssertEqual(reactor.currentState.isSubscribingMessage, true)
        XCTAssertEqual(reactor.currentState.messageBox.messages.first?.text, "안녕하세요")
        XCTAssertEqual(reactor.currentState.messageBox.messages.first?.sender.nickName, "testUser")
        XCTAssertEqual(reactor.currentState.messageBox.messages.first?.sender.language, .korean)
        XCTAssertEqual(reactor.currentState.messageBox.messages.first?.language, "ko")
    }
    
    func test_subscribeMessages_reconnect() throws {

    }
    
    
}
