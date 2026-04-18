//
//  FollowersListViewModel.swift
//  CombineGitHubClient
//
//  Created by Yauheni Levin on 18/04/2026.
//

import Foundation

struct FollowersListViewModel {
  
  private let followersCountLimit = 99
  private let visibleFollowersLimit = 5
  
  let state: Loadable<[Follower]>
  
  var headerTitle: String {
    guard case .loaded(let followers) = state, !followers.isEmpty else {
      return "Followers"
    }
    
    let countText = followers.count > followersCountLimit
    ? "\(followersCountLimit)+"
    : "\(followers.count)"
    
    return "Followers(\(countText))"
  }
  
  var contentState: Loadable<[Follower]> {
    switch state {
    case .idle:
        .idle
    case .loading:
        .loading
    case .error:
        .error(error: nil)
    case .loaded(let followers):
        .loaded((
          followers.prefix(visibleFollowersLimit).map { $0 })
        )
    }
  }
}
