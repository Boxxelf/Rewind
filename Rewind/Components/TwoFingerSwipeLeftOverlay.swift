import SwiftUI
import UIKit

struct TwoFingerSwipeLeftOverlay: UIViewRepresentable {
    var onSwipe: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipe: onSwipe)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        context.coordinator.install(on: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.onSwipe = onSwipe
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onSwipe: () -> Void
        private var recognizer: UISwipeGestureRecognizer?

        init(onSwipe: @escaping () -> Void) {
            self.onSwipe = onSwipe
        }

        func install(on view: UIView) {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handle))
            swipe.direction = .left
            swipe.numberOfTouchesRequired = 2
            swipe.cancelsTouchesInView = false
            swipe.delegate = self
            recognizer = swipe
            DispatchQueue.main.async { [weak self, weak view] in
                guard let swipe = self?.recognizer, let window = view?.window else { return }
                window.addGestureRecognizer(swipe)
            }
        }

        func uninstall() {
            if let recognizer {
                recognizer.view?.removeGestureRecognizer(recognizer)
            }
        }

        @objc func handle(_ recognizer: UISwipeGestureRecognizer) {
            if recognizer.state == .ended {
                onSwipe()
            }
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}
