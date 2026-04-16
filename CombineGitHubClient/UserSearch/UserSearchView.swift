//
//  UserSearchView.swift
//  Combine_Basics
//
//  Created by YAUHENI LEVIN on 10/28/25.
//

import SwiftUI

/// Root view for searching GitHub users. Hosts the search field and renders results based on the view model's loadable state.
struct UserSearchView: View {
  enum Constants {
    static let usersListTopOffset: CGFloat = 18
    static let userRowCornerRadius: CGFloat = 12
  }
  /// The view-owned source of truth for search state and side effects.
  /// Use `@StateObject` because this view creates and owns the view model.
  /// If a parent injects a view model instance, prefer `@ObservedObject` instead.
  @StateObject var viewModel = UserSearchViewModel()
  
  /// Top-level layout: navigation, background, and content reacting to the view model's state.
  /// The `searchable` modifier binds to `viewModel.state.searchText` to drive the Combine pipeline.
  var body: some View {
    NavigationStack {
      content
        .navigationTitle("GitHub users")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
          text: $viewModel.state.searchText,
          placement: .navigationBarDrawer,
          prompt: "Start typing username... "
        )
    }
  }
  
  /// Renders different UI based on the `Loadable` state in `viewModel.state.state`.
  /// - `.idle`: Prompt to start typing
  /// - `.loading`: Spinner, optionally overlayed on previous results
  /// - `.loaded`: List of users
  /// - `.error`: An error placeholder
  @ViewBuilder
  private var content: some View {
    switch viewModel.state.results {
    case .idle:
      emptyView
    case .loading:
      spinnerView
    case .loaded(let users):
      usersList(users)
    case .error(let error):
      errorView(with: error)
    }
  }
  
  private func errorView(with error: Error) -> some View {
    ContentUnavailableView(
      "Oops",
      image: "exclamationmark.triangle.fill",
      description: Text(error.localizedDescription)
    )
  }
  
  private var emptyView: some View {
    ContentUnavailableView(
      "Start typing",
      image: "magnifyingglass",
      description: Text("Search GitHub users")
    )
  }
  
  private var spinnerView: some View {
    VStack {
      Spacer()
      ProgressView()
      Spacer()
    }
  }
  
  /// Displays a list of users with navigation to profile details.
  /// - Parameter users: The users to render.
  @ViewBuilder
  private func usersList(_ users: [GithubUser]) ->some View {
    ScrollView {
      LazyVStack(spacing: Constants.usersListTopOffset) {
        ForEach(users) { user in
          row(for: user)
            .onAppear {
              guard user.id == users.last?.id else { return }
              guard !viewModel.isLoadingNextPage else { return }
              viewModel.loadNextPage()
            }
        }
        if viewModel.isLoadingNextPage {
          ProgressView()
        }
      }
    }
    .padding(.top, Constants.usersListTopOffset)
  }
  
  private func row(for user: GithubUser) -> some View {
    NavigationLink {
      ProfileDetailsView(
        userID: user.login,
        apiService: viewModel.api
      )
    } label: {
      UserRow(user: user)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: Constants.userRowCornerRadius)
            .fill(Color(.secondarySystemBackground))
        )
    }
    .buttonStyle(.plain)
  }
}

// Preview for development and design-time rendering.
#Preview {
  UserSearchView()
}

/// A single row showing a user's avatar and login.
struct UserRow: View {
  
  /// The user model backing this row.
  let user: GithubUser
  
  var body: some View {
    HStack(spacing: 12) {
      AvatarView(
        avatarURL: URL(string: user.avatar_url),
        type: .medium
      )
      Text(user.login)
        .font(.headline)
      
      Spacer()
      
      Image(systemName: "chevron.right")
        .foregroundColor(.secondary)
    }
  }
}
