//
//  NotificationsSettingsViewModel.swift
//  Woojo
//
//  Created by Edouard Goossens on 13/05/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import RxCocoa
import RxSwift
import Promises

class NotificationsSettingsViewModel {
    func getNotificationsState(type: String) -> Driver<Bool> {
        return UserNotificationRepository.shared
            .getNotificationsState(type: type)
            .asDriver(onErrorJustReturn: false)
    }
    
    func setNotificationsState(type: String, enabled: Bool) -> Promise<Void> {
        return UserNotificationRepository.shared.setNotificationsState(type: type, enabled: enabled).then {
            Analytics.setUserProperties(properties: ["\(type)_notifications_enabled": String(enabled)])
            Analytics.Log(event: "Preferences_\(type)_notifications", with: ["enabled": String(enabled)])
        }
    }
}
