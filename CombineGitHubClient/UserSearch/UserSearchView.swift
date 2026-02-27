//
//  UserSearchView.swift
//  Combine_Basics
//
//  Created by YAUHENI LEVIN on 10/28/25.
//

import SwiftUI

/// Root view for searching GitHub users. Hosts the search field and renders results based on the view model's loadable state.
struct UserSearchView: View {
  /// The view-owned source of truth for search state and side effects.
  /// Use `@StateObject` because this view creates and owns the view model.
  /// If a parent injects a view model instance, prefer `@ObservedObject` instead.
  @StateObject var viewModel = UserSearchViewModel()

    /// Top-level layout: navigation, background, and content reacting to the view model's state.
    /// The `searchable` modifier binds to `viewModel.state.searchText` to drive the Combine pipeline.
    var body: some View {
      NavigationStack {
        ZStack {
          background
          VStack(spacing: .zero) {
            content
              .padding(.top, 16)
          }
          .frame(maxHeight: .infinity, alignment: .top)
        }
        .navigationTitle("GitHub users")
        .searchable(text: $viewModel.state.searchText, prompt: "Start typing userName...  ")
      }
    }
  
  /// Alternative custom search field UI.
  /// When using the `.searchable` modifier in the navigation stack, this view is not used.
  /// Keep as a fallback or for platforms where `.searchable` is unavailable.
  private var searchField: some View {
    HStack {
      HStack {
        Image(systemName: "magnifyingglass")
          .foregroundColor(.gray)
        TextField("Search users...", text: $viewModel.state.searchText)
          .textInputAutocapitalization(.never)
          .disableAutocorrection(true)
      }
      .padding()
      .padding(.trailing)
      .background(.white.opacity(0.9))
      .cornerRadius(12)
      Button {
        viewModel.cancel()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.white)
          .frame(width: 36, height: 36)
          .background(Circle().fill(Color.blue))
          .shadow(radius: 2)
      }
      .buttonStyle(.plain)
    }
  }
  
  /// Background gradient for the screen.
  private var background: some View {
    LinearGradient(
      colors: [.white, .blue.opacity(0.2)],
      startPoint: .top,
      endPoint: .bottom
    )
    .ignoresSafeArea()
  }
  
  /// Renders different UI based on the `Loadable` state in `viewModel.state.state`.
  /// - `.idle`: Prompt to start typing
  /// - `.loading`: Spinner, optionally overlayed on previous results
  /// - `.loaded`: List of users
  /// - `.error`: An error placeholder
  @ViewBuilder
  private var content: some View {
    switch viewModel.state.state {
    case .idle:
      Text("Start typing to search")
        .foregroundColor(Color.secondary)
        .padding()
    case .loading(let previousUsers):
      if let users = previousUsers {
        usersList(users: users)
          .overlay(ProgressView())
      } else {
        ProgressView()
      }
    case .loaded(let users):
      usersList(users: users)
    case .error(let error):
      ContentUnavailableView(
        "Oops",
        image: "exclamationmark.triangle.fill",
        description: Text(error.localizedDescription)
      )
    }
  }
  
  /// Displays a list of users with navigation to profile details.
  /// - Parameter users: The users to render.
  @ViewBuilder
  private func usersList(users: [GithubUser]) ->some View {
    List(users) { user in
      NavigationLink {
        ProfileDetailsView(userID: user.login, apiService: viewModel.api)
      } label: {
        UserRow(user: user)
      }
    }
    .scrollContentBackground(.hidden)
    .background(Color.clear)
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
        }
        .padding(.vertical, 4)
    }
}
