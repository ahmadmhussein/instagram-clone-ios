import UIKit
import FirebaseFirestore
import FirebaseAuth

struct Message {
    let text: String
    let isSender: Bool
    let timestamp: Double
}

class ChatRoomViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    var messages: [Message] = []
    var receiverID: String?
    let db = Firestore.firestore()
    
    var chatRoomID: String? {
        guard let currentUID = Auth.auth().currentUser?.uid, let receiverUID = receiverID else { return nil }
        return currentUID < receiverUID ? "\(currentUID)_\(receiverUID)" : "\(receiverUID)_\(currentUID)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        
        loadMessages()
    }
    
    func loadMessages() {
        guard let roomID = chatRoomID else { return }
        
        db.collection("chats").document(roomID).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                self.messages = documents.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard let text = data["text"] as? String,
                          let senderID = data["senderID"] as? String,
                          let timestamp = data["timestamp"] as? Double else { return nil }
                    
                    let isSender = senderID == Auth.auth().currentUser?.uid
                    return Message(text: text, isSender: isSender, timestamp: timestamp)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    if !self.messages.isEmpty {
                        let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
                        self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            }
    }
    
    @IBAction func sendButtonTapped(_ sender: UIButton) {
        guard let text = messageTextField.text, !text.isEmpty,
              let roomID = chatRoomID,
              let currentUID = Auth.auth().currentUser?.uid else { return }
        
        messageTextField.text = ""
        
        let messageData: [String: Any] = [
            "text": text,
            "senderID": currentUID,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        db.collection("chats").document(roomID).collection("messages").addDocument(data: messageData) { error in
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        if message.isSender {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SenderCell", for: indexPath) as! SenderCell
            cell.messageLabel.text = message.text
            cell.bubbleView.layer.cornerRadius = 12
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiverCell", for: indexPath) as! ReceiverCell
            cell.messageLabel.text = message.text
            cell.bubbleView.layer.cornerRadius = 12
            return cell
        }
    }
}

class SenderCell: UITableViewCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
}

class ReceiverCell: UITableViewCell {
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
}
