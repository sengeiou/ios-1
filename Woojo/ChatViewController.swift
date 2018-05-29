//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 15/02/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Applozic
import SDWebImage
import PKHUD
import Whisper
import RxSwift
import RxCocoa
import FirebaseAuth
import FirebaseDatabase

class ChatViewController: ALChatViewController, UIGestureRecognizerDelegate, AuthStateAware {
    
    @IBOutlet weak var loadEarlierAction: UIButton!
    @IBOutlet weak var loadEarlierActionTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var bannerView: UIView!
    
    let translucentColor = UIColor(red: 247.0/255.0, green: 247.0/255.0, blue: 247.0/255.0, alpha: 0.95)
    var unmatchObserverHandle: UInt?
    var disposeBag = DisposeBag()
    var matchesReference: DatabaseReference?
    var matchesDisposable: Disposable?
    var authStateDidChangeListenerHandle: AuthStateDidChangeListenerHandle?
    
    override var individualLaunch: Bool {
        get {
            return false
        }
        set {
            super.individualLaunch = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.placeHolderTxt = NSLocalizedString("Write a message...", comment: "")
        ALApplozicSettings.setColorForSendMessages(self.view.tintColor)
        
        mTableView.contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 50.0, right: 0.0)
        
        UserMatchRepository.shared.getMatchesReference().subscribe(onNext: {
            self.matchesReference = $0
        }, onError: { _ in
            
        }).disposed(by: disposeBag)
        
        /*if let navigationController = navigationController {
            let userChatBannerView = UserChatBannerView(frame: CGRect(x: 0, y: UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height, width: view.frame.width, height: 100))
            userChatBannerView.load(title: "Why not sit together?", description: "Choose your seat today and\nmeet on board your Joon flight!", image: #imageLiteral(resourceName: "joon"), actionText: "Go")
            bannerView.addSubview(userChatBannerView)
        }*/
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("DID LAYOUT SUBVIEWS")
    }
    
    override func setTitle() {
        super.setTitle()
        setNavigationItemTitle()
    }
    
