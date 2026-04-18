//  ProfileDetailsView.swift
//  Combine_Basics
//
//  Created by YAUHENI LEVIN on 2/23/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import SwiftUI
import Combine

struct UserProfile: Decodable, Identifiable {
  let id: Int
  let login: String
  let name: String?
  let location: String?
  let avatarUrl: URL?
  let followersUrl: URL?
  let followingUrl: String
  let followers: Int
  let following: Int
  let publicRepos: Int
  
  static var preview: Self {
    .init(
      id: 12345,
      login: "elevin90",
      name: "Yauheni Levin",
      location: "Warsaw, Poland",
      avatarUrl: URL(string: "https://avatars.githubusercontent.com/u/19538431?v=4"),
      followersUrl: URL(string: "https://api.github.com/users/elevin90/following{/other_user}"),
      followingUrl: "",
      followers: 1,
      following: 2,
      publicRepos: 14
    )
  }
}

struct ProfileDetailsView: View {
  
  enum SocialTypes {
    case followers
    case subscriptions
    
    var title: String {
      switch self {
      case .followers:
        "Followers"
      case .subscriptions:
        "Subscriptions"
      }
    }
    
    var image: String {
      switch self {
      case .followers:
        "person.2.fill"
      case .subscriptions:
        "star.fill"
      }
    }
  }
  
  @StateObject var viewModel: ProfileDetailsViewModel
  
  init(userID: String, apiService: APIService) {
    _viewModel = StateObject(
      wrappedValue: ProfileDetailsViewModel(
        api: apiService,
        userId: userID
      ))
  }
  
  var body: some View {
    ZStack {
      switch viewModel.state.profileState {
      case .loaded(let profile):
        contentView(for: profile)
      case .loading:
        ProgressView()
      case .error:
        ContentUnavailableView(
          "Oops... something went wrong",
          image: "exclamationmark.triangle.fill"
        )
      case .idle:
        EmptyView()
      }
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          // TODO: Add share
        } label: {
          Image(systemName: "square.and.arrow.up")
        }
      }
    }
    .navigationTitle("Profile")
#if os(iOS)
    .navigationBarTitleDisplayMode(.inline)
#endif
  }
  
  @ViewBuilder
  private func contentView(for profile: UserProfile) -> some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 18) {
        headerView(for: profile)
        FollowersListView(state: viewModel.state.followersState)
        RepositoriesView(state: viewModel.state.repositoriesState)
      }
      .padding(.top)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
  
  private var isUserLoaded: Bool {
    if case .loaded = viewModel.state.profileState {
      return true
    }
    return false
  }
  
  @ViewBuilder
  private func headerView(for profile: UserProfile) -> some View {
    HStack(spacing: 16) {
      AvatarView(avatarURL: profile.avatarUrl, type: .large)
      headerUserNamesView(for: profile)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(.background)
        .shadow(radius: 4)
      
    )
    .padding(.horizontal)
  }

  @ViewBuilder
  private func headerUserAvatarView(for profile: UserProfile) -> some View {
    AsyncImage(url: profile.avatarUrl) { phase in
      switch phase {
      case .success(let image):
        image
          .resizable()
          .scaledToFill()
      default:
        Image(systemName: "person.circle.fill")
          .resizable()
          .scaledToFill()
      }
    }
    .frame(width: 64, height: 64)
    .clipShape(Circle())
    .shadow(radius: 4)
  }
  
  private func headerUserNamesView(for profile: UserProfile) -> some View {
    VStack(alignment: .leading) {
      let name = profile.name ?? "Github user \(profile.id)"
      Text(name)
        .fontWeight(.bold)
        .font(.title2)
      Text(profile.login)
        .font(.callout)
        .foregroundColor(.secondary)
      if let location = profile.location {
        Text(location)
          .fontWeight(.bold)
          .foregroundColor(.secondary)
      }
    }
  }
}

#if DEBUG
private struct MockAPIService: APIService {
  func searchUsers(query: String, page: Int) -> AnyPublisher<[GithubUser], any Error> {
    Just([GithubUser(id: 1, login: "", avatar_url: "")])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
  
  func getFollowers(for user: String) -> AnyPublisher<[Follower], APIServiceError> {
    Just([Follower.preview, Follower.preview2])
      .setFailureType(to: APIServiceError.self)
      .eraseToAnyPublisher()
  }
  
  func getRepositories(for user: String, page: Int) -> AnyPublisher<[Repository], APIServiceError> {
    Just([Repository.preview] )
      .setFailureType(to: APIServiceError.self)
      .eraseToAnyPublisher()
  }
  
  func getProfile(for user: String) -> AnyPublisher<UserProfile, any Error> {
    Just(UserProfile.preview)
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
}
#endif

#Preview("ProfileDetailsView – Mocked") {
  NavigationStack {
    ProfileDetailsView(userID: "elevin90", apiService: MockAPIService())
  }
}
