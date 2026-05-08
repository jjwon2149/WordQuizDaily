//
//  Data.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import Foundation

struct WordData: Codable {
    let channel: Channel
}

struct Channel: Codable {
    let item: [Item]
}

struct Item: Codable {
    let word: String
    let sense: [Sense]
}

struct Sense: Codable {
    let definition: String
    let pos: String?
    let link: String
    let type: String
}

extension WordData {
    init(learningWord: LearningWord) {
        self.init(
            channel: Channel(
                item: [
                    Item(
                        word: learningWord.korean,
                        sense: [
                            Sense(
                                definition: learningWord.simpleKoreanDefinition,
                                pos: learningWord.partOfSpeech,
                                link: "",
                                type: "local"
                            )
                        ]
                    )
                ]
            )
        )
    }

    var firstDefinition: String? {
        channel.item.first?.sense.first?.definition
    }
}
