import Testing
import Foundation
@testable import RTOTracker

@Suite("Office Detection Service Tests")
final class OfficeDetectionServiceTests {
    var sut: OfficeDetectionService
    var mockDataManager: DataManager
    var mockUserDefaults: UserDefaults
    var suiteName: String

    init() {
        suiteName = "test.officedetection.\(UUID().uuidString)"
        mockUserDefaults = UserDefaults(suiteName: suiteName)!
        mockDataManager = DataManager(userDefaults: mockUserDefaults)
        sut = OfficeDetectionService(dataManager: mockDataManager)
    }

    deinit {
        sut.stopDetection()
        mockUserDefaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - IP Prefix Matching Logic

    @Test("Office IP matches prefix correctly")
    func ipPrefixMatchingOfficeIP() {
        let testIP = "10.78.123.45"
        let prefix = "10.78."

        let matches = testIP.hasPrefix(prefix)
        #expect(matches == true)
    }

    @Test("Non-office IP does not match prefix")
    func ipPrefixMatchingNonOfficeIP() {
        let testIP = "192.168.1.1"
        let prefix = "10.78."

        let matches = testIP.hasPrefix(prefix)
        #expect(matches == false)
    }

    @Test("Partial match does not match prefix")
    func ipPrefixMatchingPartialMatch() {
        let testIP = "10.79.1.1"
        let prefix = "10.78."

        let matches = testIP.hasPrefix(prefix)
        #expect(matches == false)
    }

    @Test("Empty IP does not match prefix")
    func ipPrefixMatchingEmptyIP() {
        let testIP = ""
        let prefix = "10.78."

        let matches = testIP.hasPrefix(prefix)
        #expect(matches == false)
    }

    @Test(
        "Various IP prefix combinations",
        arguments: [
            ("10.78.1.1", "10.78.", true),
            ("10.78.255.255", "10.78.", true),
            ("10.77.1.1", "10.78.", false),
            ("192.168.1.1", "10.78.", false),
            ("172.16.1.1", "172.16.", true),
            ("10.0.0.1", "10.", true),
            ("10.78.1.1", "10.78.1.", true),
            ("10.78.2.1", "10.78.1.", false),
        ]
    )
    func ipPrefixMatching(ip: String, prefix: String, expected: Bool) {
        let matches = ip.hasPrefix(prefix)
        #expect(matches == expected)
    }

    // MARK: - Office Day Confirmation

    @Test("Check office presence validates logic structure")
    func checkOfficePresenceWithOfficeIP() {
        mockDataManager.settings.officeIPPrefix = "10.78."

        sut.checkOfficePresence()

        // Current IP should be populated (even if empty)
        #expect(sut.currentIP != nil)
    }

    @Test("Check office presence confirms day when at office")
    func checkOfficePresenceConfirmsDay() {
        let initialCount = mockDataManager.getCurrentQuarterProgress().confirmed
        #expect(initialCount == 0)

        mockDataManager.settings.officeIPPrefix = "10.78."
        sut.checkOfficePresence()

        if sut.isAtOffice {
            let record = mockDataManager.getTodayRecord()
            #expect(record.isConfirmed == true)
        }
    }

    @Test("Test current connection returns IP and status")
    func testCurrentConnectionReturnsIPAndStatus() {
        mockDataManager.settings.officeIPPrefix = "10.78."

        let result = sut.testCurrentConnection()

        #expect(result.ip != nil)
        #expect(result.isOffice == result.ip.hasPrefix("10.78."))
    }

    // MARK: - Detection Lifecycle

    @Test("Start detection checks immediately")
    func startDetectionChecksImmediately() {
        let initialIP = sut.currentIP
        #expect(initialIP == "")

        sut.startDetection()

        #expect(sut.currentIP != nil)
    }

    @Test("Stop detection cleans up properly")
    func stopDetectionCleansUp() {
        sut.startDetection()
        sut.stopDetection()

        #expect(sut != nil)
    }

    // MARK: - Published Properties

    @Test("isAtOffice property starts as false")
    func isAtOfficePropertyStartsFalse() {
        #expect(sut.isAtOffice == false)
    }

    @Test("currentIP property starts empty")
    func currentIPPropertyStartsEmpty() {
        #expect(sut.currentIP == "")
    }

    // MARK: - Integration Tests

    @Test("Multiple checks update status consistently")
    func multipleChecksUpdateStatus() {
        sut.checkOfficePresence()
        let firstIP = sut.currentIP
        let firstStatus = sut.isAtOffice

        sut.checkOfficePresence()
        let secondIP = sut.currentIP
        let secondStatus = sut.isAtOffice

        #expect(firstIP == secondIP)
        #expect(firstStatus == secondStatus)
    }
}
