//
//  Constants.swift
//  Woojo
//
//  Created by Edouard Goossens on 22/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    
    struct App {
        struct RemoteConfig {
            struct Keys {
                static let termsURL = "terms_url"
                static let privacyURL = "privacy_url"
            }
        }
        struct Appearance {
            struct EmptyDatasets {
                static var titleStringAttributes: [String:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSFontAttributeName: UIFont.boldSystemFont(ofSize: 20.0),
                            NSForegroundColorAttributeName: UIColor.lightGray,
                            NSParagraphStyleAttributeName: paragraphStyle
                        ]
                        return attributes
                    }
                }
                static var descriptionStringAttributes: [String:Any] {
                    get {
                        let paragraphStyle = NSMutableParagraphStyle()
                        paragraphStyle.lineBreakMode = .byWordWrapping
                        paragraphStyle.alignment = .center
                        let attributes = [
                            NSFontAttributeName: UIFont.systemFont(ofSize: 13.0),
                            NSForegroundColorAttributeName: UIColor.lightGray,
                            NSParagraphStyleAttributeName: paragraphStyle
                        ]
                        return attributes
                    }
                }
            }
        }
    }
    
    struct User {
        static let firebaseNode = "users"
        struct Properties {
            static let uid = "uid"
            static let fbAppScopedID = "app_scoped_id"
            static let fbAccessToken = "fb_access_token"
        }
        struct Activity {
            static let firebaseNode = "activity"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let lastSeen = "last_seen"
                    static let signUp = "sign_up"
                }
            }
        }
        struct Profile {
            static let firebaseNode = "profile"
            struct Photo {
                static let firebaseNode = "photos"
                struct properties {
                    static let full = "full"
                    static let thumbnail = "thumbnail"
                }
            }
            struct properties {
                struct firebaseNodes {
                    static let firstName = "first_name"
                    static let gender = "gender"
                    static let description = "description"
                    static let city = "city"
                    static let country = "country"
                    static let photoID = "photoID"
                    static let birthday = "birthday"
                }
                struct graphAPIKeys {
                    static let firstName = "first_name"
                    static let gender = "gender"
                    static let description = "description"
                    static let city = "city"
                    static let country = "country"
                    static let photoURL = "photoURL"
                    static let birthday = "birthday"
                }
            }
        }
        struct Candidate {
            static let firebaseNode = "candidates"
            struct properties {
                struct firebaseNodes {
                    static let uid = "uid"
                }
            }
        }
        struct Event {
            static let firebaseNode = "events"
            struct properties {
                struct firebaseNodes {
                    static let id = "id"
                }
            }
        }
        struct Preferences {
            static let firebaseNode = "preferences"
            struct properties {
                struct firebaseNodes {
                    static let gender = "gender"
                    static let ageRange = "age_range"
                    static let ageRangeMin = "min"
                    static let ageRangeMax = "max"
                }
            }
        }
        struct Like {
            static let firebaseNode = "likes"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let created = "created"
                    static let visible = "visible"
                    static let message = "message"
                }
            }
        }
        struct Pass {
            static let firebaseNode = "passes"
            static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
            struct properties {
                struct firebaseNodes {
                    static let created = "created"
                }
            }
        }
    }
    
    struct Album {
        struct properties {
            struct graphAPIKeys {
                static let id = "id"
                static let name = "name"
                static let picture = "picture"
                static let pictureData = "data"
                static let pictureDataURL = "url"
                static let data = "data"
                static let count = "count"
            }
        }
    }
    
    struct Event {
        static let firebaseNode = "events"
        static let dateFormat = "yyyy-MM-dd'T'HH:mm:ssxx"
        static let humanDateFormat = "dd MMM yyyy, HH:mm"
        struct properties {
            struct firebaseNodes {
                static let id = "id"
                static let name = "name"
                static let place = "place"
                static let start = "start_time"
                static let end = "end_time"
                static let pictureURL = "picture_url"
                static let description = "description"
            }
            struct graphAPIKeys {
                static let id = "id"
                static let name = "name"
                static let place = "place"
                static let start = "start_time"
                static let end = "end_time"
                static let picture = "picture"
                static let pictureData = "data"
                static let pictureDataURL = "url"
                static let description = "description"
                static let attendingCount = "attending_count"
            }
        }
        struct Place {
            static let firebaseNode = "place"
            static let graphAPIKey = "place"
            struct properties {
                struct firebaseNodes {
                    static let name = "name"
                    static let location = "location"
                }
                struct graphAPIKeys {
                    static let name = "name"
                    static let location = "location"
                }
            }
            struct Location {
                static let firebaseNode = "location"
                struct properties {
                    struct firebaseNodes {
                        static let country = "country"
                        static let city = "city"
                        static let zip = "zip"
                        static let street = "street"
                        static let latitude = "latitude"
                        static let longitude = "longitude"
                        static let name = "name"
                    }
                    struct graphAPIKeys {
                        static let country = "country"
                        static let city = "city"
                        static let zip = "zip"
                        static let street = "street"
                        static let latitude = "latitude"
                        static let longitude = "longitude"
                        static let name = "name"
                    }
                }
            }
        }
    }
    
    struct GraphRequest {
        
        static let fields = "fields"
        static let fieldsSeparator = ","
        
        struct UserProfile {
            static let fieldID = "id"
        }
        
        struct UserProfilePhoto {
            static let path = "albums"
            static let fields = "type, picture.type(small), cover_photo{source}"
            struct keys {
                static let data = "data"
                static let type = "type"
                static let typeProfile = "profile"
                static let coverPhoto = "cover_photo"
                static let coverPhotoSource = "source"
                static let coverPhotoID = "id"
                static let picture = "picture"
                static let pictureData = "data"
                static let pictureDataURL = "url"
            }
        }
        
        struct UserEvents {
            static let path = "/me/events"
            static let fieldPictureUrl = "picture.type(normal){url}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct UserAlbums {
            static let path = "/me/albums"
            static let fields = "id,name,count,picture.type(small){url}"
            struct keys {
                static let data = "data"
            }
        }
        
        struct AlbumPhotos {
            static let path = "/photos"
            static let fields = "id,images"
            struct keys {
                static let data = "data"
                static let id = "id"
                static let images = "images"
                static let imageWidth = "width"
                static let imageHeight = "height"
                static let imageURL = "source"
            }
        }
        
    }
    
}
