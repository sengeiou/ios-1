//
//  Notification.swift
//  Woojo
//
//  Created by Edouard Goossens on 23/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import FirebaseDatabase

extension CurrentUser {
    
    enum NotificationType: String {
        case match
        case message
    }
    
    class Notification {
        
        var id: String
        var type: NotificationType
        var created: Date
        var displayed: Bool?
        var data: [String:Any]?
        
        static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .iso8601)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            formatter.dateFormat = Constants.User.Notification.dateFormat
            return formatter
        }()
        
        static let ref: FIRDatabaseReference = User.current.value!.ref.child(Constants.User.Notification.firebaseNode)
        
        var ref: FIRDatabaseReference {
            get {
                return CurrentUser.Notification.ref.child(id)
            }
        }
        
        init(id: String, type: NotificationType, created: Date, displayed: Bool? = nil, data: [String:Any]? = nil) {
            self.id = id
            self.type = type
            self.created = created
            self.displayed = displayed  
            self.data = data
        }
        
        /*static func allFrom(firebase snapshot: FIRDataSnapshot) -> [Notification] {
            var notifications: [Notification] = []
            for item in snapshot.children {
                let typeLevelSnapshot = item as! FIRDataSnapshot
                if let type = NotificationType(rawValue: typeLevelSnapshot.key) {
                    switch type {
                    case .match:
                        let matchNotification = MatchNotification.from(firebase: typeLevelSnapshot.childSnapshot(forPath: type.rawValue))
                        notifications.append(matchNotification)
                    case .message:
                        let messageNotification = MessageNotification.from(firebase: typeLevelSnapshot.childSnapshot(forPath: type.rawValue))
                        notifications.append(matchNotification)
                    }
                    
                }
            }
            return notifications
        }*/
        
        convenience init?(fromFirebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any],
                let typeString = value[Constants.User.Notification.properties.firebaseNodes.type] as? String,
                let type = NotificationType(rawValue: typeString),
                let createdString = value[Constants.User.Notification.properties.firebaseNodes.created] as? String,
                let created = Notification.dateFormatter.date(from: createdString) {
                let displayed = value[Constants.User.Notification.properties.firebaseNodes.displayed] as? Bool
                let data = value[Constants.User.Notification.properties.firebaseNodes.data] as? [String:Any]
                self.init(id: snapshot.key, type: type, created: created, displayed: displayed, data: data)
                print("Set Displayed \(value[Constants.User.Notification.properties.firebaseNodes.displayed]) \(self.displayed)")
            } else {
                print("notif init returning nil")
                return nil
            }
        }
        
        /*class func from(firebase snapshot: FIRDataSnapshot) -> Notification? {
            if let value = snapshot.value as? [String:Any],
                let typeString = value[Constants.User.Notification.properties.firebaseNodes.type] as? String,
                let type = NotificationType(rawValue: typeString),
                let createdString = value[Constants.User.Notification.properties.firebaseNodes.created] as? String,
                let created = Notification.dateFormatter.date(from: createdString) {
                let data = value[Constants.User.Notification.properties.firebaseNodes.data] as? [String:Any]
                let notification = Notification(id: snapshot.key, type: type, created: created, data: data)
                notification.displayed = value[Constants.User.Notification.properties.firebaseNodes.displayed] as? Bool
                return notification
            } else {
                return nil
            }
        }*/
        
        class func deleteAll(otherId: String) {
            let queryRef = ref.queryOrdered(byChild: Constants.User.Notification.Interaction.properties.firebaseNodes.otherId).queryEqual(toValue: otherId)
            queryRef.observeSingleEvent(of: .value, with: { snapshot in
                for child in snapshot.children {
                    if let child = child as? FIRDataSnapshot {
                        child.ref.removeValue()
                    }
                }
                queryRef.removeAllObservers()
            })
        }
        
        func toDictionary() -> [String:Any] {
            var dict: [String:Any] = [:]
            dict[Constants.User.Notification.properties.firebaseNodes.created] = Notification.dateFormatter.string(from: self.created)
            dict[Constants.User.Notification.properties.firebaseNodes.type] = self.type.rawValue
            if let displayed = self.displayed {
                dict[Constants.User.Notification.properties.firebaseNodes.displayed] = displayed
            }
            return dict
        }
        
        func setDisplayed(completion: ((Error?) -> Void)? = nil) {
            self.displayed = true
            ref.child(Constants.User.Notification.properties.firebaseNodes.displayed).setValue(self.displayed, withCompletionBlock: { error, ref in
                completion?(error)
            })
        }
        
        func delete(completion: ((Error?) -> Void)? = nil) {
            ref.removeValue(completionBlock: { error, ref in
                completion?(error)
            })
        }
        
        func save(completion: ((Error?) -> Void)? = nil) {
            ref.setValue(toDictionary()) { error, ref in
                completion?(error)
            }
        }
        
    }
    
    class InteractionNotification: Notification {
        
        var otherId: String
        
        init(id: String, created: Date, type: NotificationType, otherId: String, displayed: Bool? = nil , data: [String:Any]? = nil) {
            self.otherId = otherId
            super.init(id: id, type: type, created: created, displayed: displayed, data: data)
        }
        
        init(notification: Notification, otherId: String) {
            self.otherId = otherId
            super.init(id: notification.id, type: notification.type, created: notification.created, displayed: notification.displayed, data: notification.data)
        }
        
        convenience init?(fromFirebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any],
                let notification = Notification(fromFirebase: snapshot),
                let otherId = value[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] as? String {
                self.init(notification: notification, otherId: otherId)
            } else {
                return nil
            }
        }
        
        override func toDictionary() -> [String:Any] {
            var dict = super.toDictionary()
            dict[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] = self.otherId
            return dict
        }
        
    }
    
    class MatchNotification: InteractionNotification {
        
        init(id: String, created: Date, otherId: String, displayed: Bool? = nil , data: [String:Any]? = nil) {
            super.init(id: id, created: created, type: .match, otherId: otherId, displayed: displayed, data: data)
        }
        
        init(notification: InteractionNotification) {
            super.init(id: notification.id, created: notification.created, type: .match, otherId: notification.otherId, displayed: notification.displayed, data: notification.data)
        }
        
        convenience init?(fromFirebase snapshot: FIRDataSnapshot) {
            if let notification = InteractionNotification(fromFirebase: snapshot) {
                self.init(notification: notification)
            } else {
                return nil
            }
        }
        
    }
    
    class MessageNotification: InteractionNotification {
        
        //var otherId: String
        //var messageId: String
        var excerpt: String
        
        init(id: String, created: Date, otherId: String, excerpt: String, displayed: Bool? = nil, data: [String:Any]? = nil) {
            //self.otherId = otherId
            //self.messageId = messageId
            self.excerpt = excerpt
            super.init(id: id, created: created, type: .message, otherId: otherId, displayed: displayed, data: data)
        }
        
        init(notification: InteractionNotification, excerpt: String) {
            //self.otherId = otherId
            //self.messageId = messageId
            self.excerpt = excerpt
            super.init(id: notification.id, created: notification.created, type: .message, otherId: notification.otherId, displayed: notification.displayed, data: notification.data)
        }
        
        convenience init?(fromFirebase snapshot: FIRDataSnapshot) {
            if let value = snapshot.value as? [String:Any],
                let notification = InteractionNotification(fromFirebase: snapshot),
                //let otherId = value[Constants.User.Notification.Match.properties.firebaseNodes.otherId] as? String,
                //let messageId = value[Constants.User.Notification.Message.properties.firebaseNodes.messageId] as? String,
                let excerpt = value[Constants.User.Notification.Interaction.Message.properties.firebaseNodes.excerpt] as? String {
                self.init(notification: notification, excerpt: excerpt)
            } else {
                print("messagenotif init returning nil")
                return nil
            }
        }
        
        override func toDictionary() -> [String:Any] {
            var dict = super.toDictionary()
            //dict[Constants.User.Notification.Interaction.properties.firebaseNodes.otherId] = self.otherId
            //dict[Constants.User.Notification.Message.properties.firebaseNodes.messageId] = self.messageId
            dict[Constants.User.Notification.Interaction.Message.properties.firebaseNodes.excerpt] = self.excerpt
            return dict
        }
        
    }
    
}
