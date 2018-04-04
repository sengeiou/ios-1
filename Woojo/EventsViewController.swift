//
//  EventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 03/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import RxSwift
import DZNEmptyDataSet
import PKHUD
import FacebookCore

class EventsViewController: UITableViewController {
    
    var events: [String: [Event]] = [:]
    var months: [String] = []
    var disposeBag = DisposeBag()
    var reachabilityObserver: AnyObject?
    //@IBOutlet weak var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var tipView: UIView!
    @IBOutlet weak var dismissTipButton: UIButton!
    let tipId = "eventFilter"
    var pendingEventsCount = 0
    var scrolled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "EventsTableViewCell", bundle: nil), forCellReuseIdentifier: "eventCell")
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        setupDataSource()
        tableView.tableFooterView = UIView()
        
        //longPressGestureRecognizer.addTarget(self, action: #selector(longPress))
        let imageView = UIImageView(image: #imageLiteral(resourceName: "close"))
        imageView.frame = CGRect(x: dismissTipButton.frame.width/2.0, y: dismissTipButton.frame.height/2.0, width: 10, height: 10)
        dismissTipButton.addSubview(imageView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.showSettingsButton()
        let settingsButton = self.navigationItem.rightBarButtonItem?.customView as? UIButton
        settingsButton?.addTarget(self, action: #selector(showSettings(sender:)), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startMonitoringReachability()
        checkReachability()
        User.current.value?.activity.setLastSeen()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CurrentUser.Notification.deleteAll(type: "events")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopMonitoringReachability()
    }
    
    func setupDataSource() {
        User.current.asObservable()
            .flatMap { user -> Observable<[Event]> in
                if let currentUser = user {
                    if let tips = user?.tips, tips[self.tipId] != nil {
                        self.tableView.tableHeaderView = nil
                    }
                    return currentUser.events.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .subscribe(onNext: { events in
                self.events = events.group(by: { $0.monthString })
                self.months = Array(self.events.keys).sorted().reversed()
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                    self.scrollToNow()
                })
                Analytics.setUserProperties(properties: ["event_count": String(events.count)])
            }).disposed(by: disposeBag)
        
        /* User.current.asObservable()
            .flatMap { user -> Observable<[Event]> in
                if let currentUser = user {
                    return currentUser.pendingEvents.asObservable()
                } else {
                    return Variable([]).asObservable()
                }
            }
            .subscribe(onNext: { pendingEvents in
                self.pendingEventsCount = pendingEvents.count
                //self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                self.tableView.reloadData()
            }).disposed(by: disposeBag) */
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func scrollToNow() {
        if !self.scrolled {
            if let month = self.months.reversed().first(where: {
                if let current = Int($0), let reference = Int(Event.sectionDateFormatter.string(from: Date())) {
                    return current >= reference
                }
                return false
            }), let index = self.months.index(of: month) {
                let indexPath = IndexPath(row: 0, section: index)
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
                self.scrolled = true
            }
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return months.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        /* if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "pendingEventsInfoCell", for: indexPath) as! PendingEventsInfoTableViewCell
            cell.infoLabel.text = "You have \(pendingEventsCount) new event\((pendingEventsCount > 1) ? "s" : "") on Facebook"
            cell.actionLabel.text = "Add \((pendingEventsCount > 1) ? "them" : "it") to discover new people!"
            cell.borderView.layer.borderWidth = 1.0
            cell.borderView.layer.borderColor = UIColor.lightGray.cgColor
            cell.borderView.layer.cornerRadius = 12.0
            cell.borderView.layer.masksToBounds = true
            return cell
        } else { */
            let cell = tableView.dequeueReusableCell(withIdentifier: "eventCell", for: indexPath) as! EventsTableViewCell
            cell.event = self.events[months[indexPath.section]]?[indexPath.row]
            return cell
        // }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        /* if section == 0 {
            if pendingEventsCount > 0 {
                return 1
            } else {
                return 0
            }
        } else if section == 1 {
            return events.count
        } else {
            return 0
        } */
        return events[months[section]]?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let monthAsDate = Event.sectionDateFormatter.date(from: months[section]) {
            return Event.sectionHumanDateFormatter.string(from: monthAsDate).capitalized
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Remove", comment: ""), handler: { action, indexPath in
            self.removeEvent(at: indexPath)
        })
        return [deleteAction]
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /* if indexPath.section == 0 {
            
        } else if indexPath.section == 1 { */
            let eventDetailsViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "EventDetailsViewController") as! EventDetailsViewController
            eventDetailsViewController.event = events[months[indexPath.section]]?[indexPath.row]
            eventDetailsViewController.event?.loadMatches {
                self.navigationController?.pushViewController(eventDetailsViewController, animated: true)
            }
        // }
    }
    
    @IBAction func dismissTip() {
        Woojo.User.current.value?.dismissTip(tipId: self.tipId)
        UIView.beginAnimations("foldHeader", context: nil)
        self.tableView.tableHeaderView = nil
        UIView.commitAnimations()
    }
    
    @IBAction func ignorePendingEvents() {
        User.current.value?.removeAllPendingEvents(completion: nil)
    }
    
    func removeEvent(at indexPath: IndexPath) {
        if let cell = self.tableView.cellForRow(at: indexPath) as? EventsTableViewCell, let event = cell.event {
            HUD.show(.labeledProgress(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Removing event...", comment: "")))
            User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
                let analyticsEventParameters = ["event_id": event.id,
                                                "origin": "filter"]
                Analytics.Log(event: "Events_event_removed", with: analyticsEventParameters)
                HUD.show(.labeledSuccess(title: NSLocalizedString("Remove Event", comment: ""), subtitle: NSLocalizedString("Event removed!", comment: "")))
                HUD.hide(afterDelay: 1.0)
            })
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if let reachable = isReachable(), reachable {
            return true
        } else { return false }
    }
    
    /*func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizerState.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                let actionSheetController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let removeButton = UIAlertAction(title: "Remove", style: .destructive, handler: { (action) -> Void in
                    self.removeEvent(at: indexPath);
                })
                let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                actionSheetController.addAction(removeButton)
                actionSheetController.addAction(cancelButton)
                actionSheetController.popoverPresentationController?.sourceView = self.view
                self.present(actionSheetController, animated: true, completion: nil)
            }
        }
    }*/
    
}

extension EventsViewController: ShowsSettingsButton {
    
    @objc func showSettings(sender : Any?) {
        if let settingsNavigationController = self.storyboard?.instantiateViewController(withIdentifier: "SettingsNavigationController") {
            self.present(settingsNavigationController, animated: true, completion: nil)
        }
    }
    
}

extension EventsViewController: DZNEmptyDataSetSource {
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("No Events Yet", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: NSLocalizedString("Click the + button to add events", comment: ""), attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "events")
    }
    
}

extension EventsViewController: DZNEmptyDataSetDelegate {
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}

extension EventsViewController: ReachabilityAware {
    
    func setReachabilityState(reachable: Bool) {
        if reachable {
            
        } else {
            tableView.setEditing(false, animated: true)
        }
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
