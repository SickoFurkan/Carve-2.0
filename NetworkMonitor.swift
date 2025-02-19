import Network
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    
    @Published var isConnected = true
    @Published var connectionType = NWInterface.InterfaceType.other
    @Published var isExpensive = false
    @Published var isConstrained = false
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = path.availableInterfaces.first?.type ?? .other
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                if path.status == .satisfied {
                    print("✅ Network connection established")
                    print("   Type: \(self?.connectionTypeString ?? "unknown")")
                    print("   Expensive: \(path.isExpensive)")
                    print("   Constrained: \(path.isConstrained)")
                } else {
                    print("❌ No network connection")
                    print("   Status: \(path.status)")
                    
                    // Handle unsatisfied reason without directly accessing it
                    let reason: String
                    switch path.status {
                    case .satisfied:
                        reason = "Satisfied"
                    case .unsatisfied:
                        reason = "Unsatisfied"
                    case .requiresConnection:
                        reason = "Requires Connection"
                    @unknown default:
                        reason = "Unknown"
                    }
                    print("   Reason: \(reason)")
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    var isOnCellular: Bool {
        return connectionType == .cellular
    }
    
    var isOnWiFi: Bool {
        return connectionType == .wifi
    }
    
    var shouldAllowLargeTransfers: Bool {
        return isConnected && !isExpensive && !isConstrained
    }
    
    private var connectionTypeString: String {
        switch connectionType {
        case .wifi:
            return "WiFi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
} 