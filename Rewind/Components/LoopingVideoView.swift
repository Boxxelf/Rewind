import AVFoundation
import Photos
import SwiftUI

struct LoopingVideoView: UIViewRepresentable {
    let asset: PHAsset
    var isScrubbing: Bool
    var isMuted: Bool
    var scrubProgress: CGFloat

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.load(asset: asset)
        return view
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var wasScrubbing = false
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.player?.isMuted = isMuted
        if isScrubbing {
            uiView.scrub(progress: scrubProgress)
        } else if context.coordinator.wasScrubbing {
            uiView.resumeLoop()
        }
        context.coordinator.wasScrubbing = isScrubbing
    }

    final class PlayerView: UIView {
        var player: AVPlayer?
        private var loopDuration: Double = 3
        private var fullDuration: Double = 3
        private var isLooping = true
        private var item: AVPlayerItem?
        private var observer: Any?

        override class var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        func load(asset: PHAsset) {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] item, _ in
                guard let self, let item else { return }
                DispatchQueue.main.async {
                    let seconds = asset.duration.isFinite ? asset.duration : 3
                    self.fullDuration = max(seconds, 0.01)
                    self.loopDuration = min(3, self.fullDuration)
                    let player = AVPlayer(playerItem: item)
                    player.isMuted = true
                    self.player = player
                    self.item = item
                    self.playerLayer.player = player
                    self.playerLayer.videoGravity = .resizeAspectFill
                    player.play()
                    self.limitToThreeSeconds()
                }
            }
        }

        private func limitToThreeSeconds() {
            player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.25, preferredTimescale: 600), queue: .main) { [weak self] time in
                guard let self, self.isLooping else { return }
                if time.seconds >= self.loopDuration {
                    self.player?.seek(to: .zero)
                    self.player?.play()
                }
            }
        }

        func scrub(progress: CGFloat) {
            isLooping = false
            player?.pause()
            let full = fullDuration
            let seconds = max(0, min(full, full * Double(progress)))
            player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600), toleranceBefore: .zero, toleranceAfter: .zero)
        }

        func resumeLoop() {
            guard !isLooping else { return }
            isLooping = true
            player?.seek(to: .zero)
            player?.play()
        }
    }
}
