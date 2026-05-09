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

    var preferredItem: NaverItem? {
        if items.indices.contains(2) {
            return items[2]
        }
        return items.first
    }
}

// MARK: - Item
struct NaverItem: Codable {
    let title: String
    let link: String //이미지의 URL
    let thumbnail: String
    let sizeheight, sizewidth: String

    var imageURLCandidates: [URL] {
        [thumbnail, link].reduce(into: [URL]()) { urls, urlString in
            guard let url = Self.makeURL(from: urlString), !urls.contains(url) else { return }
            urls.append(url)
        }
    }

    private static func makeURL(from urlString: String) -> URL? {
        let trimmedURLString = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedURLString.isEmpty else { return nil }

        if let url = URL(string: trimmedURLString) {
            return url
        }

        guard let encodedURLString = trimmedURLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        return URL(string: encodedURLString)
    }
}
