import SwiftUI

struct AppIconPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var appIconManager: AppIconManager
    @Environment(\.dismiss) private var dismiss
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                GradientBackground()
                    .environmentObject(themeManager)
                
                VStack(spacing: 0) {
                    // Header
                    Text("Change App Icon")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.selectedTheme.textPrimary)
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                    
                    // Icon Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
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
                        .padding(.horizontal, 8)
                        .padding(.bottom, 20)
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
        VStack(spacing: 8) {
            // Icon Preview
            ZStack {
                if let uiImage = UIImage(named: "AppIcon-\(icon.rawValue)-preview") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? themeManager.selectedTheme.accent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                } else {
                    // Fallback to a colored placeholder
                    RoundedRectangle(cornerRadius: 12)
                        .fill(icon.previewColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(icon.displayName.prefix(2))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isSelected ? themeManager.selectedTheme.accent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                
                // Selection indicator
                if isSelected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(themeManager.selectedTheme.accent)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            
            // Icon Name
            Text(icon.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(themeManager.selectedTheme.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? themeManager.selectedTheme.accent.opacity(0.1) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    AppIconPickerView()
        .environmentObject(ThemeManager())
        .environmentObject(AppIconManager())
}