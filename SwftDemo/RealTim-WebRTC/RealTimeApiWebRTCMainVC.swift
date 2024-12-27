

import UIKit
import WebRTC
import AVFoundation

class RealTimeApiWebRTCMainVC: UIViewController, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
    
    @IBOutlet weak var myVolumeView: UIView!
    @IBOutlet weak var statusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
    }
    func initUI(){
        statusButton.layer.borderWidth = 1.0
        statusButton.layer.borderColor = UIColor.blue.cgColor
        statusButton.layer.cornerRadius = 8
        
        //Monitor Audio Volum Change
        DispatchQueue.main.async {
            self.monitorAudioTrackLeval()
        }
    }
    //MARK: Handle Status
    var connect_status = "notConnect" // notConnect connecting connected
    @IBAction func clickStatusButton(_ sender: Any) {
        if connect_status == "notConnect"{
            connectWebSockt()
        }else if connect_status == "connecting"{
            MBProgressHUD.showTextWithTitleAndSubTitle(title: "Connecting, please try again later.", subTitle: "", view: view)
        }else if connect_status == "connected"{
            let alertVC = UIAlertController(title: "The WebRTC is connected, So do you want to disconnect it? ", message: "", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            let confirAction = UIAlertAction(title: "Confirm", style: .default) { alert in
                self.stopAll()
                self.connect_status = "notConnect"
                self.refreshStatusButtonUI()
            }
            alertVC.addAction(cancelAction)
            alertVC.addAction(confirAction)
            getCurrentVc().present(alertVC, animated: true)
        }
    }
    func refreshStatusButtonUI(){
        DispatchQueue.main.async {
            if self.connect_status == "notConnect"{
                self.statusButton.setTitle("Start With WebRTC", for: .normal)
                self.stopAll()
                self.audioVolumeView.removeFromSuperview()
            }else if self.connect_status == "connecting"{
                self.statusButton.setTitle("Connecting With WebRTC", for: .normal)
            }else if self.connect_status == "connected"{
                self.statusButton.setTitle("Connected With WebRTC", for: .normal)
            }
        }
    }
    //MARK: Connect WebSockt
    private var peerConnectionFactory: RTCPeerConnectionFactory?
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var dataChannel: RTCDataChannel?
    func connectWebSockt(){
        connect_status = "connecting"
        refreshStatusButtonUI()
        //1.OpenAI -- Get Secret Key
        getOpenAIWebSocketSecretKey { secretDict in
            print("getOpenAIWebSocketSecretKey -- \(secretDict)")
            //2.init WebRTC
            self.peerConnectionFactory = RTCPeerConnectionFactory.init()
            let config = RTCConfiguration()
            let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
            self.peerConnection = self.peerConnectionFactory?.peerConnection(with: config, constraints: constraints, delegate: self)
            
            //3.setup local audio
            let audioTrackSource = self.peerConnectionFactory?.audioSource(with: nil)
            self.audioTrack = self.peerConnectionFactory?.audioTrack(with: audioTrackSource!, trackId: "audio0")
            let stream = self.peerConnectionFactory?.mediaStream(withStreamId: "stream0")
            stream!.addAudioTrack(self.audioTrack!)
            self.peerConnection?.add(stream!)
            
            //4.creat data  channel
            let config1 = RTCDataChannelConfiguration()
            self.dataChannel = self.peerConnection?.dataChannel(forLabel: "oai-events", configuration: config1)
            self.dataChannel?.delegate = self
            
            //5.creat SDP Offer and connect backend
            self.createOffer { sdp in
                print("set local description -- success：\(sdp)")
                //6.send SDP to Open AI
                if let client_secret = secretDict["client_secret"] as? [String: Any],
                   let client_secret_value = client_secret["value"] as? String{
                    self.sendSDPToServer(sdp, clientSecret: client_secret_value) {
                        self.connect_status = "connected"
                        self.refreshStatusButtonUI()
                    } failBlock: {
                        self.connect_status = "notConnect"
                        self.refreshStatusButtonUI()
                    }
                }
            } failBlock: {
                print("creat offer -- fail")
                self.connect_status = "notConnect"
                self.refreshStatusButtonUI()
            }
        } failBlock: {
            print("getOpenAIWebSocketSecretKey -- fail")
            self.connect_status = "notConnect"
            self.refreshStatusButtonUI()
            
        }
    }
    func getOpenAIWebSocketSecretKey(successBlock: @escaping(([String: Any])->()), failBlock:@escaping(()->())){
        guard let url = URL(string: "https://api.openai.com/v1/realtime/sessions") else {
            failBlock()
            return
        }
        //MARK: You must replace the parameter here with your OpenAI key.
        let OPENAI_API_KEY = "*******************"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OPENAI_API_KEY)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
                    "model": "gpt-4o-realtime-preview-2024-12-17",
                    "voice": "verse"
                ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil{
                print("getOpenAIWebSocketSecretKey -- fail：\(String(describing: error?.localizedDescription))")
                failBlock()
                return
            }
            if data == nil{
                print("data is Null")
                failBlock()
                return
            }
            guard let jsonResponse_object = try? JSONSerialization.jsonObject(with: data!, options: .mutableContainers) else{
                failBlock()
                return
            }
            if let jsonResponse_Dict = jsonResponse_object as? [String: Any]{
                successBlock(jsonResponse_Dict)
            }else{
                failBlock()
            }
        }.resume()
    }
    func createOffer(successBlock: @escaping((RTCSessionDescription)->()), failBlock: @escaping(()->())){
       let sdpMandatoryConstraints = ["OfferToReceiveAudio": "true",
                                      "OfferToReceiveVideo": "true"
                                     ]
       let sdpConstraints = RTCMediaConstraints.init(mandatoryConstraints: sdpMandatoryConstraints, optionalConstraints: nil)
       self.peerConnection?.offer(for: sdpConstraints, completionHandler: { sdp, error in
           if error != nil{
               print("creat offer -- fail:\(String(describing: error?.localizedDescription))")
               failBlock()
               return
           }
           guard let sessionDescription = sdp else {
               print("creat offer -- fail: sdp is null")
               failBlock()
               return
           }
           self.peerConnection?.setLocalDescription(sessionDescription, completionHandler: { error1 in
               if error1 != nil{
                   print("set local description -- fail：\(String(describing: error1?.localizedDescription))")
                   failBlock()
                   return
               }
               //print("set local description -- success：\(sessionDescription)")
               successBlock(sessionDescription)
           })
       })
    }
    private func sendSDPToServer(_ sdp: RTCSessionDescription, clientSecret: String, successBlock: @escaping(()->()), failBlock: @escaping(()->())){
        guard let url = URL(string: "https://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview-2024-12-17") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(clientSecret)", forHTTPHeaderField: "Authorization")
        request.addValue("application/sdp", forHTTPHeaderField: "Content-Type")
        request.httpBody = sdp.sdp.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil{
                print("sendSDPToServer -- fail：\(String(describing: error?.localizedDescription))")
                failBlock()
                return
            }
            if data == nil{
                print("data is Null")
                failBlock()
                return
            }
            guard let remoteSDP = String(data: data!, encoding: .utf8) else {
                print("remoteSDP is Null")
                failBlock()
                return
            }
            // set up remote sdp
            let remoteDescription = RTCSessionDescription(type: .answer, sdp: remoteSDP)
            self.peerConnection?.setRemoteDescription(remoteDescription, completionHandler: { error1 in
                if let error1 = error1{
                    print("setup remote SDP fail: \(error1)")
                    failBlock()
                } else {
                    print("setup remote SDP success")
                    successBlock()
                }
            })
        }.resume()
    }
    //RTCPeerConnectionDelegate
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //print("RTCPeerConnectionDelegate---1")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        print("RTCPeerConnectionDelegate---2---connected stram with OpneAI form WebRTC")
        //play audio stream
        if let audioTrack = stream.audioTracks.first {
            print("Audio track received")
            let audioSession = AVAudioSession.sharedInstance()
            do{
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
                //print("Play sound — Set speaker — Success")
            }catch{
                //print("Play sound — Set speaker — Failure")
            }
        }else{
            print("Audio track not found")
        }
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        //print("RTCPeerConnectionDelegate---3")
    }
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //print("RTCPeerConnectionDelegate---4")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //print("RTCPeerConnectionDelegate---5")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //print("RTCPeerConnectionDelegate---6")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        //print("RTCPeerConnectionDelegate---7")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //print("RTCPeerConnectionDelegate---8")
    }
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        //print("RTCPeerConnectionDelegate---9")
    }
    //RTCDataChannelDelegate
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        //print("RTCDataChannelDelegate---11")
    }
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        //print("RTCDataChannelDelegate---22")
        print("Message received: Invalid message: \(String(data: buffer.data, encoding: .utf8) ?? "Invalid message")")
    }
    
    //Monitor Audio Volum Change
    var audioRecorder: AVAudioRecorder?
    var audioPeadkerChangeTimer: Timer?
    lazy var audioVolumeView = {
        let view = AudioVisualizerView(frame: CGRect(x: UIScreen.main.bounds.size.width/2-200/2, y: 30, width: 200, height: 100))
        return view
    }()
    func monitorAudioTrackLeval(){
        
        audioVolumeView.removeFromSuperview()
        self.myVolumeView.addSubview(audioVolumeView)
        
        //import AVFoundation
        let audioAuthStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
        if audioAuthStatus == AVAuthorizationStatus.notDetermined{
            AVAudioSession.sharedInstance().requestRecordPermission {granted in
                if granted{
                    print("User granted permission")
                    DispatchQueue.main.async {
                        self.monitorAudioTrackLeval()
                    }
                }else{
                    print("User denied permission")
                }
            }
            return
        }
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord)
        let settings = [
            AVSampleRateKey: NSNumber(floatLiteral: 44100.0),
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVNumberOfChannelsKey: NSNumber(value: 2),
            AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.max.rawValue)
        ]
        let url = URL(string: "/dev/null")//null address
        
        self.audioRecorder = try? AVAudioRecorder.init(url: url!, settings: settings)
        if self.audioRecorder == nil{
            print("init self.audioRecorder fail")
            return
        }
        self.audioRecorder?.isMeteringEnabled = true
        self.audioRecorder?.prepareToRecord()
        self.audioRecorder?.record()
        if self.audioPeadkerChangeTimer != nil{
            self.audioPeadkerChangeTimer?.invalidate()
            self.audioPeadkerChangeTimer = nil
        }
        //The range of peakPower is between -160 and 0, but based on my testing, background noise is generally below -40. So, I have decided to use the range of -40 to 0.
        self.audioPeadkerChangeTimer = Timer.init(timeInterval: 0.1, repeats: true, block: { timer in
            if self.audioRecorder?.isRecording == true{
                self.audioRecorder?.updateMeters()
                let peakPower = self.audioRecorder?.averagePower(forChannel: 0)
                var nowScale = 0.00
                if peakPower! <= -40.0{
                    nowScale = 0.00
                }else if peakPower! >= 0.0{
                    nowScale = 1.0
                }else{
                    nowScale = Double((peakPower! + 40)*2.5/100.0)
                }
                //print("Monitor Audio Volum Change--scale--\(nowScale)")
                DispatchQueue.main.async {
                    if self.connect_status == "connected"{
                        self.audioVolumeView.updateCircles(with: Float(nowScale))
                    }else{
                        self.audioVolumeView.updateCircles(with: Float(0))
                    }
                }
            }
        })
        RunLoop.current.add(self.audioPeadkerChangeTimer!, forMode: .common)
    }

    
    //MARK: 6.Back-->clear all about realTime
    @IBAction func clickBackButton(_ sender: Any) {
        peerConnection?.close()
        dataChannel?.close()
        audioRecorder?.stop()
        audioRecorder = nil
        dismiss(animated: true)
    }
    func stopAll(){
        peerConnection?.close()
        dataChannel?.close()
        audioRecorder?.stop()
        audioRecorder = nil
    }
}
