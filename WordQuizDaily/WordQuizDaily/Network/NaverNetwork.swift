//
//  NaverNetwork.swift
//  WordQuizDaily
//
//  Created by 정종원 on 1/29/24.
//

import Foundation
import Alamofire

protocol NaverNetworkDelegate: AnyObject {
    func imageDataUpdated(_ result: Result<NaverImageData, NaverImageError>)
}

enum NaverImageError: Error {
    case missingAPIKeys
    case invalidResponse
    case apiError(statusCode: Int, code: String?, message: String?)
    case decodingFailed(String)
    case emptyResult
    case requestFailed(String)

    var logMessage: String {
        switch self {
        case .missingAPIKeys:
            return "Missing Naver API keys"
        case .invalidResponse:
            return "Missing Naver API response status"
        case .apiError(let statusCode, let code, let message):
            return "Naver API error status=\(statusCode), code=\(code ?? "unknown"), message=\(message ?? "unknown")"
        case .decodingFailed(let message):
            return "Naver image response decode failed: \(message)"
        case .emptyResult:
            return "Naver image response contained no items"
        case .requestFailed(let message):
            return "Naver image request failed: \(message)"
        }
    }
}

private struct NaverAPIErrorResponse: Decodable {
    let errorCode: String?
    let errorMessage: String?
    let message: String?
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
        
        guard let clientID = naverClientID?.trimmingCharacters(in: .whitespacesAndNewlines),
              let clientSecret = naverClientSecret?.trimmingCharacters(in: .whitespacesAndNewlines),
              !clientID.isEmpty,
              !clientSecret.isEmpty else {
            publish(.failure(.missingAPIKeys), completion: completion)
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
        .responseData { response in
            switch response.result {
            case .success(let responseData):
                guard let statusCode = response.response?.statusCode else {
                    self.publish(.failure(.invalidResponse), completion: completion)
                    return
                }

                guard (200..<300).contains(statusCode) else {
                    let apiError = try? JSONDecoder().decode(NaverAPIErrorResponse.self, from: responseData)
                    self.publish(
                        .failure(.apiError(
                            statusCode: statusCode,
                            code: apiError?.errorCode,
                            message: apiError?.errorMessage ?? apiError?.message
                        )),
                        completion: completion
                    )
                    return
                }

                do {
                    let data = try JSONDecoder().decode(NaverImageData.self, from: responseData)
                    guard !data.items.isEmpty else {
                        self.publish(.failure(.emptyResult), completion: completion)
                        return
                    }
                    self.publish(.success(data), completion: completion)
                } catch {
                    self.publish(.failure(.decodingFailed(error.localizedDescription)), completion: completion)
                }
            case .failure(let error):
                self.publish(.failure(.requestFailed(error.localizedDescription)), completion: completion)
            }
        }
    }

    private func publish(_ result: Result<NaverImageData, NaverImageError>, completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                self.imageData = data
                print("\(#file) > \(#function) :: SUCCESS")
            case .failure(let error):
                self.imageData = nil
                print("\(#file) > \(#function) :: FAILURE : \(error.logMessage)")
            }

            self.delegate?.imageDataUpdated(result)
            completion()
        }
    }
}
