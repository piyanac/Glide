import XCTest
@testable import Glide

final class GlideTests: XCTestCase {
    func testCountdownDraftCreatesExpectedTriggerDate() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let draft = AlarmDraft(
            selection: .countdown(1800),
            selectedPreset: "Tea",
            customMessage: "",
            soundEnabled: true,
            selectedSound: .glass
        )

        let alarm = draft.makeAlarm(now: now)

        XCTAssertEqual(alarm.triggerDate, now.addingTimeInterval(1800))
        XCTAssertEqual(alarm.message, "Tea")
    }

    func testClockTimeRollsToNextDayWhenTimeHasPassed() {
        var components = DateComponents()
        components.year = 2026
        components.month = 3
        components.day = 21
        components.hour = 20
        components.minute = 15
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: components)!

        let trigger = AlarmDateResolver.nextClockTime(hour: 19, minute: 45, now: now)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 3, day: 22, hour: 19, minute: 45))!

        XCTAssertEqual(trigger, expected)
    }

    @MainActor
    func testActivateDueAlarmsMarksAndSortsByTriggerDate() {
        let store = AlarmStore()
        let base = Date(timeIntervalSince1970: 2_000_000)

        store.addAlarm(Alarm(kind: .countdown(duration: 60), triggerDate: base.addingTimeInterval(30), message: "Later", sound: nil))
        store.addAlarm(Alarm(kind: .countdown(duration: 60), triggerDate: base.addingTimeInterval(10), message: "Soon", sound: nil))
        store.addAlarm(Alarm(kind: .countdown(duration: 60), triggerDate: base.addingTimeInterval(90), message: "Future", sound: nil))

        let due = store.activateDueAlarms(now: base.addingTimeInterval(40))

        XCTAssertEqual(due.map(\.message), ["Soon", "Later"])
        XCTAssertEqual(store.sortedAlarms.filter { $0.state == .firing }.count, 2)
    }

    @MainActor
    func testRemovingAlarmPreventsActivation() {
        let store = AlarmStore()
        let now = Date(timeIntervalSince1970: 3_000_000)
        let alarm = Alarm(kind: .countdown(duration: 5), triggerDate: now.addingTimeInterval(5), message: "Remove me", sound: nil)

        store.addAlarm(alarm)
        store.removeAlarm(id: alarm.id)

        XCTAssertTrue(store.activateDueAlarms(now: now.addingTimeInterval(10)).isEmpty)
    }

    func testHoverSelectionMapsShortRangeFromOneSecondToFiftyNineMinutes() {
        let left = AlarmHoverSelection(zone: .shortTimer, normalizedX: 0)
        let right = AlarmHoverSelection(zone: .shortTimer, normalizedX: 1)

        XCTAssertEqual(left.duration ?? 0, 1, accuracy: 0.001)
        XCTAssertEqual(right.duration ?? 0, 3540, accuracy: 0.001)
    }

    func testHoverSelectionMapsLongRangeToTwentyFourHours() {
        let left = AlarmHoverSelection(zone: .longTimer, normalizedX: 0)
        let right = AlarmHoverSelection(zone: .longTimer, normalizedX: 1)

        XCTAssertEqual(left.duration ?? 0, 3600, accuracy: 0.001)
        XCTAssertEqual(right.duration ?? 0, 86_400, accuracy: 0.001)
    }

    func testAbsoluteTimePreviewUsesHourOnlyForSameDay() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 21, hour: 9, minute: 0))!
        let target = calendar.date(from: DateComponents(year: 2026, month: 3, day: 21, hour: 13, minute: 45))!

        XCTAssertEqual(AlarmHoverPreview.absoluteTimeString(for: target, relativeTo: now), "13:45")
    }

    func testAbsoluteTimePreviewUsesMonthDayAndHourForNextDay() {
        let calendar = Calendar(identifier: .gregorian)
        let now = calendar.date(from: DateComponents(year: 2026, month: 3, day: 21, hour: 23, minute: 30))!
        let target = calendar.date(from: DateComponents(year: 2026, month: 3, day: 22, hour: 6, minute: 5))!

        XCTAssertEqual(AlarmHoverPreview.absoluteTimeString(for: target, relativeTo: now), "03/22 06:05")
    }
}
