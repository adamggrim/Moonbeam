import SwiftUI

struct PreviewContainer<Content: View>: View {
    var backgroundColor: Color = .black
    @ViewBuilder let content: (Binding<Color>, Binding<Double>) -> Content

    @State private var selection: Color = .white
    @State private var progress: Double = 0.0

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            content($selection, $progress)
                .padding()
        }
    }
}
