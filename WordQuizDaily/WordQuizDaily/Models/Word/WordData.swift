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





//"channel": {
//    "item": [
//        {
//            "word": "나무",
//            "sense": {
//                "target_code": 368281,
//                "sense_no": 1,
//                "definition": " 줄기나 가지가 목질로 된 여러해살이 식물.",
//                "pos": "명사",
//                "link": "http://opendict.korean.go.kr/dictionary/view?sense_no=368281",
//                "type": "일반어"
//            }
//        }
