import SwiftUI

/// A state structure that isolates the drag gesture properties.
internal struct ColorSliderState {
    var isDragging: Bool = false
    var dragStartValue: Double? = nil
    var liveContainerDrag: CGFloat = .zero

    mutating func updateDrag(translation: CGFloat, currentValue: Double) {
        isDragging = true

        if dragStartValue == nil {
            dragStartValue = currentValue
        }
        liveContainerDrag = translation
    }

    mutating func finalizeDrag() {
        isDragging = false
        dragStartValue = nil
        liveContainerDrag = .zero
    }
}
