//  ProfileDetailsViewModel.swift
//  Combine_Basics
//
//  Created by YAUHENI LEVIN on 2/24/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import Foundation
import Combine

struct ProfileDetailsViewState {
  var profileState: Loadable<UserProfile> = .idle
  var repositoriesState: Loadable<[Repository]> = .idle
  var followersState: Loadable<[Follower]> = .idle
}

final class ProfileDetailsViewModel: ObservableObject {
  private let api: APIService
  private var cancellables = Set<AnyCancellable>()
  @Published private(set) var state = ProfileDetailsViewState()
  
  init(api: APIService, userId: String) {
    self.api = api
    loadProfile(for: userId)
    loadRepositories(for: userId)
    loadFollowers(for: userId)
  }
  
  private func loadProfile(for userId: String) {
    state.profileState = .loading
    api.getProfile(for: userId)
      .map { Loadable.loaded($0) }
      .catch { error in
        Just(.error(error: error))
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] loadable in
        self?.state.profileState = loadable
      }
      .store(in: &cancellables)
  }
  
  func loadRepositories(for userId: String) {
    state.repositoriesState = .loading
    api.getRepositories(for: userId, page: 1)
      .map { reposies in
        reposies.sorted(by: { $0.stargazersCount > $1.stargazersCount })
          .prefix(5)
      }
      .map { Array($0) }
      .map { Loadable.loaded($0) }
      .catch { error in
        Just(.error(error: error))
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] repositories in
        self?.state.repositoriesState = repositories
      }
      .store(in: &cancellables)
  }
  
  func loadFollowers(for userId: String) {
    state.profileState = .loading
    api.getFollowers(for: userId)
      .map { Loadable.loaded($0) }
      .catch {error in
        Just(.error(error: error))
      }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] followers in
        self?.state.followersState = followers
      }
      .store(in: &cancellables)
    
  }
  
}
