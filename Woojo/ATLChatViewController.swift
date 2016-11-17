//
//  ChatViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 06/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import LayerKit
import Atlas

class ATLChatViewController: ATLConversationViewController, ATLConversationViewControllerDataSource, ATLConversationViewControllerDelegate {
    
    var dateFormatter: DateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        self.delegate = self
        // Uncomment the following line if you want to show avatars in 1:1 conversations
        // self.shouldDisplayAvatarItemForOneOtherParticipant = true
        
        // Setup the dateformatter used by the dataSource.
        self.dateFormatter.dateStyle = .short
        self.dateFormatter.timeStyle = .short
        
        self.configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let mainTabBarController = UIApplication.shared.windows.first!.rootViewController as! MainTabBarController
        mainTabBarController.tabBar.isHidden = true
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let mainTabBarController = UIApplication.shared.windows.first!.rootViewController as! MainTabBarController
        mainTabBarController.tabBar.isHidden = false
        super.viewWillDisappear(animated)
    }
    
    // MARK - UI Configuration methods
    
    func configureUI() {
        //ATLOutgoingMessageCollectionViewCell.appearance().messageTextColor = .red
        for participant in self.conversation.participants {
            if participant.userID != LayerManager.layerClient.authenticatedUser?.userID {
                self.navigationItem.title = participant.displayName
            }
        }
    }
    
    // MARK - ATLConversationViewControllerDelegate methods
    
    func conversationViewController(_ viewController: ATLConversationViewController, didSend message: LYRMessage) {
        print("Message sent!")
    }
    
    func conversationViewController(_ viewController: ATLConversationViewController, didFailSending message: LYRMessage, error: Error) {
        print("Message failed to sent with error: \(error)")
    }
    
    func conversationViewController(_ viewController: ATLConversationViewController, didSelect message: LYRMessage) {
        print("Message selected")
    }
    
    // MARK - ATLConversationViewControllerDataSource methods
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, participantFor identity: LYRIdentity) -> ATLParticipant {
        let chatParticipant = ChatParticipant()
        chatParticipant.avatarImageURL = identity.avatarImageURL
        chatParticipant.firstName = identity.firstName
        return chatParticipant
    }
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, attributedStringForDisplayOf date: Date) -> NSAttributedString {
        let attributes: NSDictionary = [ NSFontAttributeName : UIFont.systemFont(ofSize: 14), NSForegroundColorAttributeName : UIColor.gray ]
        return NSAttributedString(string: self.dateFormatter.string(from: date as Date), attributes: attributes as? [String : AnyObject])
    }
    
    func conversationViewController(_ conversationViewController: ATLConversationViewController, attributedStringForDisplayOfRecipientStatus recipientStatus: [AnyHashable : Any]) -> NSAttributedString {
        let mergedStatuses: NSMutableAttributedString = NSMutableAttributedString()
        
        let recipientStatusDict = recipientStatus as NSDictionary
        let allKeys = recipientStatusDict.allKeys as NSArray
        allKeys.enumerateObjects({ participant, _, _ in
            let participantAsString = participant as! String
            if (participantAsString == LayerManager.layerClient.authenticatedUser?.userID) {
                return
            }
            
            var text = ""
            let textColor = UIColor.lightGray
            let status = LYRRecipientStatus(rawValue: recipientStatusDict[participantAsString] as! Int)
            switch status! {
            case .sent:
                text = "Sent"
            case .delivered:
                text = "Delivered"
            case .read:
                text = "Read"
            default:
                text = ""
            }
            let statusString: NSAttributedString = NSAttributedString(string: text, attributes: [NSForegroundColorAttributeName: textColor])
            mergedStatuses.append(statusString)
        })
        return mergedStatuses;
    }

    
}
