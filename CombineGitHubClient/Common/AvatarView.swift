//  AvatarView.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/8/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import SwiftUI

enum AvatarViewType {
  case small
  case medium
  case large
  
  var size: CGSize {
    switch self {
    case .small: .init(width: 24, height: 24)
    case .medium: .init(width: 52, height: 52)
    case .large: .init(width: 96, height: 96)
    }
  }
}

struct AvatarView: View {
  let avatarURL: URL?
  let type: AvatarViewType
  
  var body: some View {
      AsyncImage(url: avatarURL) { phase in
        switch phase {
        case .empty:
          ZStack {
            Circle()
              .fill(Color.gray.opacity(0.2))
              ProgressView()
          }
        case .success(let image):
          image
            .resizable()
            .scaledToFill()
        case .failure:
          Image(systemName: "person.circle.fill")
            .resizable()
            .scaledToFill()
        @unknown default:
          EmptyView()
        }
      }
      .clipShape(Circle())
      .frame(
        width: type.size.width,
        height: type.size.height
      )
  }
}

#Preview {
  AvatarView(
    avatarURL: UserProfile.preview.avatarUrl,
    type: AvatarViewType.medium
  )
}
