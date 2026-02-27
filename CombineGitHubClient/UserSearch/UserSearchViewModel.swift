//  UserSearchViewModel.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/17/26.
//  Copyright © 2026 ___ORGANIZATIONNAME___. All rights reserved.
//

import Foundation
import Combine

/// A view model is used to operate UserSearch view logic
final class UserSearchViewModel: ObservableObject {
  /// Backing view state for the User Search screen.
  /// Contains the current `searchText` and a `Loadable<[GithubUser]>` representing the results.
  @Published var state = SearchState()
  
  /// A signal used to cancel any in-flight search request.
  /// Emitted when the user clears the search field or calls `cancel()`.
  private let cancelTapped = PassthroughSubject<Void, Never>()
  
  /// Abstraction over the GitHub API used to search for users.
  /// Default implementation is `GitHubAPIService`.
  let api: APIService
  
  /// Storage for Combine subscriptions created by this view model.
  private var cancellables = Set<AnyCancellable>()
  
  /// Creates a new instance of `UserSearchViewModel`.
  /// - Parameter api: The service used to perform API requests. Defaults to `GitHubAPIService`.
  /// Automatically binds the Combine pipeline to react to search text changes.
  init(api: APIService = GitHubAPIService()) {
    self.api = api
    bind()
  }
  
  /// Wires up the Combine pipeline that observes search text changes and performs debounced searches.
  private func bind() {
    // Minimum number of characters required before a search is triggered.
    let minimalCharactersCount = 2
    $state
        // Observe the search text from the view state.
        // Extract just the `searchText` field to observe.
        .map(\.searchText)
        // Wait for 500ms pauses in typing before searching to reduce API calls.
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        // Ignore repeated identical queries.
        .removeDuplicates()
        // If the user clears the text, cancel the current search and reset state.
        .handleEvents(receiveOutput: { [weak self] text in
          if text.isEmpty {
            self?.cancel()
          }
        })
        // Trim leading/trailing whitespace before searching.
        .map { $0.trimmingCharacters(in: .whitespaces) }
        // Only search when the query has enough characters.
        .filter { $0.count >= minimalCharactersCount }
        // Transform the query into a `Loadable`-emitting publisher that performs the network request.
        .map { [weak self] query -> AnyPublisher<Loadable<[GithubUser]>, Never> in
            // If the view model has been deallocated, emit an idle state and stop.
            guard let self else {
                return Just(.idle).eraseToAnyPublisher()
            }

            // Preserve previously loaded users to display while a new request is loading.
            let previousUsers: [GithubUser]? = {
                if case .loaded(let users) = self.state.state {
                    return users
                }
                return nil
            }()

            // Update UI state to loading, keeping the previous value if available.
            self.state.state = .loading(previousValue: previousUsers)

            // Kick off the API request for users matching the query.
            return self.api.searchUsers(query: query)
                // Wrap the successful result in a Loadable.loaded value.
                .map { Loadable.loaded($0) }
                // Convert any error into a non-failing Loadable.error publisher.
                .catch { error in
                    Just(Loadable.error(error: error))
                }
                // Cancel this request if a cancel signal arrives (e.g., user cleared the text).
                .prefix(untilOutputFrom: self.cancelTapped)
                .eraseToAnyPublisher()
        }
        // Only keep the most recent search; cancel prior in-flight requests.
        .switchToLatest()
        // Ensure UI updates happen on the main thread.
        .receive(on: DispatchQueue.main)
        // Apply the new loadable state to the view state.
        .sink { [weak self] loadable in
            self?.state.state = loadable
        }
        // Retain the subscription for the lifetime of the view model.
        .store(in: &cancellables)
    }
  
  /// Cancels any in-flight search, resets the loadable state to `.idle`, and clears the search text.
  func cancel() {
    cancelTapped.send(())
    state.state = .idle
    state.searchText = ""
  }
}

