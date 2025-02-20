import SwiftUI

public enum NavigationPageType {
    case forkDowns
    case muscleUps
}

// MARK: - Utility Extensions and Components

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
    
    public func standardPageLayout() -> some View {
        modifier(StandardPageLayout())
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

public struct StandardPageLayout: ViewModifier {
    public func body(content: Content) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                content
            }
            .padding(.vertical)
        }
    }
}
