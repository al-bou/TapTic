import SwiftUI
import UIKit

// Classe observable pour un point de contact
class TouchData: ObservableObject, Identifiable, Equatable {
    let id: Int
    @Published var point: CGPoint
    let color: Color

    init(id: Int, point: CGPoint, color: Color) {
        self.id = id
        self.point = point
        self.color = color
    }

    // Conformité à Equatable
    static func == (lhs: TouchData, rhs: TouchData) -> Bool {
        return lhs.id == rhs.id
    }
}

// Vue UIKit pour capturer les touches
class MultiTouchView: UIView {
    var touchPoints: [Int: TouchData] = [:]
    var onTouchUpdate: ([TouchData]) -> Void
    let colors: [Color]
    var colorIndex = 0

    init(colors: [Color], onTouchUpdate: @escaping ([TouchData]) -> Void) {
        self.colors = colors
        self.onTouchUpdate = onTouchUpdate
        super.init(frame: .zero)
        self.isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func nextColor() -> Color {
        let color = colors[colorIndex % colors.count]
        colorIndex += 1
        return color
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchID = touch.hash
            let touchData = TouchData(id: touchID, point: location, color: nextColor())
            touchPoints[touchID] = touchData
        }
        onTouchUpdate(Array(touchPoints.values))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            let touchID = touch.hash
            if let touchData = touchPoints[touchID] {
                touchData.point = location // Mise à jour en temps réel
            }
        }
        onTouchUpdate(Array(touchPoints.values))
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            touchPoints.removeValue(forKey: touch.hash)
        }
        onTouchUpdate(Array(touchPoints.values))
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
}

// Wrapper SwiftUI pour intégrer la vue UIKit
struct MultiTouchViewRepresentable: UIViewRepresentable {
    let colors: [Color]
    @Binding var touchPoints: [TouchData]
    
    func makeUIView(context: Context) -> MultiTouchView {
        let view = MultiTouchView(colors: colors) { updatedPoints in
            DispatchQueue.main.async {
                self.touchPoints = updatedPoints
            }
        }
        return view
    }
    
    func updateUIView(_ uiView: MultiTouchView, context: Context) {
        // Pas de mise à jour nécessaire ici
    }
}
