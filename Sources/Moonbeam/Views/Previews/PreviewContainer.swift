import SwiftUI

struct PreviewContainer<Content: View>: View {
    var backgroundColor: Color = .black
    @ViewBuilder let content: (Binding<CGColor>, Binding<Double>) -> Content

    @State private var selection: CGColor = CGColor(gray: 1, alpha: 1)
    @State private var progress: Double = 0.0

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            content($selection, $progress)
        }
    }
}
