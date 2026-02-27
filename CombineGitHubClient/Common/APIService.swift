//
//  Code.swift
//  Combine_Basics
//
//  Created by YAUHENI LEVIN on 10/28/25.
//

import Foundation
import Combine

/// Asynchronously fetches a sample name using a completion-handler based API.
/// - Parameter completion: Completion handler called with a `Result` containing a name on success or an `Error` on failure.
func fetchName(completion: @escaping (Result<String, Error>) -> Void) {
  DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
    completion(.success("Eugheny"))
  })
}

/// Demonstrates calling `fetchName(completion:)` and printing the result.
func run() {
  fetchName { result in
    switch result {
    case .success(let name):
      print(name)
    case .failure(let failure):
      print(failure.localizedDescription)
    }
  }
}

/// A simple user model used in caching examples.
struct User {
  let name: String
}

/// Represents GitHub API endpoints used by the app.
/// Builds URLs for searching users, fetching a user profile, followers and listing repositories.
enum Endpoint {
  case searchUsers(query: String)
  case userProfile(userName: String)
  case userRepositories(userName: String, page: Int = 1, perPage: Int = 20)
  case userFollowers(userName: String)
  
  /// Constructs the full URL for the endpoint.
  /// - Returns: A fully formed `URL` if construction succeeds; otherwise `nil`.
  var url: URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.github.com"
    
    switch self {
    case .searchUsers(let query):
      components.path = "/search/users"
      components.queryItems = [URLQueryItem(name: "q", value: query)]
    case .userProfile(let userName):
      components.path = "/users/\(userName)"
    case .userRepositories(let userName, let page, let perPage):90
      components.path = "/users/\(userName)/repos"
      components.queryItems = [
        URLQueryItem(name: "page", value: "\(page)"),
        URLQueryItem(name: "per_page", value: "\(perPage)")
      ]
    case .userFollowers(let userName):
      components.path = "/users/\(userName)/followers"
    }
    
    return components.url
  }
}

/// Demonstrates cached publishers for users.
/// These are sample publishers to illustrate `AnyPublisher` usage with and without errors.
final class UsersCache {
  /// Returns a cached users publisher that never fails.
  /// - Returns: An `AnyPublisher` emitting a static array of `User` and finishing successfully.
  static func cachedUsers() -> AnyPublisher<[User], Never> {
    let publisher = Just([User(name: "sample")])
    return publisher.eraseToAnyPublisher()
  }
  
  /// Returns a cached users publisher that can fail with a generic error type.
  /// - Returns: An `AnyPublisher` emitting a static array of `User` or failing with `Error`.
  static func cachedUserWithError() -> AnyPublisher<[User], Error> {
    Just([User(name: "sample")])
      .setFailureType(to: Error.self)
      .eraseToAnyPublisher()
  }
}

/// Represents a GitHub user returned by the search API.
struct GithubUser: Identifiable, Decodable {
  let id: Int
  let login: String
  let avatar_url: String
}

/// Top-level response container for GitHub user search.
struct Response: Decodable {
  let items: [GithubUser]
}

/// Represents a GitHub repository for a user.
struct Repository: Decodable {
  let name: String
  let language: String?
  let createdAt: Date
  let updatedAt: Date
  let stargazersCount: Int
  let watchersCount: Int
  let openIssuesCount: Int

  /// A preview repository instance for SwiftUI previews and testing.
  static var preview: Self {
    .init(
      name: "Testabe repository",
      language: "Swift", 
      createdAt: .now,
      updatedAt: .now,
      stargazersCount: 1,
      watchersCount: 1,
      openIssuesCount: 1
    )
  }
}

/// Defines operations for interacting with the GitHub API.
/// Implementations may use `URLSession` or mocked data sources.
protocol APIService {
  /// Searches GitHub users by a query string.
  /// - Parameter query: The text to search for.
  /// - Returns: A publisher emitting an array of matching `GithubUser` or failing with `Error`.
  func searchUsers(query: String) -> AnyPublisher<[GithubUser], Error>
  
  /// Fetches the profile for a given GitHub username.
  /// - Parameter user: The GitHub username.
  /// - Returns: A publisher emitting `UserProfile` or failing with `Error`.
  func getProfile(for user: String) -> AnyPublisher<UserProfile, Error>
  
