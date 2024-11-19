
import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var startSessionButton: UIButton!
    @IBOutlet weak var discconnectAIButton: UIButton!
    @IBOutlet weak var inputTextView: UITextView!
    @IBOutlet weak var outputTextView: UITextView!
    @IBOutlet weak var monitorAudioDataView: UIView!
    
    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame: CGRect(x: UIScreen.main.bounds.size.width/2-200/2, y: 30, width: 200, height: 100))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(openAiStatusChanged), name: NSNotification.Name(rawValue: "WebSocketManager_connected_status_changed"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(UserStartToSpeek), name: NSNotification.Name(rawValue: "UserStartToSpeek"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveInputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveInputText"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(HaveOutputText(notifiction:)), name: NSNotification.Name(rawValue: "HaveOutputText"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(showMonitorAudioDataView(notification:)), name: NSNotification.Name(rawValue: "showMonitorAudioDataView"), object: nil)
        
        monitorAudioDataView.addSubview(audioVolumeView)
    }
    //MARK: 1.Connect to OpenAI – Create Session
    @IBAction func clickStartSessionButton(_ sender: Any) {
        WebSocketManager.shared.connectWebSocketOfOpenAi()
    }
    //WebSocket connection state changed：
    @objc func openAiStatusChanged(){
        if WebSocketManager.shared.connected_status == "not_connected"{
            startSessionButton.setTitle("Open AI: not_connected", for: .normal)
            discconnectAIButton.isHidden = true
        }else
        if WebSocketManager.shared.connected_status == "connecting"{
            startSessionButton.setTitle("Open AI: connecting", for: .normal)
            discconnectAIButton.isHidden = true
        }else
        if WebSocketManager.shared.connected_status == "connected"{
            startSessionButton.setTitle("Open AI: connected", for: .normal)
            discconnectAIButton.isHidden = false
        }else{
            startSessionButton.setTitle("", for: .normal)
            discconnectAIButton.isHidden = true
        }
    }
    //MARK: 2.Disconnect Open AI
    @IBAction func clickDisConnecteButton(_ sender: Any) {
        let alertVC = UIAlertController(title: "The websocket is connected, So do you want to disconnect it? ", message: "", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        let confirAction = UIAlertAction(title: "Confirm", style: .default) { alert in
            //stop play audio
            WebSocketManager.shared.audio_String = ""
            WebSocketManager.shared.audio_String_count = 0
            PlayAudioCotinuouslyManager.shared.audio_event_Queue.removeAll()
            //pause captrue audio
            RecordAudioManager.shared.pauseCaptureAudio()
            //Disconnect websockt--It will recieve .peerClosed and cancelled
            WebSocketManager.shared.socket.disconnect()
        }
        alertVC.addAction(cancelAction)
        alertVC.addAction(confirAction)
        getCurrentVc().present(alertVC, animated: true)
    }
    //User start to speak
    @objc func UserStartToSpeek(){
        self.inputTextView.text = ""
        self.outputTextView.text = ""
    }
    
    //MARK: 3.What I am talking.
    @objc func HaveInputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: Any] {
            if let transcript = dict["text"] as? String{
                self.inputTextView.text = transcript
            }
        }
    }
    
    //MARK: 4.OpenAI response
    @objc func HaveOutputText(notifiction: Notification){
        if let dict = notifiction.object as? [String: String] {
            if let transcript = dict["text"] as? String {
                self.outputTextView.text = transcript
            }
        }
    }
    
    //MARK: 5.Show View Of Monitoring Audio Data
    @objc func showMonitorAudioDataView(notification: Notification){
        if let dict = notification.object as? [String: Any] {
            if let rmsValue = dict["rmsValue"] as? Float{
                print("此时的音频音量为:\(rmsValue)")
                DispatchQueue.main.async {
                    self.audioVolumeView.updateCircles(with: rmsValue)
                }
            }
        }
    }
    
}

