import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Choose Theme")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.accent)
                    Text("Select your preferred color scheme")
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.accent.opacity(0.7))
                }
                .padding(.top)

                VStack(spacing: 12) {
                    ThemeChoiceRow(title: "System", choice: .system)
                    ThemeChoiceRow(title: "Light", choice: .light)
                    ThemeChoiceRow(title: "Dark", choice: .dark)
                }
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 8) {
                    Text("Current Theme")
                        .font(.headline)
                        .foregroundColor(themeManager.selectedTheme.accent)
                    Text(currentThemeName)
                        .font(.subheadline)
                        .foregroundColor(themeManager.selectedTheme.accent.opacity(0.7))
                }
                .padding()
                .background(themeManager.selectedTheme.primary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom)
            }
            .navigationTitle("Themes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
            .background(themeManager.selectedTheme.primary)
        }
    }

    private var currentThemeName: String {
        switch themeManager.choice {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

private struct ThemeChoiceRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let title: String
    let choice: ThemeChoice

    var body: some View {
        Button(action: { themeManager.setChoice(choice) }) {
            HStack {
                Text(title)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                Spacer()
                if themeManager.choice == choice {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
            .padding()
            .background(themeManager.selectedTheme.cardBackground)
            .cornerRadius(12)
        }
    }
}

struct ThemePreviewCard: View {
    let theme: AppTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            // Color Preview - Side by Side
            HStack(spacing: 0) {
                // Primary color (left half)
                Rectangle()
                    .fill(theme.primary)
                    .frame(height: 60)
                
                // Accent color (right half)
                Rectangle()
                    .fill(theme.accent)
                    .frame(height: 60)
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            
            // Theme Name
            Text(theme.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(theme.primary) // Use the theme's primary color for text
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? theme.accent.opacity(0.1) : theme.primary.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 2)
                )
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    ThemePickerView()
        .environmentObject(ThemeManager())
}
