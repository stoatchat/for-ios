//
//  RoleSheet.swift
//  Stoat
//
//  Lists server members who have the tapped role.
//

import SwiftUI
import Types

struct RoleSheet: View {
    @EnvironmentObject var viewState: ViewState
    @Environment(\.dismiss) private var dismiss

    let role: Role
    let serverId: String

    private var roleColour: AnyShapeStyle {
        if let colour = role.colour {
            return parseCSSColorToShapeStyle(currentTheme: viewState.theme, input: colour)
        } else {
            return AnyShapeStyle(viewState.theme.accent)
        }
    }

    private var membersWithRole: [Member] {
        guard let serverMembers = viewState.members[serverId] else { return [] }

        return serverMembers.values
            .filter { $0.roles?.contains(role.id) ?? false }
            .sorted { lhs, rhs in
                let lhsName = displayName(for: lhs)
                let rhsName = displayName(for: rhs)
                return lhsName.localizedCaseInsensitiveCompare(rhsName) == .orderedAscending
            }
    }

    private func displayName(for member: Member) -> String {
        if let nickname = member.nickname { return nickname }
        if let user = viewState.users[member.id.user] {
            return user.display_name ?? user.username
        }
        return member.id.user
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(membersWithRole, id: \.id) { member in
                        if let user = viewState.users[member.id.user] {
                            Button {
                                dismiss()
                                viewState.openUserSheet(user: user, member: member)
                            } label: {
                                HStack(spacing: 12) {
                                    Avatar(user: user, member: member, width: 32, height: 32, withPresence: true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(member.nickname ?? user.display_name ?? user.username)
                                            .foregroundStyle(viewState.theme.foreground)
                                            .lineLimit(1)

                                        if member.nickname != nil || user.display_name != nil {
                                            Text(verbatim: "@\(user.username)")
                                                .font(.caption)
                                                .foregroundStyle(viewState.theme.foreground2)
                                                .lineLimit(1)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Circle()
                            .foregroundStyle(roleColour)
                            .frame(width: 12, height: 12)

                        Text(verbatim: role.name)
                            .foregroundStyle(roleColour)

                        Spacer()

                        Text("\(membersWithRole.count)")
                            .foregroundStyle(viewState.theme.foreground2)
                    }
                    .textCase(nil)
                    .padding(.vertical, 4)
                }
                .listRowBackground(viewState.theme.background2)
            }
            .background(viewState.theme.background)
            .scrollContentBackground(.hidden)
            .navigationTitle(role.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .overlay {
                if membersWithRole.isEmpty {
                    ContentUnavailableView(
                        "No members",
                        systemImage: "person.slash",
                        description: Text("No loaded members have this role.")
                    )
                }
            }
        }
    }
}
