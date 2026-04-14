import Foundation
import UserNotifications

// MARK: - Stored alert model

struct CommuteAlert: Codable, Identifiable, Equatable {
    let id: UUID
    let stopId: String
    let stopName: String
    let hour: Int
    let minute: Int

    init(stopId: String, stopName: String, hour: Int, minute: Int) {
        self.id = UUID()
        self.stopId = stopId
        self.stopName = stopName
        self.hour = hour
        self.minute = minute
    }

    var displayTime: String {
        String(format: "%02d:%02d", hour, minute)
    }
}

// MARK: - Manager

@MainActor
@Observable
final class CommuteAlertManager {
    static let shared = CommuteAlertManager()

    private let storageKey = "commuteAlerts_v1"
    private let center = UNUserNotificationCenter.current()

    var alerts: [CommuteAlert] = []
    var permissionStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        load()
    }

    // MARK: - Permission

    func refreshPermissionStatus() async {
        let settings = await center.notificationSettings()
        permissionStatus = settings.authorizationStatus
    }

    /// Returns true if permission was granted.
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            await refreshPermissionStatus()
            return granted
        } catch {
            return false
        }
    }

    // MARK: - CRUD

    func addAlert(stopId: String, stopName: String, hour: Int, minute: Int) async {
        let alert = CommuteAlert(stopId: stopId, stopName: stopName, hour: hour, minute: minute)
        alerts.append(alert)
        save()
        await schedule(alert)
    }

    func removeAlert(_ alert: CommuteAlert) {
        center.removePendingNotificationRequests(withIdentifiers: [alert.id.uuidString])
        alerts.removeAll { $0.id == alert.id }
        save()
    }

    func removeAllAlerts() {
        center.removeAllPendingNotificationRequests()
        alerts.removeAll()
        save()
    }

    // MARK: - Scheduling

    /// Schedule a repeating local notification for this alert.
    private func schedule(_ alert: CommuteAlert) async {
        var dateComponents = DateComponents()
        dateComponents.hour = alert.hour
        dateComponents.minute = alert.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = alert.stopName
        content.body = "Time to check your departures"
        content.sound = .default
        // Deep link: berlintransportmap://departures/STOP_ID?name=STOP_NAME
        content.userInfo = ["stopId": alert.stopId, "stopName": alert.stopName]

        let request = UNNotificationRequest(identifier: alert.id.uuidString, content: content, trigger: trigger)

        do {
            try await center.add(request)
        } catch {
            // Notification scheduling failed — user likely denied permission
        }
    }

    /// Re-schedule all stored alerts (called after permission grant).
    func rescheduleAll() async {
        center.removeAllPendingNotificationRequests()
        for alert in alerts {
            await schedule(alert)
        }
    }

    // MARK: - Persistence

    private func save() {
        guard let data = try? JSONEncoder().encode(alerts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([CommuteAlert].self, from: data)
        else { return }
        alerts = decoded
    }
}
