//  UserSearchViewModel.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/17/26.
//  Copyright © 2026 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// Represents user-driven intents.
private enum Action {
  case searchChanged(String)
  case loadNextPage
  case cancel
}

/// ViewModel responsible for searching GitHub users with pagination.
/// Implements a unidirectional data flow using Combine.
final class UserSearchViewModel: ObservableObject {
  
  // MARK: - Public State
  
  /// Full UI state consumed by SwiftUI
  @Published var state = SearchState()
  
  /// Indicates whether pagination request is in progress
  @Published private(set) var isLoadingNextPage = false
  
  // MARK: - Dependencies
  
  /// API service used for fetching GitHub users
  let api: APIService
  
  // MARK: - Private State
  
  /// Internal action stream
  private let action = PassthroughSubject<Action, Never>()
  
  /// Combine cancellables
  private var cancellables = Set<AnyCancellable>()
  
  /// Current page index (starts from 1)
  private var currentPage = 1
  
  /// Indicates if more pages are available
  private var hasMorePages = true
  
  // MARK: - Init
  
  /// Initializes ViewModel with API dependency
  /// - Parameter api: Service for fetching GitHub users
  init(api: APIService = GitHubAPIService()) {
    self.api = api
    bind()
  }
  
  // MARK: - Binding
  
  /// Binds user input and actions into a reactive pipeline.
  /// Converts UI events into side effects and state updates.
  private func bind() {
    bindSearchInput()
    bindActions()
  }
  
  /// Observes search text changes and emits corresponding actions.
  private func bindSearchInput() {
    let minimalTextLength = 2
    $state
      .map(\.searchText)
      .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
      .removeDuplicates()
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .sink { [weak self] text in
        guard let self else { return }
        
        switch text.count {
        case .zero:
          action.send(.cancel)
        case minimalTextLength...:
          action.send(.searchChanged(text))
        default:
          break
        }
      }
      .store(in: &cancellables)
  }
  
  /// Main action processing pipeline.
  /// Maps actions into side-effect publishers and updates state.
  private func bindActions() {
    action
      .map { [weak self] action -> AnyPublisher<Loadable<[GithubUser]>, Never> in
        guard let self else {
          return Just(.idle).eraseToAnyPublisher()
        }

        return switch action {
        case .searchChanged(let query):
           makeSearchPublisher(query: query)
        case .loadNextPage:
           makeNextPagePublisher()
        case .cancel:
           makeResetPublisher()
        }
      }
      .switchToLatest()
      .receive(on: DispatchQueue.main)
      .sink { [weak self] newValue in
        self?.state.results = newValue
      }
      .store(in: &cancellables)
  }
  
  // MARK: - Public API
  
  /// Requests loading of the next page (pagination trigger).
  func loadNextPage() {
    action.send(.loadNextPage)
  }
  
  /// Cancels current search and resets state.
  func cancel() {
    action.send(.cancel)
  }
  
  // MARK: - Publishers
  
  /// Creates a publisher for performing a new search request.
  /// - Parameter query: Search query string
  private func makeSearchPublisher(query: String) -> AnyPublisher<Loadable<[GithubUser]>, Never> {
    
    resetPagination()
    
    let previousUsers = currentUsers
    
    return api.searchUsers(query: query, page: currentPage)
      .map { Loadable.loaded($0) }
      .prepend(.loading(previousValue: previousUsers))
      .catch { Just(Loadable.error(error: $0)) }
      .eraseToAnyPublisher()
  }
  
  /// Creates a publisher for loading the next page.
  private func makeNextPagePublisher() -> AnyPublisher<Loadable<[GithubUser]>, Never> {
    
    guard canLoadNextPage else {
      return Empty().eraseToAnyPublisher()
    }
    
    isLoadingNextPage = true
    
    let nextPage = currentPage + 1
    let existingUsers = currentUsers ?? []
    
    return api.searchUsers(query: state.searchText, page: nextPage)
      .map { [weak self] newUsers -> Loadable<[GithubUser]> in
        guard let self else { return .loaded(existingUsers) }
        
        if newUsers.isEmpty {
          self.hasMorePages = false
          return .loaded(existingUsers)
        }
        
        self.currentPage = nextPage
        return .loaded(existingUsers + newUsers)
      }
      .catch { Just(Loadable.error(error: $0)) }
      .handleEvents(receiveCompletion: { [weak self] _ in
        self?.isLoadingNextPage = false
      })
      .eraseToAnyPublisher()
  }
  
  /// Creates a publisher that resets state.
  private func makeResetPublisher() -> AnyPublisher<Loadable<[GithubUser]>, Never> {
    resetAll()
    return Just(.idle).eraseToAnyPublisher()
  }
  
  // MARK: - Helpers
  
  /// Returns currently loaded users (if any).
  private var currentUsers: [GithubUser]? {
    if case .loaded(let users) = state.results {
      return users
    }
    return nil
  }
  
  /// Indicates whether next page can be loaded.
  private var canLoadNextPage: Bool {
    hasMorePages &&
    !isLoadingNextPage &&
    currentUsers != nil
  }
  
  /// Resets pagination-related state.
  private func resetPagination() {
    currentPage = 1
    hasMorePages = true
    isLoadingNextPage = false
  }
  
  /// Fully resets ViewModel state.
  private func resetAll() {
    resetPagination()
    state = SearchState()
  }
}
