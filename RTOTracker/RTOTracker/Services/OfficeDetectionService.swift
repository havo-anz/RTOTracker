import Foundation
import Network
import Combine

final class OfficeDetectionService: ObservableObject {
    @Published var isAtOffice: Bool = false
    @Published var currentIP: String = ""

    private var dataManager: DataManager
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private var pollingInterval: TimeInterval { 5 * 60 } // 5 minutes

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    func startDetection() {
        // Check immediately
        checkOfficePresence()

        // Then check every 5 minutes
        timer = Timer.scheduledTimer(
            withTimeInterval: pollingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.checkOfficePresence()
        }
    }

    func stopDetection() {
        timer?.invalidate()
        timer = nil
    }

    func checkOfficePresence() {
        let ip = getCurrentIPAddress()
        currentIP = ip

        let wasAtOffice = isAtOffice
        isAtOffice = ip.hasPrefix(dataManager.settings.officeIPPrefix)

        if isAtOffice {
            // Confirm today as an office day
            dataManager.confirmTodayAsOfficeDay()
        }

        // Notify AppDelegate if status changed (for menu bar icon update)
        if wasAtOffice == false && isAtOffice {
            NotificationCenter.default.post(name: .officeStatusChanged, object: nil)
        }
    }

    func getCurrentIPAddress() -> String {
        var address: String = ""
        var ifaddr: UnsafeMutablePointer<ifaddrs>?

        guard getifaddrs(&ifaddr) == 0 else { return "" }
        guard let firstAddr = ifaddr else { return "" }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            // Check for IPv4 interface
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)

                // Check for en0 (primary ethernet/wifi)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(
                        interface.ifa_addr,
                        socklen_t(interface.ifa_addr.pointee.sa_len),
                        &hostname,
                        socklen_t(hostname.count),
                        nil,
                        socklen_t(0),
                        NI_NUMERICHOST
                    )
                    address = String(cString: hostname)
                    break
                }
            }
        }

        freeifaddrs(ifaddr)
        return address
    }

    func testCurrentConnection() -> (ip: String, isOffice: Bool) {
        let ip = getCurrentIPAddress()
        let isOffice = ip.hasPrefix(dataManager.settings.officeIPPrefix)
        return (ip, isOffice)
    }
}

extension Notification.Name {
    static let officeStatusChanged = Notification.Name("officeStatusChanged")
}
