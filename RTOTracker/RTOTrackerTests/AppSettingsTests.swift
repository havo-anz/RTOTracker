import Testing
import Foundation
@testable import RTOTracker

@Suite("App Settings Tests")
struct AppSettingsTests {

    // MARK: - Default Settings Tests

    @Test("Default settings have correct values")
    func defaultValues() {
        let settings = AppSettings.default

        #expect(settings.officeIPPrefix == "10.78.")
        #expect(settings.quarterTarget == 36)
        #expect(settings.reminderEnabled == true)
        #expect(settings.launchAtLogin == false)
        #expect(settings.quarterStartMonths == [1, 4, 7, 10])
    }

    // MARK: - Custom Initialization Tests

    @Test("Custom initialization sets all properties")
    func customInitialization() {
        let reminderTime = Date()
        let settings = AppSettings(
            officeIPPrefix: "192.168.",
            quarterTarget: 40,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: false,
            reminderTime: reminderTime,
            launchAtLogin: true
        )

        #expect(settings.officeIPPrefix == "192.168.")
        #expect(settings.quarterTarget == 40)
        #expect(settings.reminderEnabled == false)
        #expect(settings.launchAtLogin == true)
    }

    // MARK: - Codable Tests

    @Test("Encoding and decoding preserves all properties")
    func encodingDecoding() throws {
        let reminderTime = Date()
        let original = AppSettings(
            officeIPPrefix: "172.16.",
            quarterTarget: 45,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: reminderTime,
            launchAtLogin: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)

        #expect(decoded.officeIPPrefix == original.officeIPPrefix)
        #expect(decoded.quarterTarget == original.quarterTarget)
        #expect(decoded.reminderEnabled == original.reminderEnabled)
        #expect(decoded.quarterStartMonths == original.quarterStartMonths)
    }

    @Test("Default settings encode and decode correctly")
    func defaultEncodingDecoding() throws {
        let original = AppSettings.default

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(AppSettings.self, from: data)

        #expect(decoded.officeIPPrefix == "10.78.")
        #expect(decoded.quarterTarget == 36)
        #expect(decoded.reminderEnabled == true)
        #expect(decoded.launchAtLogin == false)
    }

    // MARK: - Validation Tests

    @Test(
        "Valid IP prefixes are accepted",
        arguments: ["10.78.", "192.168.", "172.16.", "10.", "192.", "10.0.0."]
    )
    func validIPPrefixes(prefix: String) {
        let settings = AppSettings(
            officeIPPrefix: prefix,
            quarterTarget: 36,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )
        #expect(settings.officeIPPrefix == prefix)
    }

    @Test(
        "Quarter targets in valid range are accepted",
        arguments: [1, 36, 50, 60, 100]
    )
    func quarterTargetRange(target: Int) {
        let settings = AppSettings(
            officeIPPrefix: "10.78.",
            quarterTarget: target,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )
        #expect(settings.quarterTarget == target)
        #expect(settings.quarterTarget > 0)
    }

    // MARK: - Mutation Tests

    @Test("AppSettings is mutable and properties can be changed")
    func isMutable() {
        var settings = AppSettings.default

        #expect(settings.quarterTarget == 36)

        settings.quarterTarget = 40
        #expect(settings.quarterTarget == 40)

        settings.officeIPPrefix = "192.168."
        #expect(settings.officeIPPrefix == "192.168.")

        settings.reminderEnabled = false
        #expect(settings.reminderEnabled == false)

        settings.launchAtLogin = true
        #expect(settings.launchAtLogin == true)
    }

    // MARK: - Edge Cases

    @Test("Empty IP prefix is accepted")
    func emptyIPPrefix() {
        let settings = AppSettings(
            officeIPPrefix: "",
            quarterTarget: 36,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )

        #expect(settings.officeIPPrefix == "")
    }

    @Test("Zero target is accepted")
    func zeroTarget() {
        let settings = AppSettings(
            officeIPPrefix: "10.78.",
            quarterTarget: 0,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )

        #expect(settings.quarterTarget == 0)
    }

    @Test("Large target values are accepted")
    func largeTarget() {
        let settings = AppSettings(
            officeIPPrefix: "10.78.",
            quarterTarget: 999,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )

        #expect(settings.quarterTarget == 999)
    }

    @Test("Quarter start months contain all four quarters")
    func quarterStartMonths() {
        let settings = AppSettings.default

        #expect(settings.quarterStartMonths.count == 4)
        #expect(settings.quarterStartMonths.contains(1))
        #expect(settings.quarterStartMonths.contains(4))
        #expect(settings.quarterStartMonths.contains(7))
        #expect(settings.quarterStartMonths.contains(10))
    }

    // MARK: - JSON Compatibility

    @Test("JSON structure contains expected fields")
    func jsonStructure() throws {
        let settings = AppSettings(
            officeIPPrefix: "10.78.",
            quarterTarget: 36,
            quarterStartMonths: [1, 4, 7, 10],
            reminderEnabled: true,
            reminderTime: Date(),
            launchAtLogin: false
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(settings)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("officeIPPrefix"))
        #expect(jsonString.contains("quarterTarget"))
        #expect(jsonString.contains("reminderEnabled"))
        #expect(jsonString.contains("10.78."))
        #expect(jsonString.contains("36"))
    }
}
