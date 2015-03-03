//
//  InviteTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/24/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class InviteTableViewController: UITableViewController, UISearchBarDelegate, UISearchDisplayDelegate {

    let addressBook = APAddressBook()
    var arraycontacts:NSArray = []
    // var filteredContacts:NSArray = []
    // var filteredContacts: [AnyObject] = []
    var sharedInstance = VideoDataToAPI.sharedInstance
    var tagsLabel:UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.addressBook.fieldsMask = APContactField.Default | APContactField.Thumbnail
        self.addressBook.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true),
            NSSortDescriptor(key: "lastName", ascending: true)]
        self.addressBook.filterBlock = {(contact: APContact!) -> Bool in
            return contact.phones.count > 0
        }
        self.addressBook.loadContacts(
            { (contacts: [AnyObject]!, error: NSError!) in
                if (contacts != nil) {
                    println(contacts)
                    self.arraycontacts = contacts
                    self.setupFriendModelData()
                    self.tableView.reloadData()
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        }) // self.addressBook.loadContacts()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if tableView == self.searchDisplayController!.searchResultsTableView {
            println("I'm always here")
            return self.sharedInstance.filteredContacts.count
        } else {
            return self.sharedInstance.friendsList.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("InviteCell") as InviteUITableViewCell
        var friend:FriendModel
        if tableView == self.searchDisplayController!.searchResultsTableView {
            friend = self.sharedInstance.filteredContacts[indexPath.row] as FriendModel
        } else {
            friend = self.sharedInstance.friendsList[indexPath.row] as FriendModel
        }
    
        cell.phoneNumber.text = friend.name
        self.processTagsLabel(self.sharedInstance.taggedFriends)

        if (friend.tagged == true) {
            cell.friendSelected.image = UIImage(named:("starwithvotes"))
        } else {
             cell.friendSelected.image = nil
        }
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let indexPath = tableView.indexPathForSelectedRow();
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as InviteUITableViewCell
        
        var friend:FriendModel
        if tableView == self.searchDisplayController!.searchResultsTableView {
            let foundfriend = self.sharedInstance.filteredContacts[indexPath!.row] as FriendModel
            var arraypoint = filter(self.sharedInstance.friendsList) { $0 as NSObject == foundfriend as FriendModel }
            friend = arraypoint[0] as FriendModel
            println("yo")
        } else {
            friend = self.sharedInstance.friendsList[indexPath!.row] as FriendModel
        }
        
        
        // var friend:FriendModel = self.sharedInstance.friendsList[indexPath!.row] as FriendModel
        
        if (friend.tagged == true) {
            friend.tagged = false
            currentCell.friendSelected.image = nil
            currentCell.friendChecked = false
            sharedInstance.taggedFriends.removeObject(friend)
            self.processTagsLabel(sharedInstance.taggedFriends)
        } else {
            friend.tagged = true
            sharedInstance.taggedFriends.addObject(friend)
            self.processTagsLabel(sharedInstance.taggedFriends)
            currentCell.friendChecked = true
            currentCell.friendSelected.image = UIImage(named:("starwithvotes"))
        }
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        self.sharedInstance.sharedCell = self.tableView.dequeueReusableCellWithIdentifier("CustomHeader") as CustomHeaderUITableViewCell
        tagsLabel = self.sharedInstance.sharedCell.tagsLabel
        tagsLabel?.adjustsFontSizeToFitWidth = true
        self.processTagsLabel(self.sharedInstance.taggedFriends)

        return self.sharedInstance.sharedCell
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.processTagsLabel(self.sharedInstance.taggedFriends)
        self.tableView.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        self.processTagsLabel(self.sharedInstance.taggedFriends)
        self.tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.processTagsLabel(self.sharedInstance.taggedFriends)
        self.tableView.reloadData()
    }
    
    
    /* Search Code
    Implemented via http://www.raywenderlich.com/76519/add-table-view-search-swift
    UISearchDisplayControllerDelegate methods
    */
    
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        var array: [AnyObject] = self.sharedInstance.friendsList
        self.sharedInstance.filteredContacts = array.filter(){
            return $0.name.hasPrefix(searchText)
        }
        println(self.sharedInstance.filteredContacts.count)
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filterContentForSearchText(searchString)
        return true
    }
    
    func searchDisplayController(controller: UISearchDisplayController!, shouldReloadTableForSearchScope searchOption: Int) -> Bool {
        self.filterContentForSearchText(self.searchDisplayController!.searchBar.text)
        return true
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func clickBack(sender: AnyObject) {
        self.sharedInstance.userIsAddingFriends = false
        NSNotificationCenter.defaultCenter().postNotificationName(didClickToNavigateBackToCamera, object: self)
    }
    
    @IBAction func clickUpload(sender: AnyObject) {
        var delegate:sendVideoProtocol = SharedViewData.sharedInstance.cameraViewController
        delegate.sendVideo()
    }
    
    func contactName(contact :APContact) -> String {
        if contact.firstName != nil && contact.lastName != nil {
            return "\(contact.firstName) \(contact.lastName)"
        }
        else if contact.firstName != nil || contact.lastName != nil {
            return (contact.firstName != nil) ? "\(contact.firstName)" : "\(contact.lastName)"
        }
        else {
            return "Unnamed contact"
        }
    }
    
    func contactPhones(contact :APContact) -> NSArray {
        // changed return from string to NSArray
        if let phones = contact.phones {
            let array = phones as NSArray
            // return array.componentsJoinedByString(" ")
            return array
        }
        return []
        //return "No phone"
    }
    
    func contactPhonesString(contact :APContact) -> String {
        if let phones = contact.phones {
            var array = phones as NSArray
            return array.componentsJoinedByString(" ")
        }
        //return []
        return "nophone"
    }
    
    func contactEmails(contact :APContact) -> NSArray {
        // changed return from string to NSArray
        if let emails = contact.emails {
            let array = emails as NSArray
            // return array.componentsJoinedByString(" ")
            return array
        }
        return []
        //return "No phone"
    }
    
    func processTagsLabel(friends:NSArray)-> NSString {
        var theString:String = ""
        var myFriends:[FriendModel] = friends as [FriendModel]
        for friend in myFriends {
            if (theString == "") {
                theString = theString + " " + friend.name
            } else {
                theString = theString + ", " + friend.name
            }
        }
        self.tagsLabel!.text = theString
        return theString
    }
    
    func setupFriendModelData(){
        
        for contact in arraycontacts {
            let contact = contact as APContact
            // Configure the cell...
            var name = self.contactName(contact)
            var phoneString = self.contactPhonesString(contact)
            if (name == "Unnamed contact") {
            } else {
                var info = name + " " + phoneString + ":"
                var friend = FriendModel(
                    name: name,
                    phone: self.contactPhones(contact),
                    email: self.contactEmails(contact),
                    phoneString: info
                )
                self.sharedInstance.friendsList.addObject(friend)
            }
        }
    } // setupFriendModelData

}
