import AVFoundation

class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = SpeechService()
    private let synthesizer = AVSpeechSynthesizer()
    
    private override init() {
        super.init()
        synthesizer.delegate = self
        print("SpeechService initialized")
        
        // Test speech at initialization
//        let testUtterance = AVSpeechUtterance(string: "Speech service is ready")
//        testUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
//        synthesizer.speak(testUtterance)
    }
    
    func speak(_ text: String) {
        print("Attempting to speak: \(text)")
        
        // Stop any ongoing speech
        if synthesizer.isSpeaking {
            print("Stopping current speech")
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0
        
        print("Using voice: \(utterance.voice?.language ?? "No voice selected")")
        synthesizer.speak(utterance)
        print("Speech request sent")
    }
    
    // Delegate methods for debugging
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        print("Speech started")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        print("Speech finished")
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        print("Speech cancelled")
    }
} 
