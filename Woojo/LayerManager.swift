//
//  LayerManager.swift
//  Woojo
//
//  Created by Edouard Goossens on 16/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import LayerKit

class LayerManager {
    
    static var layerClient = LYRClient(appID: URL(string: "layer:///apps/staging/e5d07d60-a3b7-11e6-bf2c-8858441a5d5e")!)!
    
    static func requestIdentityToken(for userID: String, appID: String, nonce: String, completion: @escaping (String?, Error?) -> Void) {
        let identityTokenURL = URL(string: "https://layer-identity-provider.herokuapp.com/identity_tokens")
        var request = URLRequest(url: identityTokenURL!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let parameters = [
            "app_id": appID,
            "user_id": userID,
            "nonce": nonce
        ]
        
        let requestBody = try! JSONSerialization.data(withJSONObject: parameters, options: .init(rawValue: 0))
        request.httpBody = requestBody
        
        let session = URLSession(configuration: URLSessionConfiguration.ephemeral)
        session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            if let data = data {
                let responseObject = try! JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0)) as! [String:Any]
                if let error = responseObject["error"] {
                    print("Error getting identityToken \(responseObject["status"]) \(error)")
                    completion(nil, NSError.init(domain: "layer-identity-provider.herokuapp.com", code: responseObject["status"] as! Int, userInfo: nil))
                } else {
                    let identityToken = responseObject["identity_token"] as! String
                    completion(identityToken, nil)
                }
            }
        }).resume()
    }
    
    static func authenticationToken(with userID: String, completion: @escaping (Bool?, Error?) -> Void) {
        layerClient.requestAuthenticationNonce() { (nonce, error) in
            if let nonce = nonce {
                self.requestIdentityToken(for: userID, appID: self.layerClient.appID.absoluteString, nonce: nonce) { (identityToken, error) in
                    if let identityToken = identityToken {
                        print("Identity token \(identityToken)")
                        self.layerClient.authenticate(withIdentityToken: identityToken) { (authenticatedUser, error) in
                            if let authenticatedUser = authenticatedUser {
                                completion(true, nil)
                                print("Layer authenticated user as \(authenticatedUser.userID)")
                            } else {
                                completion(false, error)
                            }
                        }
                    } else {
                        completion(false, error)
                        return
                    }
                }
            } else {
                completion(false, error)
                return
            }
        }
    }
    
    static func authenticateLayer(uid: String) {
        doAuthenticateLayer(with: uid) { (success, error) in
            if !success! {
                print("Failed to authenticate with Layer: \(error)")
            } else {
                print("Authenticated with Layer as \(layerClient.authenticatedUser!.userID)")
            }
        }
    }
    
    static func doAuthenticateLayer(with userID: String, completion: @escaping (Bool?, Error?) -> Void) {
        if let authenticatedUser = layerClient.authenticatedUser {
            if userID == authenticatedUser.userID {
                print("Layer already authenticated as user \(authenticatedUser.userID)")
                completion(true, nil)
                return
            } else {
                self.layerClient.deauthenticate() { (success, error) in
                    if let error = error {
                        completion(false, error)
                    } else {
                        self.authenticationToken(with: userID) { (success, error) in
                            completion(success, error)
                        }
                    }
                }
            }
        } else {
            self.authenticationToken(with: userID) { (success, error) in
                completion(success, error)
            }
        }
    }

}
