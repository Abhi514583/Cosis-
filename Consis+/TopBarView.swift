import SwiftUI

public struct TopBarView: View {
    public var title: String
    
    public init(title: String) {
        self.title = title
    }
    
    public var body: some View {
        HStack(alignment: .center) {
            Text(title)
                // Font size slightly smaller per user request
                .font(Typography.headlineLarge)
                .foregroundColor(Theme.Colors.onSurface)
            
            Spacer()
            
            // Replaced notification with Settings icon
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.Colors.onSurface)
                    .frame(width: 44, height: 44)
                    .background(Theme.Colors.surfaceContainerHigh)
                    .clipShape(Circle())
            }
            
            Button(action: {}) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(Theme.Colors.primary)
                    .background(Theme.Colors.surfaceContainerHigh)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .background(Theme.Colors.surface)
    }
}

#Preview {
    VStack {
        TopBarView(title: "LiftLite")
        Spacer()
    }
    .background(Theme.Colors.surface)
}
