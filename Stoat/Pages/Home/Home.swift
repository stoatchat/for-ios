//
//  HomeRewritten.swift
//  Revolt
//
//  Created by Angelo on 25/11/2023.
//
import SwiftUI
import Types

struct MaybeChannelView: View {
    @EnvironmentObject var viewState: ViewState
    @Binding var currentChannel: ChannelSelection
    @Binding var currentSelection: MainSelection
    var toggleSidebar: () -> ()
    @Binding var disableScroll: Bool
    @Binding var disableSidebar: Bool
    
    func getRawChannelView(channel: Channel) -> AnyView {
        let messages = Binding($viewState.channelMessages[channel.id])!
        let server = currentSelection.id.map { viewState.servers[$0]! }
        
        switch channel {
            case .voice_channel:
                return AnyView(VoiceChannelView(
                    channel: channel,
                    server: server,
                    toggleSidebar: toggleSidebar,
                    disableScroll: $disableScroll,
                    disableSidebar: $disableSidebar
                ))
            case .text_channel(let tc):
                if tc.voice != nil {
                    return AnyView(VoiceChannelView(
                        channel: channel,
                        server: server,
                        toggleSidebar: toggleSidebar,
                        disableScroll: $disableScroll,
                        disableSidebar: $disableSidebar
                    ))
                } else {
                    fallthrough
                }
            default:
                return AnyView(MessageableChannelView(
                    viewModel: MessageableChannelViewModel(
                        viewState: viewState,
                        channel: channel,
                        server: server,
                        messages: messages
                    ),
                    toggleSidebar: toggleSidebar,
                    disableScroll: $disableScroll,
                    disableSidebar: $disableSidebar
                ))
        }
    }

    
    var body: some View {
        let server = currentSelection.id.map { viewState.servers[$0]! }
        
        switch currentChannel {
            case .channel(let channelId):
                if let channel = viewState.channels[channelId] {
                    getRawChannelView(channel: channel)
                } else {
                    Text("Unknown Channel")
                        .onAppear {
                            currentChannel = .home
                        }
                }
                
            case .force_textchannel(let channelId):
                if let channel = viewState.channels[channelId] {
                    let messages = Binding($viewState.channelMessages[channelId])!
                    
                    MessageableChannelView(
                        viewModel: MessageableChannelViewModel(
                            viewState: viewState,
                            channel: channel,
                            server: server,
                            messages: messages
                        ),
                        toggleSidebar: toggleSidebar,
                        disableScroll: $disableScroll,
                        disableSidebar: $disableSidebar
                    )
                } else {
                    Text("Unknown Channel")
                        .onAppear {
                            currentChannel = .home
                        }
                }
            
            case .force_voicechannel(let channelId):
                if let channel = viewState.channels[channelId] {
                    VoiceChannelView(
                        channel: channel,
                        server: server,
                        toggleSidebar: toggleSidebar,
                        disableScroll: $disableScroll,
                        disableSidebar: $disableSidebar
                    )
                } else {
                    Text("Unknown Channel")
                        .onAppear {
                            currentChannel = .home
                        }
                }

            case .home:
                HomeWelcome(toggleSidebar: toggleSidebar)
            case .friends:
                VStack(spacing: 0) {
                    PageToolbar(toggleSidebar: toggleSidebar) {
                        Image(systemName: "person.3.sequence")
                            .frame(width: 16, height: 16)
                            .frame(width: 24, height: 24)
                        
                        Text("Friends")
                    }
                    
                    FriendsList()
                }
                .background(viewState.theme.background.color)
            case .noChannel:
                Text("Looks a bit empty in here.")
        }
    }
}

