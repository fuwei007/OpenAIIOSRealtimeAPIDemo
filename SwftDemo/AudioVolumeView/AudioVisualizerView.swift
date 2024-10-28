

import UIKit

class AudioVisualizerView: UIView {
        var circleViews: [UIView] = []
        override init(frame: CGRect) {
            super.init(frame: frame)
            self.backgroundColor =  .clear
            setupCircles()
        }
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupCircles()
        }
        private func setupCircles() {
            for _ in 0..<4 {
                let circleView = UIView()
                circleView.backgroundColor = .black
                circleView.layer.cornerRadius = 10
                circleView.layer.masksToBounds = true
                circleView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                self.addSubview(circleView)
                circleViews.append(circleView)
            }
            layoutCircles()
        }
        private func layoutCircles() {
            let spacing: CGFloat = 15.0
            let totalWidth = CGFloat(circleViews.count - 1) * spacing + CGFloat(circleViews.count) * 20.0
            let startX = (self.bounds.width - totalWidth) / 2
            for (index, circleView) in circleViews.enumerated() {
                circleView.frame.origin = CGPoint(x: startX + CGFloat(index) * (20 + spacing), y: (self.bounds.height - 20) / 2)
            }
        }
        func updateCircles(with rmsValue: Float) {
            let maxScale: CGFloat = 4
            let scaleFactor = CGFloat(rmsValue*2) * maxScale
            UIView.animate(withDuration: 0.1) {
                for circleView in self.circleViews {
                    let new_height = max(20, 20 + scaleFactor * 20)
                    circleView.frame = CGRectMake(circleView.frame.minX, self.bounds.size.height/2-new_height/2, 20, new_height)
                    circleView.layer.cornerRadius = 10
                }
            }
        }
        override func layoutSubviews() {
            super.layoutSubviews()
        }
  
}
