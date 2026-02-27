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
    VStack(alignment: .leading, spacing: 8) {
      header
      content
    }
  }
  
  private var header: some View {
    Label("Followers", systemImage: "person.2")
      .font(.callout)
      .foregroundStyle(.secondary)
      .padding(.horizontal)
  }
  
  @ViewBuilder
  private var content: some View {
    switch state {
    case .idle:
      EmptyView()
      
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity)
      
    case .error:
      Text("Error loading followers")
      
    case .loaded(let followers):
      if followers.isEmpty {
        emptyView
      } else {
        followersRow(followers)
      }
    }
  }
  
  private var emptyView: some View {
    ErrorView(
      mode: .compact,
      data: .init(
        title: "No followers found",
        image: nil,
        description: nil
      )
    )
  }
  
  private func followersRow(_ followers: [Follower]) -> some View {
    HStack {
      ForEach(followers.prefix(5), id: \.id) { follower in
        Spacer()
        renderFollower(follower)
        Spacer()
      }
      Spacer()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
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
  FollowersListView(state: .loaded([]))
}
