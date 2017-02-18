//
//  MyEventsTableViewController.swift
//  Woojo
//
//  Created by Edouard Goossens on 08/11/2016.
//  Copyright © 2016 Tasty Electrons. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import DZNEmptyDataSet
import PKHUD

class MyEventsTableViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    
    var events: [Event] = []
    let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 100
        tableView.register(UINib(nibName: "MyEventsTableViewCell", bundle: nil), forCellReuseIdentifier: "fbEventCell")
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(loadFacebookEvents), for: UIControlEvents.valueChanged)
        
        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self
        
        loadFacebookEvents()
        
        Woojo.User.current.value?.events.asObservable().subscribe(onNext: { _ in
            self.tableView.reloadData()
        }).addDisposableTo(disposeBag)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if events.count == 0 {
            loadFacebookEvents()
        }
    }

    func loadFacebookEvents() {
        Woojo.User.current.value?.getEventsFromFacebook { events in
            self.events = events
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
            self.tableView.backgroundView?.isHidden = self.events.count > 0
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        
        if events.count > 0 {
            return 1
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fbEventCell", for: indexPath) as! MyEventsTableViewCell
        cell.event = self.events[indexPath.row]
        if let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == cell.event?.id }) {
            cell.checkView.isHidden = !isUserEvent
        }
        return cell
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Tapped")
        let event = self.events[indexPath.row]
        if let isUserEvent = Woojo.User.current.value?.events.value.contains(where: { $0.id == event.id }) {
            print(isUserEvent)
            if let cell = tableView.cellForRow(at: indexPath) as? MyEventsTableViewCell {
                if isUserEvent {
                    HUD.show(.labeledProgress(title: "Remove Event", subtitle: "Removing event..."))
                    Woojo.User.current.value?.remove(event: event, completion: { (error: Error?) -> Void in
                        cell.checkView.isHidden = true
                        tableView.reloadRows(at: [indexPath], with: .none)
                        HUD.show(.labeledSuccess(title: "Remove Event", subtitle: "Event removed!"))
                        HUD.hide(afterDelay: 1.0)
                    })
                } else {
                    HUD.show(.labeledProgress(title: "Add Event", subtitle: "Adding event..."))
                    Woojo.User.current.value?.add(event: event, completion: { (error: Error?) -> Void in
                        cell.checkView.isHidden = false
                        tableView.reloadRows(at: [indexPath], with: .none)
                        HUD.show(.labeledSuccess(title: "Add Event", subtitle: "Event added!"))
                        HUD.hide(afterDelay: 1.0)
                    })
                }
            }
        }
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "My Events", attributes: Constants.App.Appearance.EmptyDatasets.titleStringAttributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        return NSAttributedString(string: "Events you're marked as \"going to\" or \"interested in\" on Facebook appear here. Only events from the past month or in the future are shown.\n\nPull to refresh", attributes: Constants.App.Appearance.EmptyDatasets.descriptionStringAttributes)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return #imageLiteral(resourceName: "my_events")
    }
    
    func emptyDataSetShouldAllowScroll(_ scrollView: UIScrollView!) -> Bool {
        return true
    }
    
}
