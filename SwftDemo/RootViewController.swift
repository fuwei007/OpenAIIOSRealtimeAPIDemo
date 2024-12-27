
import UIKit

class RootViewController: UIViewController {

    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
    }
    
    func initUI(){
        firstButton.layer.borderWidth = 1.0
        firstButton.layer.borderColor = UIColor.black.cgColor
        firstButton.layer.cornerRadius = 8
        
        secondButton.layer.borderWidth = 1.0
        secondButton.layer.borderColor = UIColor.black.cgColor
        secondButton.layer.cornerRadius = 8
    }
    
    @IBAction func clickWebSocketButton(_ sender: Any) {
        let vc = RealTimeApiWebSocketMainVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @IBAction func clickWebRTCButton(_ sender: Any) {
        let vc = RealTimeApiWebRTCMainVC()
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
}
