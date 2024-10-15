
import Foundation
import UIKit

var currentMBProgressHUD: MBProgressHUD?
var HUD_Duration_Long_fail = 20.0
extension MBProgressHUD {
    class func showJuHuaGifImage(view: UIView){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = true//true: other UI in view is clicked invalid
        currentMBProgressHUD = hud
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+HUD_Duration_Long_fail) {
            for value in view.subviews{
                if value == hud{
                    if hud.isHidden == false{
                        removeCurrentMBProgressHUD()
                    }
                }
            }
        }
    }
    class func removeCurrentMBProgressHUD(){
        DispatchQueue.main.async {
            guard let nowMBProgressHUD  = currentMBProgressHUD else{return}
            nowMBProgressHUD.hide(animated: true)
            currentMBProgressHUD = nil
        }
    }
    class func showTextWithTitleAndSubTitle(title: String, subTitle: String, view: UIView){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.label.numberOfLines = 0
        hud.detailsLabel.text = subTitle
        hud.detailsLabel.numberOfLines = 0
        hud.hide(animated: true, afterDelay: 4.0)
    }
    class func ShowSuccessMBProgresssHUD(view: UIView, title: String, block:@escaping()->()){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.label.numberOfLines = 0
        hud.hide(animated: true, afterDelay: 1.5)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+1.5) {
            block()
        }
    }
    
    class func showJuHuaGifImageLongLongTime(view: UIView){
        var hud = MBProgressHUD()
        hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = true//true: other UI in view is clicked invalid
        currentMBProgressHUD = hud
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+10*60) {
            //如果10秒钟后还在，那就直接消失
            for value in view.subviews{
                if value == hud{
                    if hud.isHidden == false{
                        removeCurrentMBProgressHUD()
                    }
                }
            }
        }
    }
    class func showTextWithTitleAndSubTitleWithShortTime(title: String, subTitle: String, view: UIView){
        let hud = MBProgressHUD.showAdded(to: view, animated: true)
        hud.isUserInteractionEnabled = false
        hud.mode = .text
        hud.label.text = title
        hud.label.numberOfLines = 0
        hud.detailsLabel.text = subTitle
        hud.detailsLabel.numberOfLines = 0
        hud.offset = CGPoint(x: 0, y: UIScreen.main.bounds.size.height/3)
        hud.hide(animated: true, afterDelay: 3.0)
    }
}
