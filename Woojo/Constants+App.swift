//
//  Constants+App.swift
//  Woojo
//
//  Created by Edouard Goossens on 05/04/2017.
//  Copyright © 2017 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit

extension Constants {
    
    struct App {
        struct RemoteConfig {
            struct Keys {
                static let termsURL = "terms_url"
                static let privacyURL = "privacy_url"
            }
        }
        /*struct Chat {
            static let applozicApplicationId = "11730f77a2a9608dba95cd86d60c498d0"
        }*/
        struct Appearance {
            struct EmptyDatasets {
                static var titleStringAttributes: [NSAttributedStringKey:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20.0),
                            NSAttributedStringKey.foregroundColor: UIColor.lightGray,
                            NSAttributedStringKey.paragraphStyle: paragraphStyle
                        ]
                        return attributes
                    }
                }
                static var descriptionStringAttributes: [NSAttributedStringKey:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineBreakMode = .byWordWrapping
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13.0),
                            NSAttributedStringKey.foregroundColor: UIColor.lightGray,
                            NSAttributedStringKey.paragraphStyle: paragraphStyle
                        ]
                        return attributes
                    }
                }
            }
        }
    }
    
}
