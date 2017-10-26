//
//  MessagesViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import UIKit
import Applozic
import FirebaseAuth
import RxSwift
import PKHUD

class MessagesViewController: ALMessagesViewController, ShowsSettingsButton/*, UITableViewDelegate*/ {
    
    var disposeBag = DisposeBag()
    
    var showChatAfterDidAppear: String?
    var didAppear = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        //mTableView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
        
        for case let cell as ALContactCell in self.mTableView.visibleCells {
            cell.mUserImageView.contentMode = .scaleAspectFill
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        /*if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }*/
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.layer.shadowRadius = 0.0
        navigationController?.navigationBar.layer.shadowOffset = CGSize.zero
        navigationController?.navigationBar.titleTextAttributes = [:]
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.clear
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newMessageReceived), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(enteredForeground), name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
        
        reloadData()
    }
    
    func enteredForeground() {
        reloadData()
        viewDidAppear(true)
    }
    
    func reloadData() {
        ALMessageService.getLatestMessage(forUser: ALUserDefaultsHandler.getDeviceKeyString()) { (_, _) in }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Forcefully disable Applozic notifications
        if let window = UIApplication.shared.keyWindow?.subviews {
            for view in window {
                if let view = view as? TSMessageView {
                    view.isHidden = true
                    view.removeFromSuperview()
                }
            }
        }
        if let showChatAfterDidAppear = showChatAfterDidAppear {
            self.createDetailChatViewController(showChatAfterDidAppear)
            self.showChatAfterDidAppear = nil
        }
        didAppear = true
        HUD.hide()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        print("MESSAGES VIEW WILL DISAPPEAR.. BUT DO NOTHING")
        /*if self.detailChatViewController != nil {
            self.detailChatViewController.refreshMainView = true
        }*/
        //NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Override to prevent unsubscribing MQTT from conversation
        didAppear = false
    }
    
    func showSettings(sender : Any?) {
        let settingsNavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SettingsNavigationController")
        self.present(settingsNavigationController, animated: true, completion: nil)
    }
    
    func newMessageReceived() {
        print("MESSSAAAGEGE FROM MessagesViewController")
    }
    
    /*func tableView(_ tableView: UITableView, editActionsForRowAt: IndexPath) -> [UITableViewRowAction]? {
        let unmatch = UITableViewRowAction(style: .destructive, title: "Unmatch") { action, index in
            if let cell = tableView.cellForRow(at: editActionsForRowAt) as? ALContactCell {
                
            }
        }
        
        let report = UITableViewRowAction(style: .normal, title: "Report") { action, index in
            print("Reporting")
        }
        report.backgroundColor = .orange
        
        if let cell = tableView.cellForRow(at: editActionsForRowAt) as? ALContactCell,
            let userName = cell.mUserNameLabel.text {
            if userName.range(of: "from Woojo") == nil {
                //return [unmatch, report]
                return []
            }
        }
        
        return []
    }*/
    
}
