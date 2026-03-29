import SwiftUI

struct AppTopSection<Header: View, Content: View>: View {
    let contentSpacing: CGFloat
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    init(
        contentSpacing: CGFloat = 10,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.contentSpacing = contentSpacing
        self.header = header
        self.content = content
    }

    var body: some View {
        VStack(spacing: contentSpacing) {
            header()
            content()
        }
        .padding(.horizontal)
        .padding(.top, 0)
    }
}

struct AppScreenTitle: View {
    let title: String
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text(title)
                .font(.tanTangkiwood(size: 32))
                .foregroundColor(themeManager.selectedTheme.accent)

            Spacer()
        }
        .frame(minHeight: 36, alignment: .center)
    }
}
