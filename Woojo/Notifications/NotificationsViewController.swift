//
//  NotificationsViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 17/11/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit

class NotificationsViewController: UITableViewController {
    
    @IBOutlet weak var pushNotificationsSwitch: UISwitch!
    @IBOutlet weak var matchNotificationsSwitch: UISwitch!
    @IBOutlet weak var messageNotificationsSwitch: UISwitch!
    @IBOutlet weak var peopleNotificationsSwitch: UISwitch!
    @IBOutlet weak var eventsNotificationsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.pushNotificationsSwitch.isOn = UIApplication.shared.isRegisteredForRemoteNotifications
        User.current.value?.getNotificationsState(type: Constants.User.Settings.Notifications.Types.Match) { enabled in
            self.matchNotificationsSwitch.isOn = enabled
        }
        User.current.value?.getNotificationsState(type: Constants.User.Settings.Notifications.Types.Message) { enabled in
            self.messageNotificationsSwitch.isOn = enabled
        }
        User.current.value?.getNotificationsState(type: Constants.User.Settings.Notifications.Types.People) { enabled in
            self.peopleNotificationsSwitch.isOn = enabled
        }
        User.current.value?.getNotificationsState(type: Constants.User.Settings.Notifications.Types.Events) { enabled in
            self.eventsNotificationsSwitch.isOn = enabled
        }
    }
    
    @IBAction func switchNotifications(sender: UISwitch) {
        switch sender {
        case pushNotificationsSwitch:
            if sender.isOn {
                if let application = UIApplication.shared.delegate as? Woojo.Application {
                    application.requestNotifications()
                }
            } else {
                UIApplication.shared.unregisterForRemoteNotifications()
            }
        case matchNotificationsSwitch:
            User.current.value?.setNotificationsState(type: Constants.User.Settings.Notifications.Types.Match, enabled: sender.isOn, completion: nil)
        case messageNotificationsSwitch:
            User.current.value?.setNotificationsState(type: Constants.User.Settings.Notifications.Types.Message, enabled: sender.isOn, completion: nil)
        case peopleNotificationsSwitch:
            User.current.value?.setNotificationsState(type: Constants.User.Settings.Notifications.Types.People, enabled: sender.isOn, completion: nil)
        case eventsNotificationsSwitch:
            User.current.value?.setNotificationsState(type: Constants.User.Settings.Notifications.Types.Events, enabled: sender.isOn, completion: nil)
        default: ()
        }
    }

}
