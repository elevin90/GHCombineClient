//  RepositoriesView.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/2/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import SwiftUI

/// A section showing a header and a horizontally scrolling list of repositories.
struct RepositoriesView: View {
  /// The loading state driving the content (idle, loading, error, or loaded repositories).
  let state: Loadable<[Repository]>
  
  /// Composes the header and content, expanding to the full available width.
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      RepositoriesHeaderView()
      RepositoriesContentView(state: state)
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
  }
}

// MARK: - Header

/// Header for the repositories section with a title and an action.
private struct RepositoriesHeaderView: View {
  /// Displays the section label and a trailing 'See all' button.
  var body: some View {
    HStack {
      Label("Repositories", systemImage: "character.book.closed")
        .font(.callout)
        .foregroundStyle(.secondary)
      
      Spacer()
      
      Button("See all") {}
        .buttonStyle(.bordered)
    }
    .padding(.horizontal)
  }
}

// MARK: - Content

/// Renders repository content based on the provided loading `state`.
private struct RepositoriesContentView: View {
  /// The current loading state for the repositories list.
  let state: Loadable<[Repository]>
  
  /// Single fixed-height row configuration for the horizontal grid.
  private static let gridRows = [GridItem(.fixed(118))]
  
  /// Switches on the `state` to show a spinner, error, empty state, or the repositories grid.
  var body: some View {
    Group {
      switch state {
      case .idle:
        EmptyView()
      case .loading:
        ProgressView().frame(maxWidth: .infinity)
      case .error:
        errorView
      case .loaded(let repositories):
        if repositories.isEmpty {
          ErrorView(
            mode: .compact,
            data: .init(title: "No Repositories found")
          )
          .padding(.vertical)
        } else {
          repositoriesGrid(repositories)
        }
      }
    }
  }
  
  /// A horizontally scrolling grid of repository cells.
  /// - Parameter repositories: The repositories to display.
  /// - Returns: A scrollable grid view.
  private func repositoriesGrid(_ repositories: [Repository]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHGrid(rows: Self.gridRows, spacing: 16) {
        ForEach(repositories, id: \.name) { repo in
          RepositoryCellView(repository: repo)
            .contentShape(Rectangle())
        }
      }
      .padding(2)
    }
    .padding(.horizontal, 4)
  }
  
  /// Content shown when there are no repositories to display.
  private var emptyView: some View {
    ContentUnavailableView(
      "No repositories found",
      image: "exclamationmark.triangle.fill"
    )
  }
  
  /// Content shown when loading repositories fails.
  private var errorView: some View {
    ContentUnavailableView(
      "Error loading repositories",
      image: "exclamationmark.triangle.fill"
    )
  }
}

// MARK: - Cell

/// A compact card presenting a repository's basic information and stats.
private struct RepositoryCellView: View {
  /// The repository model used to populate the cell.
  let repository: Repository
  
  /// Lays out the repository info and stats within a styled card.
  var body: some View {
    HStack {
      info
      Spacer()
      stats
    }
    .padding()
    .frame(width: 280, height: 102, alignment: .leading)
    .background(background)
    .overlay(border)
  }
  
  /// Name, creation date, and optional primary language.
  private var info: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(repository.name)
        .font(.headline)
        .fontDesign(.rounded)
        .lineLimit(1)
      
      Text(repository.createdAt, style: .date)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      if let language = repository.language {
        Label {
          Text(language)
            .font(.subheadline)
        } icon: {
          Circle()
            .fill(Color.languageColor(for: language))
            .frame(width: 12, height: 12)
        }
      }
    }
  }
  
  /// Star and watcher counts displayed with system icons.
  private var stats: some View {
    HStack(spacing: 8) {
      Label("\(repository.stargazersCount)", systemImage: "star")
      Label("\(repository.watchersCount)", systemImage: "eye")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
  }
  
  /// Card background appearance.
  private var background: some View {
    RoundedRectangle(cornerRadius: 16)
      .fill(Color(uiColor: .systemBackground))
  }
  
  /// Subtle card border to separate from the background.
  private var border: some View {
    RoundedRectangle(cornerRadius: 16)
      .stroke(Color.primary.opacity(0.1))
  }
}

