import AppKit
import SwiftUI

struct ViewerDisplayProfileReader: NSViewRepresentable {
    let onChange: (NSWindow?) -> Void

    func makeNSView(context: Context) -> DisplayProfileObservingView {
        let view = DisplayProfileObservingView()
        view.onChange = onChange
        return view
    }

    func updateNSView(_ nsView: DisplayProfileObservingView, context: Context) {
        nsView.onChange = onChange
        nsView.reportDisplayProfile()
    }
}

@MainActor
final class DisplayProfileObservingView: NSView {
    var onChange: (NSWindow?) -> Void = { _ in }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        installWindowObservers()
        reportDisplayProfile()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func reportDisplayProfile() {
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }

            self.onChange(self.window)
        }
    }

    private func installWindowObservers() {
        NotificationCenter.default.removeObserver(self)

        guard let window else {
            return
        }

        let center = NotificationCenter.default
        let names: [NSNotification.Name] = [
            NSWindow.didChangeScreenNotification,
            NSWindow.didChangeBackingPropertiesNotification,
            NSWindow.didChangeScreenProfileNotification
        ]

        for name in names {
            center.addObserver(
                self,
                selector: #selector(displayProfileDidChange(_:)),
                name: name,
                object: window
            )
        }
    }

    @objc private func displayProfileDidChange(_ notification: Notification) {
        reportDisplayProfile()
    }
}
