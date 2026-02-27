//  File.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/8/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import Foundation

struct Follower: Decodable, Identifiable {
  let id: Int
  let login: String
  let avatarUrl: String?
}

extension Follower {
  static let preview = Follower(id: 123, login: "elevin90", avatarUrl: "https://avatars.githubusercontent.com/u/19538431?v=4")

  static let preview2 = Follower(id: 12356, login: "elevin", avatarUrl: "https://avatars.githubusercontent.com/u/4328321?v=4")
}
