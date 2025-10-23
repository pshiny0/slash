import SwiftUI

struct AppIconPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var appIconManager: AppIconManager
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text("App Icon")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.selectedTheme.textPrimary)
                            
                            Text("Choose your favorite app icon")
                                .font(.subheadline)
                                .foregroundColor(themeManager.selectedTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top)
                        
                        // Icon Grid
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(AppIcon.allCases) { icon in
                                AppIconCard(
                                    icon: icon,
                                    isSelected: appIconManager.currentIcon == icon,
                                    onTap: {
                                        appIconManager.setIcon(icon)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
        }
    }
}

struct AppIconCard: View {
    let icon: AppIcon
    let isSelected: Bool
    let onTap: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Icon Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(icon.previewColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    isSelected ? themeManager.selectedTheme.accent : Color.clear,
                                    lineWidth: 3
                                )
                        )
                    
                    // Icon representation - show actual icon preview
                    if let uiImage = UIImage(named: "AppIcon-\(icon.rawValue)") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        // Fallback to a colored placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(icon.previewColor)
                            .frame(width: 50, height: 50)
                            .overlay(
                                Text(icon.displayName.prefix(2))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                // Icon Name
                Text(icon.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.selectedTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(themeManager.selectedTheme.accent)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    AppIconPickerView()
        .environmentObject(ThemeManager())
        .environmentObject(AppIconManager())
}
