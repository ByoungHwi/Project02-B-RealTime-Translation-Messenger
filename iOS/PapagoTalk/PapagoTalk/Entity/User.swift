//
//  User.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/26.
//

import Foundation

protocol UserDataProviding {
    var id: Int { get set }
    var nickName: String { get set }
    var image: String { get set }
    var language: Language { get set }
}

struct User: Codable {
    var id: Int
    var nickName: String
    var image: String
    var language: Language
    
    init(id: Int, nickName: String, image: String, language: Language) {
        self.id = id
        self.nickName = nickName
        self.image = image
        self.language = language
    }
    
    init(_ imageFactory: ImageFactory = DefaultImageFactory()) {
        id = 1
        nickName = ""
        image = imageFactory.randomImageURL()
        language = Locale.currentLanguage
    }
}
