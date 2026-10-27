//
//  Auth.swift
//
//  Created by Bram on 11/8/24.
//

import Foundation

struct Auth: Codable, Hashable {
    var accessToken: String?
    var accessHeaders: [String: String] = [:]
    var accessQueryParams: [String: String] = [:]
    var accessTokenExpiryTime: Int64?
    var refreshToken: String?
    var refreshHeaders: [String: String] = [:]
    var refreshQueryParams: [String: String] = [:]
    var refreshUrl: String?
    var onAuthRawHandle: Int64?

    /**
     * Returns the headers specified for the access request, with the
     * template `{accessToken}` and `{refreshToken}` replaced.
     */
    func getExpandedAccessHeaders() -> [String: String] {
        return expandMap(accessHeaders)
    }

    /**
     * Returns the query parameters specified for the access request, with the
     * template `{accessToken}` and `{refreshToken}` replaced.
     */
    func getExpandedAccessQueryParams() -> [String: String] {
        return expandMap(accessQueryParams)
    }

    /// Add/update the query parameters in this `url` with `queryParams`
    /// and return the new URI.
    func addOrUpdateQueryParams(
        url: String,
        queryParams: [String: String] = [:]
    ) -> URL {
        guard let startUri = URL(string: url) else {
            // Handle invalid URL gracefully, e.g., return the original URL or throw an error
            return URL(string: url)!
        }
        guard !queryParams.isEmpty else { return startUri }

        var components = URLComponents(url: startUri, resolvingAgainstBaseURL: false)!
        var updatedQueryParams = components.queryItems?.reduce(into: [String: String]()) { (result, item) in
            result[item.name] = item.value
        } ?? [:]
        
        for (key, value) in queryParams {
            updatedQueryParams[key] = value
        }

        components.queryItems = updatedQueryParams.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
    
    /// Returns true if the `accessTokenExpiryTime` is after now plus
    /// the `bufferTime`, otherwise returns false.
    func isTokenExpired(bufferTime: Int64 = 10000) -> Bool {
        guard let expiry = accessTokenExpiryTime else { return false }
        let expiryTimeWithBuffer = Int64(Date().timeIntervalSince1970 * 1000) + bufferTime
        return expiryTimeWithBuffer > expiry
    }
    
    /// Expands the [mapToExpand] by replacing {accessToken} and {refreshToken}
    ///
    /// Returns the expanded map, without changing the original
    private func expandMap(_ mapToExpand: [String: String]) -> [String: String] {
        var newMap: [String: String] = [:]
        for (key, value) in mapToExpand {
            var newValue = value
            if let accessToken = accessToken {
                newValue = newValue.replacingOccurrences(of: "{accessToken}", with: accessToken)
            }
            if let refreshToken = refreshToken {
                newValue = newValue.replacingOccurrences(of: "{refreshToken}", with: refreshToken)
            }
            newMap[key] = newValue
        }
        return newMap
    }
    
    /// True if this `Auth` object has an 'onAuth' callback that can be called to refresh the
    /// access token.
    func hasOnAuthCallback() -> Bool {
        return onAuthRawHandle != nil
    }
}
