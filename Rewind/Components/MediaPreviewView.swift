import AVFoundation
import Photos
import SwiftUI

struct MediaPreviewView: View {
    let item: DeckItem
    var onClose: () -> Void

    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            Color.black.opacity(min(1, 0.55 + Double(scale) * 0.35))
                .ignoresSafeArea()

            Group {
                if item.isVideo {
                    PreviewVideoView(asset: item.asset)
                } else {
                    AssetImageView(asset: item.asset, contentMode: .fit, quality: .preview)
                }
            }
            .scaleEffect(scale)
            .offset(offset)
            .gesture(previewGesture)

            VStack {
                Spacer()
                Text("Pinch out to zoom · Pinch in to close")
                    .font(RewindFont.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 36)
            }
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
        .accessibilityLabel("Full preview")
        .accessibilityHint("Pinch in to close")
        .accessibilityAction(.escape, onClose)
    }

    private var previewGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                scale = max(0.55, min(4, value.magnification))
            }
            .onEnded { value in
                if value.magnification < 0.88 {
                    onClose()
                    return
                }
                withAnimation(RewindSpring.snappy) {
                    scale = min(max(value.magnification, 1), 4)
                    if scale <= 1.02 {
                        offset = .zero
                    }
                }
            }
            .simultaneously(with:
                DragGesture()
                    .onChanged { value in
                        if scale > 1.05 { offset = value.translation }
                    }
                    .onEnded { _ in
                        if scale <= 1.05 {
                            withAnimation(RewindSpring.snappy) { offset = .zero }
                        }
                    }
            )
    }
}

struct PreviewVideoView: UIViewRepresentable {
    let asset: PHAsset

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.load(asset: asset)
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {}

    final class PlayerView: UIView {
        var player: AVPlayer?

        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

        func load(asset: PHAsset) {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .fastFormat
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { [weak self] item, _ in
                guard let self, let item else { return }
                DispatchQueue.main.async {
                    let player = AVPlayer(playerItem: item)
                    player.isMuted = false
                    self.player = player
                    self.playerLayer.player = player
                    self.playerLayer.videoGravity = .resizeAspect
                    player.play()
                }
            }
        }
    }
}
