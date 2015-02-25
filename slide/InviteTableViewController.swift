//
//  InviteTableViewController.swift
//  slide
//
//  Created by Justin Zollars on 2/24/15.
//  Copyright (c) 2015 rmb. All rights reserved.
//

import UIKit

class InviteTableViewController: UITableViewController {

    let addressBook = APAddressBook()
    var arraycontacts:NSArray = []
    var taggedFriends: NSMutableArray = [] // This is the array that contains friends I'm tagging
    var friendsList: NSMutableArray = []
    
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
                    self.tableView.reloadData()
                }
                else if (error != nil) {
                    let alert = UIAlertView(title: "Error", message: error.localizedDescription,
                        delegate: nil, cancelButtonTitle: "OK")
                    alert.show()
                }
        }) // self.addressBook.loadContacts()

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
        println("self.arraycontacts.count")
        println(self.arraycontacts.count)
        return self.arraycontacts.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("InviteCell") as InviteUITableViewCell
        let contact: APContact = arraycontacts[indexPath.row] as APContact
        // Configure the cell...
        var friend = FriendModel(
            name: self.contactName(contact),
            phone: self.contactPhones(contact),
            email: self.contactEmails(contact)
        )
        friendsList.addObject(friend)
        cell.phoneNumber.text = self.contactName(contact)
        return cell
    }
    
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let indexPath = tableView.indexPathForSelectedRow();
        let currentCell = tableView.cellForRowAtIndexPath(indexPath!) as InviteUITableViewCell
        var friend:FriendModel = friendsList[indexPath!.row] as FriendModel
        
        if (currentCell.friendChecked) {
            currentCell.friendSelected.image = nil
            currentCell.friendChecked = false
            taggedFriends.removeObject(friend)
        } else {
            taggedFriends.addObject(friend)
            currentCell.friendChecked = true
            currentCell.friendSelected.image = UIImage(named:("starwithvotes"))
        }
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

}
