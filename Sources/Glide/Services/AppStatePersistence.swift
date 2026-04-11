import Combine
import Foundation

struct AppStateSnapshot: Codable, Equatable {
    var alarms: [Alarm]
    var playSoundByDefault: Bool
    var defaultSound: AlarmSound
    var showDurationsUnderFiveHoursAsHourMinute: Bool
    var messagePresetsCatalogVersion: Int
    var messagePresets: [AlarmMessagePreset]

    private enum CodingKeys: String, CodingKey {
        case alarms
        case playSoundByDefault
        case defaultSound
        case showDurationsUnderFiveHoursAsHourMinute
        case messagePresetsCatalogVersion
        case messagePresets
    }

    init(
        alarms: [Alarm],
        playSoundByDefault: Bool,
        defaultSound: AlarmSound,
        showDurationsUnderFiveHoursAsHourMinute: Bool,
        messagePresetsCatalogVersion: Int,
        messagePresets: [AlarmMessagePreset]
    ) {
        self.alarms = alarms
        self.playSoundByDefault = playSoundByDefault
        self.defaultSound = defaultSound
        self.showDurationsUnderFiveHoursAsHourMinute = showDurationsUnderFiveHoursAsHourMinute
        self.messagePresetsCatalogVersion = messagePresetsCatalogVersion
        self.messagePresets = messagePresets
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        alarms = try container.decode([Alarm].self, forKey: .alarms)
        playSoundByDefault = try container.decode(Bool.self, forKey: .playSoundByDefault)
        defaultSound = try container.decode(AlarmSound.self, forKey: .defaultSound)
        showDurationsUnderFiveHoursAsHourMinute = try container.decodeIfPresent(
            Bool.self,
            forKey: .showDurationsUnderFiveHoursAsHourMinute
        ) ?? false
        messagePresetsCatalogVersion = try container.decodeIfPresent(
            Int.self,
            forKey: .messagePresetsCatalogVersion
        ) ?? 0
        messagePresets = try container.decode([AlarmMessagePreset].self, forKey: .messagePresets)
    }

    static var defaults: Self {
        Self(
            alarms: [],
            playSoundByDefault: true,
            defaultSound: .glass,
            showDurationsUnderFiveHoursAsHourMinute: false,
            messagePresetsCatalogVersion: AlarmMessagePreset.defaultsCatalogVersion,
            messagePresets: AlarmMessagePreset.defaults
        )
    }
}

struct AppHelpLinks {
    let privacyPolicyURL: URL
    let supportURL: URL

    static func localized(for language: AppLanguage) -> Self {
        switch language {
        case .traditionalChinese:
            return Self(
                privacyPolicyURL: URL(string: "https://apps.piyan.party/zh-tw/terms")!,
                supportURL: URL(string: "https://apps.piyan.party/zh-tw/support/glide")!
            )
        case .english:
            return Self(
                privacyPolicyURL: URL(string: "https://apps.piyan.party/en/terms")!,
                supportURL: URL(string: "https://apps.piyan.party/en/support/glide")!
            )
        }
    }
}

final class AppStatePersistence {
    private let fileManager: FileManager
    private let stateFileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        fileManager: FileManager = .default,
        stateFileURL: URL? = nil,
        bundleIdentifier: String = Bundle.main.bundleIdentifier ?? "party.piyan.Glide"
    ) {
        self.fileManager = fileManager
        self.stateFileURL = stateFileURL ?? AppStatePersistence.defaultStateFileURL(
            fileManager: fileManager,
            bundleIdentifier: bundleIdentifier
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        self.decoder = JSONDecoder()
    }

    func load(now: Date = Date()) -> AppStateSnapshot {
        guard let data = try? Data(contentsOf: stateFileURL) else {
            return .defaults
        }

        guard var snapshot = try? decoder.decode(AppStateSnapshot.self, from: data) else {
            return .defaults
        }

        snapshot.alarms = snapshot.alarms
            .filter { $0.state == .scheduled && $0.triggerDate > now }
            .sorted { $0.triggerDate < $1.triggerDate }

        if snapshot.messagePresets.isEmpty {
            snapshot.messagePresets = AlarmMessagePreset.defaults
            snapshot.messagePresetsCatalogVersion = AlarmMessagePreset.defaultsCatalogVersion
        } else {
            let migratedPresets = AlarmMessagePreset.migratedPresetsIfNeeded(
                from: snapshot.messagePresets,
                catalogVersion: snapshot.messagePresetsCatalogVersion
            )
            snapshot.messagePresets = migratedPresets.presets
            snapshot.messagePresetsCatalogVersion = migratedPresets.catalogVersion
        }

        return snapshot
    }

    func save(_ snapshot: AppStateSnapshot) {
        do {
            let directoryURL = stateFileURL.deletingLastPathComponent()
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
            let data = try encoder.encode(snapshot)
            try data.write(to: stateFileURL, options: .atomic)
        } catch {
            NSLog("Failed to persist app state: %@", String(describing: error))
        }
    }

    private static func defaultStateFileURL(fileManager: FileManager, bundleIdentifier: String) -> URL {
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return applicationSupportDirectory
            .appendingPathComponent(bundleIdentifier, isDirectory: true)
            .appendingPathComponent("AppState.json", isDirectory: false)
    }
}

@MainActor
final class AppStatePersistenceCoordinator {
    private let persistence: AppStatePersistence
    private var cancellables = Set<AnyCancellable>()

    init(persistence: AppStatePersistence) {
        self.persistence = persistence
    }

    func connect(store: AlarmStore, preferences: AppPreferences) {
        store.$alarms
            .dropFirst()
            .sink { [weak self, weak preferences] alarms in
                guard let self, let preferences else { return }
                self.persistence.save(
                    AppStateSnapshot(
                        alarms: alarms,
                        playSoundByDefault: preferences.playSoundByDefault,
                        defaultSound: preferences.defaultSound,
                        showDurationsUnderFiveHoursAsHourMinute: preferences.showDurationsUnderFiveHoursAsHourMinute,
                        messagePresetsCatalogVersion: AlarmMessagePreset.defaultsCatalogVersion,
                        messagePresets: preferences.messagePresets
                    )
                )
            }
            .store(in: &cancellables)

        Publishers.CombineLatest4(
            preferences.$playSoundByDefault.dropFirst(),
            preferences.$defaultSound.dropFirst(),
            preferences.$showDurationsUnderFiveHoursAsHourMinute.dropFirst(),
            preferences.$messagePresets.dropFirst()
        )
        .sink { [weak self, weak store] playSoundByDefault, defaultSound, showDurationsUnderFiveHoursAsHourMinute, messagePresets in
            guard let self, let store else { return }
            self.persistence.save(
                AppStateSnapshot(
                    alarms: store.alarms,
                    playSoundByDefault: playSoundByDefault,
                    defaultSound: defaultSound,
                    showDurationsUnderFiveHoursAsHourMinute: showDurationsUnderFiveHoursAsHourMinute,
                    messagePresetsCatalogVersion: AlarmMessagePreset.defaultsCatalogVersion,
                    messagePresets: messagePresets
                )
            )
        }
        .store(in: &cancellables)
    }
}