struct Home: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @EnvironmentObject var viewState: ViewState

    @Binding var currentSelection: MainSelection
    @Binding var currentChannel: ChannelSelection
    
    @State var offset = CGFloat.zero
    @State var forceOpen: Bool = false
    @State var calculatedSize = CGFloat.zero
    @State var disableScroll = false
    @State var disableSidebar = false
    
    let minGestureLength: CGFloat = 20
    let minSwipeVelocity: CGFloat = 200
    let minSnapPercentage: CGFloat = 0.4
    let sidebarWidthPercentage: CGFloat = 0.85
    let minSidebarWidth: CGFloat = 600
    var animationStyle: Animation? { reduceMotion ? nil : .snappy }
    
    func toggleSidebar() {

        withAnimation(animationStyle) {
            if offset != .zero {
                offset = .zero
            } else {
                offset = UIScreen.main.bounds.width*sidebarWidthPercentage
            }
        }
    }

    var body: some View {
        if isIPad || isMac {
            HStack(spacing: 0) {
                HStack(spacing: 0) {
                    ServerScrollView()
                        .frame(width: 60)
                    
                    switch currentSelection {
                        case .server(_):
                            ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                        case .dms:
                            DMScrollView(currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                    }
                }
                .frame(width: 300)
                
                MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, toggleSidebar: toggleSidebar, disableScroll: $disableScroll, disableSidebar: $disableSidebar)
                    .frame(maxWidth: .infinity)
            }
        } else {
            GeometryReader { geo in
                let sidebarWidth = min(geo.size.width * sidebarWidthPercentage, minSidebarWidth)
                let snapSide = sidebarWidth * minSnapPercentage
                
                ZStack(alignment: .topLeading) {
                    HStack(spacing: 0) {
                        ServerScrollView()
                            .frame(width: 60)
                        
                        switch currentSelection {
                            case .server(_):
                                ServerChannelScrollView(currentSelection: $currentSelection, currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                            case .dms:
                                DMScrollView(currentChannel: $currentChannel, toggleSidebar: toggleSidebar)
                        }
                    }
                    .frame(width: sidebarWidth)
                    .background(viewState.theme.background2.color)
                    
                    ZStack {
                        viewState.theme.messageBox
                            .offset(x: offset)
                            .frame(width: geo.size.width)
                            .ignoresSafeArea(.all)
                        
                        MaybeChannelView(currentChannel: $currentChannel, currentSelection: $currentSelection, toggleSidebar: toggleSidebar, disableScroll: $disableScroll, disableSidebar: $disableSidebar)
                            .allowsHitTesting(offset == 0)
                            .offset(x: offset)
                            .frame(width: geo.size.width)
                            .onTapGesture {
                                if offset != 0.0 {
                                    withAnimation(animationStyle) {
                                        offset = .zero
                                    }
                                }
                            }
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: minGestureLength)
                                // this gesture handles:
                                // - disabling scrolling on the inner view (ie text channel) to prevent two gestures from running
                                // - if the gesture length is greature than 2/5 of the width snap open
                                // - snaps open the sidebar based of the velocity
                                // - offsets the inner view by the gesture length
                                // - sets the offset back to 0 if its not being snapped open to hide it again
                                .onChanged({ g in
                                    if g.translation.width >= minGestureLength {
                                        disableScroll = true
                                    }
                                    
                                    if offset > snapSide {
                                        forceOpen = true
                                    } else if offset <= snapSide {
                                        forceOpen = false
                                    }
                                        
                                    withAnimation(animationStyle) {
                                        offset = min(max(g.translation.width, 0), sidebarWidth)
                                    }
                                })
                                .onEnded({ v in
                                    disableScroll = false
                                    
                                    let velocity = v.predictedEndLocation.x - v.location.x

                                    withAnimation(animationStyle) {
                                        if forceOpen || velocity > minSwipeVelocity {
                                            offset = sidebarWidth
                                        } else {
                                            offset = .zero
                                        }
                                    }
                                }),
                        isEnabled: !disableSidebar
                        )
                }
                .task { calculatedSize = sidebarWidth }
            }
//            .onChange(of: viewState.currentChannel, { before, after in
//                withAnimation(.easeInOut) {
//                    showSidebar = false
//                    forceOpen = false
//                    offset = .zero
//                }
//            })
//            .onChange(of: viewState.currentSelection) { before, after in
//                withAnimation {
//                    switch after {
//                        case .dms:
//                            if let last = viewState.userSettingsStore.store.lastOpenChannels["dms"] {
//                                currentChannel = .channel(last)
//                            } else {
//                                currentChannel = .home
//                            }
//                        case .server(let id):
//                            if let last = viewState.userSettingsStore.store.lastOpenChannels[id] {
//                                currentChannel = .channel(last)
//                            } else if let server = viewState.servers[id] {
//                                if let firstChannel = server.channels.compactMap({
//                                    switch viewState.channels[$0] {
//                                        case .text_channel(let c):
//                                            return c
//                                        default:
//                                            return nil
//                                    }
//                                }).first {
//                                    currentChannel = .channel(firstChannel.id)
//                                } else {
//                                    currentChannel = .noChannel
//                                }
//                            }
//                    }
//                }
//            }
        }
    }
}

#Preview {
    @Previewable @StateObject var state = ViewState.preview().applySystemScheme(theme: .dark)
    
    return Home(currentSelection: $state.currentSelection, currentChannel: $state.currentChannel)
            .environmentObject(state)
}
