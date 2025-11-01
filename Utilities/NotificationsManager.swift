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
        let days = subscription.reminderDaysBefore ?? 3
        content.body = "\(subscription.name) renews in \(days) days"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -days, to: subscription.renewalDate) else { return }
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "renewal_\(subscription.id)", content: content, trigger: trigger)
        center.add(request)
    }

    static func scheduleSoftRenewalDay(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Renewed"
        content.body = "\(subscription.name) renewed today"
        content.sound = .default

        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: subscription.renewalDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "soft_renewal_\(subscription.id)", content: content, trigger: trigger)
        center.add(request)
    }

    static func scheduleAskMeFirstReminder(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Decision needed"
        content.body = "Decide if you want to renew \(subscription.name)"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -3, to: subscription.renewalDate) else { return }
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "ask_first_\(subscription.id)", content: content, trigger: trigger)
        center.add(request)
    }

    static func scheduleOneTimeEndingReminder(for subscription: Subscription) {
        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = "Ending soon"
        content.body = "\(subscription.name) ends soon"
        content.sound = .default

        guard let triggerDate = Calendar.current.date(byAdding: .day, value: -1, to: subscription.renewalDate) else { return }
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "one_time_\(subscription.id)", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelReminder(for subscription: Subscription) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["renewal_\(subscription.id)"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["soft_renewal_\(subscription.id)"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["ask_first_\(subscription.id)"])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["one_time_\(subscription.id)"])
    }
}


