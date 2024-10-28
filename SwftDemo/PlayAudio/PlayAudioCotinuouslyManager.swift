
import UIKit
import AVFoundation

class PlayAudioCotinuouslyManager: NSObject {

    static let shared = PlayAudioCotinuouslyManager()
    private override init(){
        super.init()
        initParm()
    }

    func initParm() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        let timePitchNode = AVAudioUnitTimePitch()
        timePitchNode.rate = 1
        audioEngine.attach(playerNode)
        audioEngine.attach(timePitchNode)
        
        //Must == 24000
        let customSampleRate = Double(24000)
        audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: customSampleRate, channels: 1, interleaved: false)
        audioEngine.connect(playerNode, to: timePitchNode, format: audioFormat)
        audioEngine.connect(timePitchNode, to: audioEngine.mainMixerNode, format: audioFormat)
            
        try? audioEngine.start()
        playerNode.play()
    }

    var isPauseAudio = false
    var audioEngine: AVAudioEngine!
    var playerNode: AVAudioPlayerNode!
    var audioFormat: AVAudioFormat!
    var audio_event_Queue = [[String: Any]]()
    
    func playAudio(eventInfo: [String: Any]) {
        audio_event_Queue.append(eventInfo)
        if audio_event_Queue.count == 1 {
            playNextAudio()
        }
    }
    
    private func playNextAudio() {
        if isPauseAudio{
            return
        }
        if audio_event_Queue.count <= 0 {
            return
        }
        let firstAudioInfo = audio_event_Queue[0]
        let base64String = firstAudioInfo["delta"] as? String ?? ""
        //let index = firstAudioInfo["index"] as? Int ?? 0
        guard let pcmData = Data(base64Encoded: base64String) else {
            audio_event_Queue.removeFirst()
            playNextAudio()
            return
        }
       
        let int16Count = pcmData.count / MemoryLayout<Int16>.size
        let frameCapacity = int16Count
        guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(frameCapacity)) else {
            audio_event_Queue.removeFirst()
            playNextAudio()
            return
        }
        buffer.frameLength = AVAudioFrameCount(frameCapacity)
 
        pcmData.withUnsafeBytes { rawBufferPointer in
        guard let int16Pointer = rawBufferPointer.baseAddress?.assumingMemoryBound(to: Int16.self) else {
            return
        }
        
        //Increase the volume by two times.
        var audioSamples: [Int16] = Array(UnsafeBufferPointer(start: int16Pointer, count: frameCapacity))
        let amplificationFactor: Float = 3.0  //Amplification factor
        let maxAmplitude: Int16 = Int16.max
        let minAmplitude: Int16 = Int16.min
        for i in 0..<audioSamples.count {
            let amplifiedSample = Float(audioSamples[i]) * amplificationFactor
            if amplifiedSample > Float(maxAmplitude) {
                audioSamples[i] = maxAmplitude
            } else if amplifiedSample < Float(minAmplitude) {
                audioSamples[i] = minAmplitude
            } else {
                audioSamples[i] = Int16(amplifiedSample)
            }
        }
        //Float32-->Int16
        let floatPointer = buffer.floatChannelData?[0]
            for i in 0..<int16Count {
                floatPointer?[i] = Float(audioSamples[i]) / 32768.0
            }
        }
        playerNode.scheduleBuffer(buffer) {
            if self.audio_event_Queue.count > 0{
                self.audio_event_Queue.removeFirst()
            }
            self.playNextAudio()
        }
    }
 }

    
    
    

