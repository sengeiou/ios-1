//
//  UserStore.swift
//  Woojo
//
//  Created by Edouard Goossens on 28/04/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import CodableFirebase
import RxSwift
import Promises

class UserRepository: BaseRepository {
    static let shared = UserRepository()
    
    override private init() {
        super.init()
    }
    
    func getPreferences() -> Observable<Preferences?> {
        return withCurrentUser { $0.child("preferences").rx_observeEvent(event: .value).map { Preferences(from: $0) } }
    }
    
    func setPreferences(preferences: Preferences) -> Promise<Void> {
        return doWithCurrentUser { $0.child("preferences").setValuePromise(value: preferences.dictionary) }
    }

    func setSignUp(date: Date) -> Promise<Void> {
        return doWithCurrentUser { $0.child("activity/sign_up").setValuePromise(value: self.dateFormatter.string(from: date)) }
    }

    func setLastSeen(date: Date) -> Promise<Void> {
        return doWithCurrentUser { $0.child("activity/last_seen").setValuePromise(value: self.dateFormatter.string(from: date)) }
    }

    func isUserSignedUp() -> Promise<Bool> {
        return doWithCurrentUser { $0.child("activity/sign_up").getDataSnapshot() }.then { dataSnapshot -> Bool in
            return dataSnapshot.exists()
        }
    }

    func addDevice(device: Device) -> Promise<Void> {
        if device.token.isNullOrEmpty()  { return Promise(UserRepositoryError.deviceTokenNullOrEmpty) }
        return doWithCurrentUser { $0.child("devices").child(device.token!).setValuePromise(value: device.dictionary) }
    }

    func getBotUid() -> Promise<String?> {
        return doWithCurrentUser { $0.child("bot/uid").getDataSnapshot() }.then { dataSnapshot in
            return Promise(dataSnapshot.value as? String)
        }
    }

    func removeCurrentUser() -> Promise<Void> {
        return doWithCurrentUser { $0.removeValuePromise() }
    }

    enum UserRepositoryError: Error {
        case deviceTokenNullOrEmpty
    }
    
}
