import Foundation
import Photos
import UserNotifications

enum MemoryNotification {
    static func requestAndSchedule() async {
        let center = UNUserNotificationCenter.current()
        let granted = try? await center.requestAuthorization(options: [.alert, .sound])
        guard granted == true else { return }
        center.removeAllPendingNotificationRequests()

        let content = UNMutableNotificationContent()
        content.title = "Remember this?"
        if let asset = PhotoLibraryService.onThisDayAssets().randomElement(),
           let date = asset.creationDate {
            let years = Calendar.current.dateComponents([.year], from: date, to: .now).year ?? 1
            content.body = "A photo from \(max(1, years)) years ago today."
        } else {
            content.body = "A photo from years ago is waiting in Rewind."
        }
        content.sound = .default

        var comps = DateComponents()
        comps.weekday = 1
        comps.hour = 10
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: "rewind.weekly.memory", content: content, trigger: trigger)
        try? await center.add(request)
    }
}
