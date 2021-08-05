//
//  ChatViewController.swift
//  ChatAppIOS
//
//  Created by chekir walid on 4/8/2021.
//

import UIKit
import Firebase

class ChatViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    var messages : [Message] = []
    let db = Firestore.firestore()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self //to can insert data in tableview by UITableViewDataSource
        
        title = K.appName
        navigationItem.hidesBackButton = true //hide back button in the navigation item
        
        tableView.register(UINib(nibName: K.cellNibName, bundle: nil), forCellReuseIdentifier: K.cellIdentifier)//nibName is the name of the file K.cellNibName =  MessageCell for the design of the message
        //forCellReuseIdentifier is the identifier of the ReusableCell = K.cellIdentifier
        loadMessages()
    }
    
    func loadMessages() {
        messages = []
        //addSnapshotListener  listen for realtime updates or getDocument is get data for only once
        db.collection(K.FStore.collectionName).order(by: K.FStore.dateField).addSnapshotListener { QuerySnapshot, Error in
            if let e = Error {
                print("There was an issue retrieving data from Firestore. \(e)")
            } else {
                self.messages = []
                if let snapshotDocuments = QuerySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data() //["body": how are you ?, "sender": walid@gmail.com]
                        if let messageSender = data[K.FStore.senderField] as? String, let messageBody = data[K.FStore.bodyField] as? String {// as? or as! down cast
                            let newMessage = Message(sender: messageSender, body: messageBody)
                            self.messages.append(newMessage)
                            DispatchQueue.main.async {//update our table view
                                self.tableView.reloadData()
                                //to scroll down automaticaly when send msg or many msg display
                                let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
                            }
                        }// endIf
                    }//endFor
                }//endIF
            }
        }
    }
    
    @IBAction func SenderButtonPressed(_ sender: UIButton) {
        if let messageBody = messageTextField.text, let messageSender = Auth.auth().currentUser?.email{
            db.collection(K.FStore.collectionName).addDocument(data: [
                K.FStore.senderField: messageSender,
                K.FStore.bodyField: messageBody,
                K.FStore.dateField: Date().timeIntervalSince1970
            ]) { error in
                if let e = error {
                    print("There was an issue saving data to firestore, \(e)")
                } else {
                    print("Successfully saved data.")
                    DispatchQueue.main.async {
                        self.messageTextField.text = ""
                    }
                }//endElse
            }
        }//end if
    }
    
    @IBAction func LogOutButtonPressed(_ sender: UIBarButtonItem) {
      do {
        try Auth.auth().signOut()
        navigationController?.popToRootViewController(animated: true)//navigate to the first view launch by the app
      } catch let signOutError as NSError {
        print("Error signing out: %@", signOutError)
      }
    }
}

extension ChatViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: K.cellIdentifier, for: indexPath) as! MessageCell //cell of table and as! MessageCell  to get the design as! to cast the type or convert to the sub class its the down cast
        //and  as to up cast to parent class
        // as! to down cast to child class
        cell.label.text = messages[indexPath.row].body //label in the Message cell created
        
        if messages[indexPath.row].sender == Auth.auth().currentUser?.email {
            cell.leftImageView.isHidden = true
            cell.rightImageView.isHidden = false
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.lightPurple)
            cell.label.textColor = UIColor(named: K.BrandColors.purple)
        } else {
            cell.leftImageView.isHidden = false
            cell.rightImageView.isHidden = true
            cell.messageBubble.backgroundColor = UIColor(named: K.BrandColors.purple)
            cell.label.textColor = UIColor(named: K.BrandColors.lightPurple)
        }
        
        return cell
    }
    
    
}
