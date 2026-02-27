//  RepositoriesView.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/2/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import SwiftUI

struct RepositoriesView: View {
  let state: Loadable<[Repository]>
  let gridItem = [GridItem(.fixed(180))]
  
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Repositories")
          .font(.callout)
          .foregroundStyle(.secondary)
          .padding(.horizontal)
        Spacer()
        Button("See all") {
          
        }
        .buttonStyle(.bordered)
        .padding(.horizontal)
      }
      contentView
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
  }
  
  @ViewBuilder
  private var contentView: some View {
    switch state {
    case .loading:
      ProgressView()
        .frame(maxWidth: .infinity)
    case .loaded(let repositories):
      repositriesGridView(for: repositories)
        .overlay {
          if repositories.isEmpty {
            ContentUnavailableView(
              "No repositories found",
              image: "exclamationmark.triangle.fill"
            )
            .frame(alignment: .top)
          }
        }
    case .error:
      ContentUnavailableView(
        "Error loading repositories",
        image: "exclamationmark.triangle.fill"
      )
    case .idle:
      EmptyView()
    }
  }
  
  @ViewBuilder
  private func repositriesGridView(for repositories: [Repository]) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      LazyHGrid(rows: gridItem, alignment: .top, spacing: 16) {
        ForEach(repositories, id: \.name) { repository in
          repositoryCell(for: repository)
            .contentShape(Rectangle())
        }
      }
      .padding(2)
    }
    .padding(.horizontal, 4)
  }
  
  @ViewBuilder
  private func repositoryCell(for repository: Repository) -> some View {
    HStack {
      repositoryCellInfoViews(for: repository)
      Spacer()
      repositoryCellStatisticsViews(for: repository)
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(uiColor: .systemBackground))
    )
    .frame(width: 280, alignment: .leading)
    .frame(height: 102)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(Color.primary.opacity(0.1))
    )
  }

  @ViewBuilder
  private func repositoryCellInfoViews(for repository: Repository) -> some View {
    VStack(alignment: .leading) {
      Text(repository.name)
        .font(.headline)
        .bold()
        .lineLimit(1)
        .fontDesign(.rounded)
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

  @ViewBuilder
  private func repositoryCellStatisticsViews(for repository: Repository) -> some View {
    VStack {
      HStack(spacing: 8) {
        Label("\(repository.stargazersCount)", systemImage: "star")
        Label("\(repository.watchersCount)", systemImage: "eye")
      }
      .font(.caption)
      .foregroundStyle(.secondary)
    }
  }
}

#Preview {
  RepositoriesView(state: .loaded([.preview]))
}
