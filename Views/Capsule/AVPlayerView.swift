// AVPlayerView - SwiftUI wrapper for AVPlayer
import AVKit
import SwiftUI

struct AVPlayerView: UIViewRepresentable {
    let player: AVPlayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        view.layer.addSublayer(playerLayer)
        playerLayer.frame = view.bounds
        view.layoutSubviews()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update player layer frame if needed
        if let playerLayer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            playerLayer.frame = uiView.bounds
        }
    }
}
