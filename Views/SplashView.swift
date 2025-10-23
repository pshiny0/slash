import SwiftUI

struct SplashView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var isAnimating = false
    @State private var opacity: Double = 0.0
    
    var body: some View {
        // Logo text with accent color
        Text("slash")
            .font(.tanTangkiwood(size: 72))
            .foregroundColor(themeManager.selectedTheme.accent)
            .scaleEffect(isAnimating ? 1.1 : 1.0)
            .opacity(opacity)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
            .onAppear {
                withAnimation(.easeIn(duration: 1.0)) {
                    opacity = 1.0
                }
                withAnimation(.easeInOut(duration: 2.0).delay(0.5)) {
                    isAnimating = true
                }
            }
    }
}

#Preview {
    SplashView()
        .environmentObject(ThemeManager())
}
