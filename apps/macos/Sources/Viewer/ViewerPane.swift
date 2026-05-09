import AppKit
import SwiftUI

struct ViewerPane: View {
    let file: LocalImageFile?
    let background: ViewerBackground

    var body: some View {
        ZStack {
            background.color
                .ignoresSafeArea()

            if let file, let image = NSImage(contentsOf: file.url) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(DarkRoomDesign.Spacing.viewerPadding)
            } else {
                DRPlaceholderText(text: "Select an Image")
            }
        }
    }
}