  /// Fetches repositories for a user with pagination.
  /// - Parameters:
  ///   - user: The GitHub username.
  ///   - page: Page index for pagination.
  /// - Returns: A publisher emitting an array of `Repository` or failing with `APIServiceError`.
  func getRepositories(for user: String, page: Int) -> AnyPublisher<[Repository], APIServiceError>
  
  /// Fetches followers for a given GitHub username.
  /// - Parameter user: The GitHub username.
  /// - Returns: A publisher emitting an array of `Follower` or failing with `APIServiceError`.
  func getFollowers(for user: String) -> AnyPublisher<[Follower], APIServiceError>
}

/// Errors that can occur when interacting with the GitHub API.
enum APIServiceError: Error {
  case noConnection
  case badURL
  case badServerResponse
  case decodeFailure
}

/// Concrete implementation of `APIService` backed by `URLSession` requests to the GitHub API.
final class GitHubAPIService: APIService {
  /// Searches users via the GitHub Search API.
  /// - Parameter query: The search string.
  /// - Returns: A publisher emitting matching users or failing with an error.
  func searchUsers(query: String) -> AnyPublisher<[GithubUser], Error> {
    guard let url = Endpoint.searchUsers(query: query).url else {
      return Fail(error: URLError(.badURL))
        .eraseToAnyPublisher()
    }
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .tryMap { output in
        guard let response = output.response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
          throw URLError(.badServerResponse)
        }
        return output.data
      }
      .decode(type: Response.self, decoder: JSONDecoder())
      .map { $0.items }
      .eraseToAnyPublisher()
  }
  
  /// Retrieves a paginated list of repositories for the specified user.
  /// - Parameters:
  ///   - user: The GitHub username.
  ///   - page: The page index to fetch. Defaults to 1.
  /// - Returns: A publisher emitting repositories or failing with `APIServiceError`.
  func getRepositories(for user: String, page: Int = 1) -> AnyPublisher<[Repository], APIServiceError> {
    guard let url = Endpoint.userRepositories(userName: user, page: page).url else {
      return Fail(error: APIServiceError.badURL)
        .eraseToAnyPublisher()
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601

    return URLSession.shared
      .dataTaskPublisher(for: url)
      .tryMap { output in
        guard let response = output.response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
          throw APIServiceError.badServerResponse
        }
        return output.data
      }
      .decode(type: [Repository].self, decoder: decoder)
      .mapError { error -> APIServiceError in
        switch error {
         case is URLError:
           return .noConnection
         case is DecodingError:
           return .decodeFailure
         case let apiError as APIServiceError:
           return apiError
         default:
           return .decodeFailure
         }
      }
      .eraseToAnyPublisher()
  }
  
  /// Retrieves a user's profile information.
  /// - Parameter user: The GitHub username.
  /// - Returns: A publisher emitting the profile or failing with an error.
  func getProfile(for user: String) -> AnyPublisher<UserProfile, Error> {
    guard let url = Endpoint.userProfile(userName: user).url else {
      return Fail(error: URLError(.badURL))
        .eraseToAnyPublisher()
    }
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
  
    return URLSession.shared
      .dataTaskPublisher(for: url)
      .tryMap { output in
        guard let response = output.response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
          throw URLError(.badServerResponse)
        }
        return output.data
      }
      .decode(type: UserProfile.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  /// Retrieves followers for the specified user.
  /// - Parameter user: The GitHub username.
  /// - Returns: A publisher emitting followers or failing with `APIServiceError`.
  func getFollowers(for user: String) -> AnyPublisher<[Follower], APIServiceError> {
    guard let url = Endpoint.userFollowers(userName: user).url else {
      return Fail(error: APIServiceError.badURL)
        .eraseToAnyPublisher()
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    
    return URLSession.shared.dataTaskPublisher(for: url)
      .tryMap { output in
        guard let response = output.response as? HTTPURLResponse,
              200..<300 ~= response.statusCode else {
          throw URLError(.badServerResponse)
        }
        return output.data
      }
      .decode(type: [Follower].self, decoder: decoder)
      .mapError { error -> APIServiceError in
        switch error {
         case is URLError:
           return .noConnection
         case is DecodingError:
           return .decodeFailure
         case let apiError as APIServiceError:
           return apiError
         default:
           return .decodeFailure
         }
      }
      .eraseToAnyPublisher()
  }
}

enum Loadable<Value> {
  case idle
  case loading(previousValue: Value?)
  case loaded(Value)
  case error(error:Error)
}

struct SearchState {
  var searchText: String = ""
  var state: Loadable<[GithubUser]> = .idle
}
