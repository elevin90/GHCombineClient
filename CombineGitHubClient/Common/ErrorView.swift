//  ErrorView.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 4/5/26.
//
//  A reusable SwiftUI view for presenting error states in either a compact banner
//  style or a large, content-unavailable style. Use `ErrorViewMode.compact` for
//  inline, unobtrusive messaging and `ErrorViewMode.large` for full-screen empty
//  states. Provide display data via `ErrorViewData` including a title, optional
//  system image name, and optional description.
//
//  Copyright © 2026 Yauheni Levin. All rights reserved.
//

import SwiftUI
import Foundation

/// Display mode for `ErrorView` determining layout and prominence.
enum ErrorViewMode {
  /// A minimal, inline banner-style presentation suitable for embedding within existing layouts.
  case compact
  /// A prominent, full-screen content-unavailable presentation for empty/error states.
  case large
}

/// Data model describing the content to display in an `ErrorView`.
struct ErrorViewData {
  /// Primary message to display to the user.
  let title: String
  /// Optional SF Symbols name to show alongside the title in large mode.
  let image: String?
  /// Optional secondary text providing additional context or recovery guidance.
  let description: String?
}

/// A SwiftUI view that renders an error message using a compact or large style.
struct ErrorView: View {
  /// Controls whether the view renders in `.compact` or `.large` mode.
  let mode: ErrorViewMode
  /// The content configuration for the error presentation.
  let data: ErrorViewData
  
  /// The view hierarchy for the selected `mode`.
  var body: some View {
    switch mode {
    case .compact:
      compactView
    case .large:
      largeView
    }
  }
  
  /// Large presentation using `ContentUnavailableView` with optional image and description.
  private var largeView: some View {
    ContentUnavailableView {
      if let image = data.image {
        Label(data.title, systemImage: image)
      } else {
        Text(data.title)
      }
    } description: {
      if let description = data.description {
        Text(description)
      }
    }
  }
  
  /// Compact banner-style presentation emphasizing the title.
  private var compactView: some View {
    Text(data.title)
      .font(.body)
      .fontWeight(.semibold)
      .padding()
      .frame(maxWidth: .infinity)
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(uiColor: .systemGray5))
          .shadow(radius: 2)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(Color.primary.opacity(0.1))
      )
      .padding(.horizontal, 32)
  }
}
