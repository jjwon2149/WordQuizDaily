//
//  NaverImageData.swift
//  WordQuizDaily
//
//  Created by 정종원 on 2/18/24.
//

import Foundation

// MARK: - Welcome
struct NaverImageData: Codable {
    let items: [NaverItem]
}

// MARK: - Item
struct NaverItem: Codable {
    let title: String
    let link: String //이미지의 URL
    let thumbnail: String
    let sizeheight, sizewidth: String
}
