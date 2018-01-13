//
//  PlansViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 11/01/2018.
//  Copyright © 2018 Tasty Electrons. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa
import DZNEmptyDataSet
import PKHUD

class PlansViewController: UIViewController {
    let disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "plans"
    @IBOutlet var datePicker: UIDatePicker!
    @IBOutlet var placeChooserView: UIView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var resultsTableView: UITableView!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    var plan: Plan? {
        didSet {
            bindPlan()
        }
    }
    @IBOutlet var placeButtonsView: UIView!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var planLabel: UILabel!
    @IBOutlet var changePlaceButton: UIButton!
    @IBOutlet var makePlanButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        User.current.asObservable().subscribe(onNext: { (user) in
            if let tips = user?.tips, tips[self.tipId] != nil {
                self.tipView.isHidden = true
            }
        }).addDisposableTo(disposeBag)
        
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
        
        resultsTableView.register(UINib(nibName: "SearchPlacesResultsTableViewCell", bundle: nil), forCellReuseIdentifier: "searchPlaceCell")
        resultsTableView.rowHeight = 100
        
        setupDataSource()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupDataSource() {
        let results = searchBar.rx.text.orEmpty
            .asDriver()
            .throttle(0.3)
            .distinctUntilChanged()
            .flatMapLatest { query -> SharedSequence<DriverSharingStrategy, Array<Place>> in
                if query.isEmpty {
                    return Observable.just([])
                        .asDriver(onErrorJustReturn: [])
                } else {
                    return Place.search(query: query)
                        .retry(3)
                        .startWith([])
                        .asDriver(onErrorJustReturn: [])
                }
        }
        
        results
            .drive(resultsTableView.rx.items(cellIdentifier: "searchPlaceCell", cellType: SearchPlacesResultsTableViewCell.self)) { (_, place, cell) in
                print("PLACE", place)
                cell.place = place
            }
            .addDisposableTo(disposeBag)
        
        resultsTableView.rx.itemSelected
            .subscribe(onNext: { indexPath in
                if let reachable = self.isReachable(),
                    reachable,
                    let cell = self.resultsTableView.cellForRow(at: indexPath) as? SearchPlacesResultsTableViewCell,
                    let place = cell.place {
                    self.plan = Plan(place: place, date: self.datePicker.date)
                    self.placeChooserView.isHidden = true
                    self.placeButtonsView.isHidden = false
                }
            }).addDisposableTo(disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        resultsTableView.emptyDataSetDelegate = self
        resultsTableView.emptyDataSetSource = self
        
        resultsTableView.layoutSubviews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        tipView.isHidden = true
        tipView.subviews.forEach { $0.isHidden = true }
        UIView.commitAnimations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        startMonitoringReachability()
        checkReachability()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardFrameEnd = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect, let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval, let navigationController = navigationController {
            bottomConstraint.constant = self.view.frame.size.height - keyboardFrameEnd.origin.y + navigationController.navigationBar.frame.size.height + UIApplication.shared.statusBarFrame.size.height + searchBar.frame.size.height
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }
    
    func keyboardWillHide(_ notification: NSNotification) {
        if let animationDuration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval {
            bottomConstraint.constant = 0
            UIView.animate(withDuration: animationDuration, animations: {
                self.view.layoutIfNeeded()
            }, completion: { finished in
                
            })
        }
    }
    
    @IBAction func changePlace() {
        placeButtonsView.isHidden = true
        placeChooserView.isHidden = false
    }
    
    @IBAction func dateChanged(sender: UIDatePicker) {
        
    }
    
    @IBAction func makePlan() {
        if let reachable = isReachable(), reachable,
            let plan = plan {
            plan.date = datePicker.date
            if let event = plan.toEvent() {
                HUD.show(.labeledProgress(title: "Make Plan", subtitle: "Making plan..."))
                User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
                    HUD.show(.labeledSuccess(title: "Make Plan", subtitle: "Done!"))
                    HUD.hide(afterDelay: 1.0)
                    let analyticsEventParameters = [Constants.Analytics.Events.PlanMade.Parameters.id: event.id,
                                                    Constants.Analytics.Events.PlanMade.Parameters.screen: String(describing: type(of: self))]
                    Analytics.Log(event: Constants.Analytics.Events.EventRemoved.name, with: analyticsEventParameters)
                })
            }
        }
    }
    
    private func bindPlan() {
        if let plan = plan {
            datePicker.setDate(plan.date, animated: true)
            let attributedString = NSMutableAttributedString()
            if let name = plan.place.name {
                attributedString.append(NSMutableAttributedString(string: name, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
            }
            if let verificationStatus = plan.place.verificationStatus {
                let verifiedImage = NSTextAttachment()
                switch verificationStatus {
                case .blueVerified:
                    verifiedImage.image = #imageLiteral(resourceName: "blue_verified")
                case .grayVerified:
                    verifiedImage.image = #imageLiteral(resourceName: "gray_verified")
                default:
                    verifiedImage.image = nil
                }
                if verifiedImage.image != nil {
                    verifiedImage.bounds = CGRect(x: 0.0, y: planLabel.font.descender / 2.0, width: verifiedImage.image!.size.width, height: verifiedImage.image!.size.height)
                }
                attributedString.append(NSAttributedString(string: " ", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 17)]))
                attributedString.append(NSAttributedString(attachment: verifiedImage))
            }
            if let location = plan.place.location {
                attributedString.append(NSMutableAttributedString(string: "\n\(location.addressString)", attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 12)]))
            }
            planLabel.attributedText = attributedString
            //placeLabel.text = place?.location?.addressString
            thumbnailImageView.layer.cornerRadius = 12.0
            thumbnailImageView.layer.masksToBounds = true
            if let pictureURL = plan.place.pictureURL {
                thumbnailImageView.sd_setImage(with: pictureURL, placeholderImage: #imageLiteral(resourceName: "placeholder_40x40"), options: [.cacheMemoryOnly])
            } else {
                thumbnailImageView.image = #imageLiteral(resourceName: "placeholder_40x40")
            }
        }
    }
}

// MARK: - DZNEmptyDataSetSource

extension PlansViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Make a Plan", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Choose a date and a place\nDiscover people with the same plan!", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "plan")
    }
    
}

// MARK: - DZNEmptyDataSetDelegate
extension PlansViewController: DZNEmptyDataSetDelegate {
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
}

// MARK: - ReachabilityAware
extension PlansViewController: ReachabilityAware {
    func setReachabilityState(reachable: Bool) {
        searchBar.isUserInteractionEnabled = reachable
    }
    
    func checkReachability() {
        if let reachable = isReachable() {
            setReachabilityState(reachable: reachable)
        }
    }
    
    func reachabilityChanged(reachable: Bool) {
        setReachabilityState(reachable: reachable)
    }
}