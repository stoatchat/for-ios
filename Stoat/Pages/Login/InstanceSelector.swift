//
//  InstanceSelector.swift
//  Stoat
//
//

import SwiftUI
import Types

struct InstanceSelector: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.dismiss) var dismiss
    
    @State private var urlString: String = ""
    @State private var errorMessage: String? = nil
    @State private var isChecking = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://api.example.com", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(viewState.theme.foreground)
                } header: {
                    Text("API URL")
                } footer: {
                    Text("Enter the API endpoint of the instance you want to connect to, for example https://api.stoat.chat")
                }
                .listRowBackground(viewState.theme.background2)
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(viewState.theme.error)
                    }
                    .listRowBackground(viewState.theme.background2)
                }
                
                Section {
                    Button {
                        Task { await connect(to: urlString) }
                    } label: {
                        if isChecking {
                            ProgressView()
                        } else {
                            Text("Connect")
                        }
                    }
                    .disabled(isChecking || urlString.trimmingCharacters(in: .whitespaces).isEmpty)
                    
                    Button("Reset to official server") {
                        Task { await connect(to: DEFAULT_API_URL) }
                    }
                    .disabled(isChecking)
                }
                .listRowBackground(viewState.theme.background2)
            }
            .scrollContentBackground(.hidden)
            .background(viewState.theme.background)
            .navigationTitle("Choose Server")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(viewState.theme.topBar, for: .automatic)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            urlString = viewState.apiUrl
        }
    }
    
    private func normalize(_ raw: String) -> String {
        var url = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !url.contains("://") {
            url = "https://" + url
        }
        while url.hasSuffix("/") {
            url.removeLast()
        }
        return url
    }
    
    private func connect(to raw: String) async {
        let url = normalize(raw)
        guard URL(string: url) != nil else {
            errorMessage = "This is not a valid URL."
            return
        }
        
        isChecking = true
        errorMessage = nil
        
        for candidate in [url, url + "/api"] {
            let client = HTTPClient(token: nil, baseURL: candidate)
            
            if case .success(let info) = await client.fetchApiInfo() {
                viewState.apiUrl = candidate
                viewState.http = HTTPClient(token: nil, baseURL: candidate)
                viewState.http.apiInfo = info
                viewState.apiInfo = info
                isChecking = false
                dismiss()
                return
            }
        }
                
        isChecking = false
        errorMessage = "Could not reach a compatible server at \(url)"
    }
}

#Preview {
    InstanceSelector()
        .environmentObject(ViewState.preview())
}
