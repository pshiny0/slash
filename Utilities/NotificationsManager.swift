import Foundation
import UserNotifications

enum NotificationsManager {
    static func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
    }

    static func scheduleRenewalReminder(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Upcoming renewal"
        content.body = "\(subscription.name) renews in 3 days"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: subscription.renewalDate) else { return }
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "renewal_\(subscription.id)", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelReminder(for subscription: Subscription) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["renewal_\(subscription.id)"])
    }
}


