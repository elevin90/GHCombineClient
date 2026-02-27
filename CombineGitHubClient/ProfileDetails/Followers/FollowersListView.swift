//  FollowersListView.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/8/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import SwiftUI

struct FollowersListView: View {
  
  let state: Loadable<[Follower]>

  var body: some View {
    Text("Followers")
      .font(.callout)
      .foregroundStyle(.secondary)
      .padding(.leading)
    switch state {
    case .loading:
      ProgressView()
    case .loaded(let followersList):
      HStack {
        ForEach(followersList.prefix(5), id: \.id) { follower in
          Spacer()
          renderFollower(follower)
          Spacer()
            //.padding(.horizontal)
        }
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .frame(alignment: .leading)
    case .error:
      Text("Error loading followers")
    case .idle:
      EmptyView()
    }
  }
  
  @ViewBuilder
  private func renderFollower(_ follower: Follower) -> some View {
    if let avatarURL = follower.avatarUrl {
      AvatarView(
        avatarURL: URL(string: avatarURL),
        type: .medium
      )
    } else {
      Image(systemName: "person.fill")
        .resizable()
        .frame(width: 24, height: 24)
    }
  }
}

#Preview {
  FollowersListView(state: .loaded([.preview, .preview2]))
}
