//
//  Welcome.swift
//  Revolt
//
//  Created by Angelo Manca on 2023-11-15.
//

import SwiftUI
import Types

struct Welcome: View {
    @EnvironmentObject var viewState: ViewState
    @State private var path = NavigationPath()
    @State private var mfaTicket = ""
    @State private var mfaMethods: [String] = []
    @State private var showInstanceSelector = false
    @Binding var wasSignedOut: Bool

    @Environment(\.colorScheme) var colorScheme: ColorScheme

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                if wasSignedOut {
                    VStack {
                        Spacer()
                            .frame(height: 25)
                        Text("You have been logged out")
                            .padding(.horizontal, 25)
                            .padding(.vertical, 10)
                            .foregroundStyle(.white)
                            .background(Color(hue: 0, saturation: 95, brightness: 25))
                            .addBorder(.red, cornerRadius: 8)
                        Spacer()
                    }
                    .transition(.slideTop)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: {
                            withAnimation {
                                wasSignedOut = false
                            }
                        })
                    }
                }
                VStack {
                    Spacer()
                    Group {
                        Image("wide")
                            .resizable()
                            .if(colorScheme == .light, content: { $0.colorInvert() })
                            .aspectRatio(contentMode: .fit)
                            .padding(.horizontal, 32)
                            .padding(.bottom, 20)
                        
                        Text("Find your community, connect with the world.")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .foregroundColor((colorScheme == .light) ? Color.black : Color.white)
                        
                        Text("Stoat is one of the best ways to stay connected with your friends and community, anywhere, anytime.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 55.0)
                            .padding(.top, 10.0)
                            .font(.footnote)
                            .foregroundColor((colorScheme == .light) ? Color.black : Color.white)
                    }
                    
                    Spacer()
                    
                    Group {
                        NavigationLink("Log In", value: "login")
                            .padding(.vertical, 10)
                            .frame(width: 200.0)
                            .background((colorScheme == .light) ? Color.black : Color.white)
                            .foregroundColor((colorScheme == .light) ? Color.white : Color.black)
                            .cornerRadius(50)
                        
                        NavigationLink("Sign Up", value: "signup")
                            .padding(.vertical, 10)
                            .frame(width: 200.0)
                            .foregroundColor(.black)
                            .background((colorScheme == .light) ? Color(white: 0.851) : Color(white: 0.4))
                            .cornerRadius(50)
                    }
                    
                    Button {
                        showInstanceSelector = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "server.rack")
                            Text(URL(string: viewState.apiUrl)?.host ?? viewState.apiUrl)
                        }
                        .font(.footnote)
                        .foregroundColor(Color(white: 0.584))
                    }
                    .padding(.top, 12)
                    
                    Spacer()
                    
                    Group {
                        Link("Terms of Service", destination: URL(string: "https://stoat.chat/legal/terms")!)
                            .font(.footnote)
                            .foregroundColor(Color(white: 0.584))
                        Link("Privacy Policy", destination: URL(string: "https://stoat.chat/legal/privacy")!)
                            .font(.footnote)
                            .foregroundColor(Color(white: 0.584))
                        Link("Community Guidelines", destination: URL(string: "https://stoat.chat/legal/community-guidelines")!)
                            .font(.footnote)
                            .foregroundColor(Color(white: 0.584))
                    }
                }
                .navigationDestination(for: String.self) { dest in
                    switch dest {
                    case "mfa":
                        Mfa(path: $path, ticket: $mfaTicket, methods: $mfaMethods)
                    case "login":
                        LogIn(path: $path, mfaTicket: $mfaTicket, mfaMethods: $mfaMethods)
                    case "signup":
                        CreateAccount()
                    case _:
                        EmptyView()
                    }
                    
                }
            }
            .sheet(isPresented: $showInstanceSelector) {
                InstanceSelector()
            }
            .onAppear {
                viewState.isOnboarding = false
            }
            .task {
                viewState.apiInfo = try? await viewState.http.fetchApiInfo().get()
            }
        }
    }
}

#Preview {
    @Previewable @State var signedOut = true
    
    Welcome(wasSignedOut: $signedOut)
        .environmentObject(ViewState.preview())
}
