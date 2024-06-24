//
//  NaverNetwork.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/29/24.
//

import Foundation
import Alamofire

protocol NaverNetworkDelegate: AnyObject {
    func imageDataUpdated(_ imageData: NaverImageData?)
}
//ProcessInfo.processInfo.environment["API_KEY"]
class NaverNetwork: ObservableObject {
    static let shared = NaverNetwork()
    
    private init() {}
    
    @Published var imageData: NaverImageData?
    
    let naverClientID = Bundle.main.object(forInfoDictionaryKey: "NAVER_CLIENT_ID") as? String
    let naverClientSecret = Bundle.main.object(forInfoDictionaryKey: "NAVER_CLIENT_SECRET") as? String
    weak var delegate: NaverNetworkDelegate?

    
    func requestSearchImage(query: String, completion: @escaping () -> Void) {
        let baseURL = "https://openapi.naver.com/v1/search/image"
        
        guard let clientID = naverClientID, let clientSecret = naverClientSecret else {
            print("Missing Naver API Keys")
            return
        }
        
        let headers: HTTPHeaders = [
            "X-Naver-Client-Id": clientID,
            "X-Naver-Client-Secret": clientSecret
        ]
        
        let parameters: Parameters = [
            "query": query,
            "display": 50
        ]
        
        AF.request(baseURL,
                   method: .get,
                   parameters: parameters,
                   encoding: URLEncoding.default,
                   headers: headers)
        .validate(statusCode: 200...500)
        .responseDecodable(of: NaverImageData.self) { response in
            switch response.result {
            case .success(let data):
                guard let statusCode = response.response?.statusCode else { return }
                if statusCode == 200 {
                    DispatchQueue.main.async {
                        self.imageData = data
                        self.delegate?.imageDataUpdated(data)
                        completion()
                    }
                }
                print("\(#file) > \(#function) :: SUCCESS")
            case .failure(let error):
                print("\(#file) > \(#function) :: FAILURE : \(error)")
            }
        }
    }
}
