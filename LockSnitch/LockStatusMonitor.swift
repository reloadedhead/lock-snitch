import Foundation
import Combine

class LockStatusMonitor: ObservableObject {
    @Published var isLocked = false
    
    init() {
        setupLockObservers()
    }
    
    private func setupLockObservers() {
        let dnc = DistributedNotificationCenter.default()
        
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsLocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLocked = true
            self?.sendWebhook(locked: true)
        }
        
        dnc.addObserver(
            forName: NSNotification.Name("com.apple.screenIsUnlocked"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isLocked = false
            self?.sendWebhook(locked: false)
        }
    }
    
    private func sendWebhook(locked: Bool) {
        // Read settings from UserDefaults
        let webhookEnabled = UserDefaults.standard.bool(forKey: "webhookEnabled")
        guard webhookEnabled else {
            print("⏸️ Webhook disabled")
            return
        }
        
        let baseURLString = UserDefaults.standard.string(forKey: "webhookBaseURL") ?? ""
        guard var components = URLComponents(string: baseURLString) else {
            print("❌ Invalid webhook URL")
            return
        }
        
        // Load custom parameters
        var queryItems: [URLQueryItem] = []
        
        if let data = UserDefaults.standard.data(forKey: "webhookParameters"),
           let parameters = try? JSONDecoder().decode([URLParameter].self, from: data) {
            queryItems = parameters
                .filter { !$0.key.isEmpty }
                .map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        // Add lock status parameter with configured name and type
        let lockStatusParamName = UserDefaults.standard.string(forKey: "lockStatusParamName") ?? "state"
        let lockStatusTypeRaw = UserDefaults.standard.string(forKey: "lockStatusType") ?? LockStatusType.boolean.rawValue
        let lockStatusType = LockStatusType(rawValue: lockStatusTypeRaw) ?? .boolean
        
        queryItems.append(URLQueryItem(
            name: lockStatusParamName,
            value: lockStatusType.value(for: locked)
        ))
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            print("❌ Failed to construct URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("❌ Webhook error: \(error.localizedDescription)")
            } else {
                print("✅ Webhook sent: \(url.absoluteString)")
            }
        }.resume()
    }

    
}
