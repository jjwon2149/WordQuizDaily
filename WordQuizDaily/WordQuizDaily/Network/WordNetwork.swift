//
//  Network.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/24/24.
//

import Foundation

class WordNetwork: ObservableObject {
    
    @Published var wordData: WordData?
    let myApiKey = "850F3361187B59F09AD1CDAA3E898B12"
    
    func searchWord(_ searchWord: String) async throws -> WordData? {
        let urlString = "https://opendict.korean.go.kr/api/search?certkey_no=6282&key=\(myApiKey)&target_type=search&req_type=json&part=word&q=\(searchWord)&sort=dict&start=1&num=10"
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decodedData = try JSONDecoder().decode(WordData.self, from: data)
            DispatchQueue.main.async {
                self.wordData = decodedData
            }
            return decodedData
        } catch {
            print(error)
            throw error
        }
    }
}
