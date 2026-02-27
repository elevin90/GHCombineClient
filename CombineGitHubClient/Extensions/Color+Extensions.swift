//  Color+Extensions.swift
//  CombineGitHubClient
//
//  Created by YAUHENI LEVIN on 3/5/26.
//  Copyright © 2026 YAUHENI LEVIN. All rights reserved.
//


import Foundation
import SwiftUI

extension Color {
  
  static func languageColor(for language: String?) -> Color {
    guard let language else { return .gray }
    
    switch language {
    case "Swift": return Color(hex: "#F05138")
    case "Kotlin": return Color(hex: "#A97BFF")
    case "JavaScript": return Color(hex: "#F1E05A")
    case "TypeScript": return Color(hex: "#3178C6")
    case "Python": return Color(hex: "#3572A5")
    case "Go": return Color(hex: "#00ADD8")
    case "Rust": return Color(hex: "#DEA584")
    case "C": return Color(hex: "#555555")
    case "C++": return Color(hex: "#F34B7D")
    case "C#": return Color(hex: "#178600")
    case "Java": return Color(hex: "#B07219")
    case "Ruby": return Color(hex: "#701516")
    case "PHP": return Color(hex: "#4F5D95")
    case "HTML": return Color(hex: "#E34C26")
    case "CSS": return Color(hex: "#563D7C")
    case "Shell": return Color(hex: "#89E051")
    case "Objective-C": return Color(hex: "#438EFF")
    case "Objective-C++": return Color(hex: "#6866FB")
    case "Dart": return Color(hex: "#00B4AB")
    case "Scala": return Color(hex: "#C22D40")
    case "Elixir": return Color(hex: "#6E4A7E")
    case "Haskell": return Color(hex: "#5E5086")
    case "Lua": return Color(hex: "#000080")
    case "Groovy": return Color(hex: "#4298B8")
    case "Perl": return Color(hex: "#0298C3")
    case "R": return Color(hex: "#198CE7")
    case "MATLAB": return Color(hex: "#E16737")
    case "PowerShell": return Color(hex: "#012456")
    case "Dockerfile": return Color(hex: "#384D54")
    case "Makefile": return Color(hex: "#427819")
    case "Assembly": return Color(hex: "#6E4C13")
    case "TeX": return Color(hex: "#3D6117")
    case "Crystal": return Color(hex: "#000100")
    case "Nim": return Color(hex: "#FFC200")
    case "Zig": return Color(hex: "#EC915C")
    case "OCaml": return Color(hex: "#3BE133")
    case "F#": return Color(hex: "#B845FC")
    case "Fortran": return Color(hex: "#4D41B1")
    case "Julia": return Color(hex: "#A270BA")
    default: return .gray
    }
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    
    let r, g, b: UInt64
    switch hex.count {
    case 6:
      (r, g, b) = ((int >> 16) & 255, (int >> 8) & 255, int & 255)
    default:
      (r, g, b) = (1, 1, 1)
    }
    
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: 1
    )
  }
}
