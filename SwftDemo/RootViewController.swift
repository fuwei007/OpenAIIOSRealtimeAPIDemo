
import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var startSessionButton: UIButton!
    
    
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(openAiStatusChanged), name: NSNotification.Name(rawValue: "WebSocketManager_connected_status_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserStartToSpeek), name: NSNotification.Name(rawValue: "UserStartToSpeek"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveInputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveInputText"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveOutputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveOutputText"), object: nil)
    }
    //MARK: 1.Connect to OpenAI – Create Session
    @IBAction func clickStartSessionButton(_ sender: Any) {
        WebSocketManager.shared.connectWebSocketOfOpenAi()
    }
    //WebSocket connection state changed：
    @objc func openAiStatusChanged(){
        if WebSocketManager.shared.connected_status == "not_connected"{
            startSessionButton.setTitle("Open AI: not_connected", for: .normal)
        }else
        if WebSocketManager.shared.connected_status == "connecting"{
            startSessionButton.setTitle("Open AI: connecting", for: .normal)
        }else
        if WebSocketManager.shared.connected_status == "connected"{
            startSessionButton.setTitle("Open AI: connected", for: .normal)
           
        }else{
            startSessionButton.setTitle("", for: .normal)
        }
    }
    //User Start To Speek
    @objc func UserStartToSpeek(){
        self.inputTextView.text = ""
        self.outputTextView.text = ""
    }
    //Update Input Text
    @objc func HaveInputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: Any] {
            if let transcript = dict["text"] as? String{
                self.inputTextView.text = transcript
            }
        }
    }
    //Update Output Text
    @objc func HaveOutputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: String] {
            if let transcript = dict["text"] as? String {
                self.outputTextView.text = transcript
            }
        }
        
    }
}

