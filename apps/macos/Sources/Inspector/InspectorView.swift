import SwiftUI

struct InspectorView: View {
    let selectedFile: LocalImageFile?
    @Binding var viewerBackground: ViewerBackground

    var body: some View {
        Form {
            Section("Image") {
                LabeledContent("File") {
                    Text(selectedFile?.displayName ?? "None")
                        .lineLimit(1)
                }

                if let selectedFile {
                    LabeledContent("Path") {
                        Text(selectedFile.url.deletingLastPathComponent().path)
                            .lineLimit(2)
                            .truncationMode(.middle)
                    }
                }
            }

            Section("Viewer") {
                Picker("Background", selection: $viewerBackground) {
                    ForEach(ViewerBackground.allCases) { background in
                        Text(background.label).tag(background)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Light") {
                Slider(value: .constant(0), in: -5...5) {
                    Text("Exposure")
                }
                .disabled(true)

                Slider(value: .constant(1), in: 0...2) {
                    Text("Contrast")
                }
                .disabled(true)
            }
        }
        .formStyle(.grouped)
        .padding(.top, DarkRoomDesign.Spacing.small)
    }
}