    func setContactProfilePhoto() {
        let profileItem = UIBarButtonItem()
        
        let profileButton = UIButton(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
        profileButton.imageView?.contentMode = .scaleAspectFill
        profileButton.backgroundColor = UIColor.clear
        let widthConstraint = profileButton.widthAnchor.constraint(equalToConstant: 36)
        let heightConstraint = profileButton.heightAnchor.constraint(equalToConstant: 36)
        heightConstraint.isActive = true
        widthConstraint.isActive = true
        if let contactImageUrl = alContact.contactImageUrl {
            SDWebImageManager.shared().imageDownloader?.downloadImage(with: URL(string: contactImageUrl), options: [], progress: nil, completed: { image, _, _, _ in
                if let image = image {
                    profileButton.setImage(image, for: .normal)
                }
            })
        }
        profileButton.layer.cornerRadius = profileButton.frame.width / 2
        profileButton.layer.masksToBounds = true
        profileItem.customView = profileButton
        
        profileButton.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
        
        if (self.navRightBarButtonItems.count == 0) {
            self.navRightBarButtonItems.add(profileItem)
        } else {
            if let barButtonItem = self.navRightBarButtonItems.object(at: 0) as? UIBarButtonItem {
                barButtonItem.customView = profileButton
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        startListeningForAuthStateChange()
        
        navigationController?.navigationBar.layer.shadowOpacity = 0.0
        navigationController?.navigationBar.layer.shadowRadius = 0.0
        navigationController?.navigationBar.layer.shadowOffset = CGSize.zero
        navigationController?.navigationBar.tintColor = nil
        navigationController?.navigationBar.barTintColor = nil
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        typingMessageView.backgroundColor = translucentColor
        sendMessageTextView.backgroundColor = UIColor.clear
        sendButton.backgroundColor = UIColor.clear
        
        self.setContactProfilePhoto()
        
        matchesDisposable = UserMatchRepository.shared.getMatchesReference().subscribe(onNext: {
            self.matchesReference = $0
            self.wireUnmatchObserver()
        }, onError: { _ in
            
        })
        
        label.textColor = label.textColor.withAlphaComponent(0.6)
        
        mTableView.backgroundColor = UIColor.white
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide), name: NSNotification.Name.UIKeyboardDidHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newMessage), name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(doRefresh), name: NSNotification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
    }
    
    func setNavigationItemTitle() {
        let button = navigationItem.titleView as! UIButton
        if let title = button.title(for: .normal) {
            let titleString = NSAttributedString(string: title, attributes: [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 17.0)])
            button.setAttributedTitle(titleString, for: .normal)
            button.setAttributedTitle(titleString, for: .focused)
        }
        button.addTarget(self, action: #selector(showProfile), for: .touchUpInside)
    }
    
    @objc func doRefresh() {
        print("REFRESHING CHAT")
        super.fetchAndRefresh()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        
        self.doRefresh()
        
        loadEarlierAction.backgroundColor = translucentColor
        let titleString = NSAttributedString(string: NSLocalizedString("Load earlier messages", comment: ""), attributes: [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 12.0), NSAttributedStringKey.foregroundColor: self.view.tintColor])
        loadEarlierAction.setAttributedTitle(titleString, for: .normal)
        let bottomBorder = UIView(frame: CGRect(x: 0, y: loadEarlierAction.frame.height - 4, width: loadEarlierAction.frame.width, height: 1))
        bottomBorder.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        loadEarlierAction.addSubview(bottomBorder)
        if let navigationController = navigationController {
            loadEarlierActionTopConstraint.constant = UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height
        }
        
        UserNotificationRepository.shared.deleteAll(otherId: self.contactIds).catch { _ in }
        
        HUD.hide()
        
        /* if let uid = User.current.value?.uid,
            let analyticsEventParameters = [Constants.Analytics.Events.ChatDisplayed.Parameters.uid: uid,
                                            Constants.Analytics.Events.ChatDisplayed.Parameters.otherId: self.contactIds] as? [String: String] {
            Analytics.Log(event: Constants.Analytics.Events.ChatDisplayed.name, with: analyticsEventParameters)
        } */
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.sendMessageTextView.resignFirstResponder()
        self.label.isHidden = true
        self.label.alpha = 0.0
        self.typingLabel.isHidden = true
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: Applozic.NEW_MESSAGE_NOTIFICATION), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "APP_ENETER_IN_FOREGROUND"), object: nil)
        
        matchesDisposable?.dispose()
        self.unwireUnmatchObserver()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        stopListeningForAuthStateChange()
    }
    
    @objc func newMessage() {
        scrollTableViewToBottom(withAnimation: true)
        UserNotificationRepository.shared.deleteAll(otherId: self.contactIds).catch { _ in }
    }
    
    func wireUnmatchObserver() {
        self.unmatchObserverHandle = matchesReference?.observe(.childRemoved, with: { (snap) in
            print("UNMATCH DETECTED", snap.key, self.contactIds)
            if snap.key == self.contactIds {
                self.conversationDeleted()
            }
        })
    }
    
    func unwireUnmatchObserver() {
        if let handle = self.unmatchObserverHandle {
            matchesReference?.removeObserver(withHandle: handle)
        }
    }
    
    func conversationDeleted() {
        if HUD.isVisible {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                self.showUnmatchHUDAndPop()
            }
        } else {
            self.showUnmatchHUDAndPop()
        }
    }
    
    func showUnmatchHUDAndPop() {
        HUD.flash(.labeledError(title: NSLocalizedString("Closing chat", comment: ""), subtitle: NSLocalizedString("You're no longer connected to this user", comment: "")), onView: self.view, delay: 2.0) { _ in
            if let presentedViewController = self.presentedViewController as? UserDetailsViewController {
                presentedViewController.dismiss(animated: true) {
                    self.navigationController?.popViewController(animated: true)
                }
            } else {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    //override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //guard let navigationController = navigationController else { return }
        
        /*if scrollView == sendMessageTextView {
            return
        }
        
        var doneConversation = false
        var doneOtherwise = false
        
        if conversationId != nil && ALApplozicSettings.getContextualChatOption() {
            doneConversation = ALUserDefaultsHandler.isShowLoadEarlierOption(conversationId.stringValue) && ALUserDefaultsHandler.isServerCallDone(forMSGList: conversationId.stringValue)
        } else {
            let ids: String = (self.channelKey != nil) ? self.channelKey.stringValue : self.contactIds
            doneOtherwise = ALUserDefaultsHandler.isShowLoadEarlierOption(ids) && ALUserDefaultsHandler.isServerCallDone(forMSGList: ids)
        }
        
        if scrollView.contentOffset.y == -(UIApplication.shared.statusBarFrame.height + navigationController.navigationBar.frame.height) && (doneConversation || doneOtherwise) {
            self.loadEarlierAction.isHidden = false
        } else {
            self.loadEarlierAction.isHidden = true
        }*/
        
        //print(scrollView, mTableView.contentOffset)
        //mTableView.setContentOffset(CGPoint(x: mTableView.contentOffset.x, y: mTableView.contentOffset.y - 50.0), animated: true)
    //}
    
    @objc func showProfile() {
        if alContact.userId == "woojo-female" {
            let userDetailsViewController = UserDetailsViewController<User>(uid: "woojo-female", userType: User.self)
            userDetailsViewController.chatViewController = self
            navigationController?.pushViewController(userDetailsViewController, animated: true)
        } else {
            let userDetailsViewController = UserDetailsViewController<Match>(uid: alContact.userId, userType: Match.self)
            userDetailsViewController.chatViewController = self
            navigationController?.pushViewController(userDetailsViewController, animated: true)
        }
        //if let userDetailsViewController = self.storyboard?.instantiateViewController(withIdentifier: "UserDetailsViewController") as? UserDetailsViewController {
            //userDetailsViewController.buttonsType = .options
            //userDetailsViewController.uid = self.contactIds
            //userDetailsViewController.otherUserType = Match.self
                //let closeTapGestureRecognizer = UITapGestureRecognizer(target: userDetailsViewController, action: #selector(userDetailsViewController.dismiss(sender:)))
                //userDetailsViewController.addGestureRecognizer(closeTapGestureRecognizer)
                // let toggleTapGestureRecognizer = UITapGestureRecognizer(target: userDetailsViewController.cardView, action: #selector(userDetailsViewController.cardView.toggleDescription))
                // userDetailsViewController.cardView.carouselView.addGestureRecognizer(toggleTapGestureRecognizer)
            //})
        //}
    }
    
    @objc func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            self.checkBottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y //+ 5.0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
                self.scrollTableViewToBottom(withAnimation: false)
            }, completion: { finished in
                if finished {
                    self.scrollTableViewToBottom(withAnimation: true)
                }
            })
        }
    }
    
    override func scrollTableViewToBottom(withAnimation animated: Bool) {
        if mTableView.contentSize.height > mTableView.frame.size.height {
            let offset = CGPoint(x: 0, y: mTableView.contentSize.height - mTableView.frame.size.height + typingMessageView.frame.size.height - 7.0)
            mTableView.setContentOffset(offset, animated: animated)
        }
    }
    
    @IBAction func doScroll(_ sender: Any) {
        scrollTableViewToBottom(withAnimation: true)
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            self.checkBottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y //+ 5.0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
                self.scrollTableViewToBottom(withAnimation: false)
            }, completion: { finished in
                if finished {
                    self.scrollTableViewToBottom(withAnimation: true)
                }
            })
        }
    }
    
    @objc func keyboardDidHide(_ notification: NSNotification) {
        scrollTableViewToBottom(withAnimation: false)
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if let theMessage = self.alMessageWrapper.getUpdatedMessageArray()[indexPath.row] as? ALMessage {
            if let metadata = theMessage.metadata as? NSMutableDictionary,
                let category = metadata.object(forKey: "category") as? String,
                category == "MATCH" || category == "HIDDEN" {
                cell.isHidden = true
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let theMessage = self.alMessageWrapper.getUpdatedMessageArray()[indexPath.row] as? ALMessage {
            if let metadata = theMessage.metadata as? NSMutableDictionary,
                let category = metadata.object(forKey: "category") as? String,
                category == "MATCH" || category == "HIDDEN" {
                return 0.0
            } else if (theMessage.fileMeta == nil || (theMessage.fileMeta.thumbnailUrl == nil && theMessage.fileMeta.contentType == nil)) && theMessage.type != "100" {
                return super.tableView(tableView, heightForRowAt: indexPath) - 25.0
            } else {
                return super.tableView(tableView, heightForRowAt: indexPath)
            }
        } else {
            return 0
        }
    }
    
}
