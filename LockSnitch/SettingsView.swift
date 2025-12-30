import SwiftUI

struct SettingsView: View {
    @AppStorage("webhookBaseURL") private var webhookBaseURL = "http://homebridge-ip:51828"
    @AppStorage("webhookEnabled") private var webhookEnabled = true
    @AppStorage("lockStatusParamName") private var lockStatusParamName = "state"
    @AppStorage("lockStatusType") private var lockStatusTypeRaw = LockStatusType.boolean.rawValue
    
    @State private var parameters: [URLParameter] = []
    @State private var isTestingWebhook = false
    @State private var testResult: TestResult?
    
    private var lockStatusType: Binding<LockStatusType> {
        Binding(
            get: { LockStatusType(rawValue: lockStatusTypeRaw) ?? .boolean },
            set: { lockStatusTypeRaw = $0.rawValue }
        )
    }
    
    enum TestResult {
        case success(String)
        case failure(String)
    }
    
    var body: some View {
        Form {
            Section {
                Toggle("Enable Webhook", isOn: $webhookEnabled)
                    .toggleStyle(.switch)
                
                TextField("Base URL:", text: $webhookBaseURL)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!webhookEnabled)
                
                // Test Button
                HStack {
                    Button(action: testWebhook) {
                        Text(isTestingWebhook ? "Testing..." : "Test")
                    }
                    .disabled(webhookBaseURL.isEmpty || isTestingWebhook)
                    
                    // Test Result
                    if let result = testResult {
                        switch result {
                        case .success(let message):
                            Label(message, systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        case .failure(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            } header: {
                Text("Webhook Configuration")
            } footer: {
                Text("Lock Snitch will make a GET request to the URL above. You can further configure the request below.")
            }
            
            Section {
                TextField("Parameter Name", text: $lockStatusParamName)
                    .textFieldStyle(.roundedBorder)
                
                Picker("Value Format", selection: lockStatusType) {
                    ForEach(LockStatusType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                
            } header: {
                Text("Lock Status Parameter")
            } footer: {
                Text("Configure how the lock/unlock status is sent to your webhook.")
            }
            
            Section {
                ForEach($parameters) { $param in
                    HStack(alignment: .center, spacing: 8) {
                        VStack {
                            TextField("Key", text: $param.key)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Value", text: $param.value)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Button(action: {
                            deleteParameter(param)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                Button(action: addParameter) {
                    Label("Add Parameter", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.plain)
            } header: {
                Text("Additional URL Parameters")
                    .font(.headline)
            } footer: {
                VStack(alignment: .leading) {
                    Text("Further customise your Webhook call.")
                    if !parameters.isEmpty {
                        Text("Preview: \(constructPreviewURL())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                            .lineLimit(2)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 550, height: 600)
        .padding()
        .onAppear(perform: loadParameters)
        .onChange(of: parameters) { _ in
            saveParameters()
        }
    }
    
    private func testWebhook() {
        isTestingWebhook = true
        testResult = nil
        
        guard var components = URLComponents(string: webhookBaseURL) else {
            testResult = .failure("Invalid URL")
            isTestingWebhook = false
            return
        }
        
        // Build query items
        var queryItems = parameters
            .filter { !$0.key.isEmpty }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        
        // Add test lock status (unlocked = false/0)
        queryItems.append(URLQueryItem(
            name: lockStatusParamName,
            value: lockStatusType.wrappedValue.value(for: false)
        ))
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            testResult = .failure("Failed to construct URL")
            isTestingWebhook = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 10
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isTestingWebhook = false
                
                if let error = error {
                    testResult = .failure("Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if (200...299).contains(httpResponse.statusCode) {
                        testResult = .success("Success! Status: \(httpResponse.statusCode)")
                    } else {
                        testResult = .failure("HTTP \(httpResponse.statusCode)")
                    }
                } else {
                    testResult = .success("Request sent")
                }
            }
        }.resume()
    }
    
    private func addParameter() {
        parameters.append(URLParameter())
    }
    
    private func deleteParameter(_ parameter: URLParameter) {
        parameters.removeAll { $0.id == parameter.id }
    }
    
    private func constructPreviewURL() -> String {
        guard var components = URLComponents(string: webhookBaseURL) else {
            return webhookBaseURL
        }
        
        var queryItems = parameters
            .filter { !$0.key.isEmpty }
            .map { URLQueryItem(name: $0.key, value: $0.value) }
        
        // Add lock status parameter example
        queryItems.append(URLQueryItem(
            name: lockStatusParamName,
            value: lockStatusType.wrappedValue.value(for: false)
        ))
        
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return components.url?.absoluteString ?? webhookBaseURL
    }
    
    private func saveParameters() {
        if let encoded = try? JSONEncoder().encode(parameters) {
            UserDefaults.standard.set(encoded, forKey: "webhookParameters")
        }
    }
    
    private func loadParameters() {
        if let data = UserDefaults.standard.data(forKey: "webhookParameters"),
           let decoded = try? JSONDecoder().decode([URLParameter].self, from: data) {
            parameters = decoded
        } else {
            parameters = [
                URLParameter(key: "accessoryId", value: "maclock")
            ]
        }
    }
}

#Preview {
    SettingsView()
        .onAppear {
            // Set up preview data
            UserDefaults.standard.set("http://192.168.1.100:51828", forKey: "webhookBaseURL")
            UserDefaults.standard.set(true, forKey: "webhookEnabled")
            UserDefaults.standard.set("locked", forKey: "lockStatusParamName")
            UserDefaults.standard.set(LockStatusType.number.rawValue, forKey: "lockStatusType")
            
            // Mock parameters
            let mockParams = [
                URLParameter(key: "accessoryId", value: "maclock"),
                URLParameter(key: "token", value: "secret123")
            ]
            if let encoded = try? JSONEncoder().encode(mockParams) {
                UserDefaults.standard.set(encoded, forKey: "webhookParameters")
            }
        }
}
