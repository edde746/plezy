import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

import 'auth_callback.dart';

/// Provides an authentication handler for HTTP requests with support for access
/// and refresh tokens, customizable headers, and query parameters.
///
/// This class manages token-based authentication for HTTP requests, allowing
/// you to configure access and refresh tokens, as well as related headers and
/// query parameters. It supports automatic token refresh if an access token
/// expires and facilitates using a refresh token endpoint.
///
/// To use, :
/// - Create a [Task] as with a simple url, without query parameters, and
///   no headers. Query parameters and headers will be added based on the
///   [Auth] object, that you add to the task via [Task.options]. Include
///   [TaskOptions] with the [Auth] object as follows:
/// - Create an [Auth] object
/// - Add [accessQueryParams] containing all url query parameters. If your auth
///   uses query parameters for auth, then use `{accessToken}` to indicate where
///   the token should go, eg `{"auth":"{accessToken}"}` will add the access
///   token to the ur query parameter auth
/// - Add [accessHeaders] containing all headers required for the task. If your
///   auth uses headers, then use `{accessToken}` to indicate where the token
///   should go, eg `{"Authentication":" Bearer {accessToken}"}` will add a
///   typical authentication header for OAuth or JWT based requests.
/// - Add information for refresh, eg [refreshToken], [refreshUrl] if you want
///   to use the default handler
/// - If you use your own handler, add that as `onAuth` - otherwise the refresh
///   will be attempted using [defaultOnAuth]
///
/// For tasks that contain an [Auth] object, the background_downloader will
/// first check if the token is expired. If the token is expired, it will call
/// the `onAuth` callback, which should refresh the token by calling
/// [refreshToken], which will update the [Auth] associated with the task, then
/// return the modified task.
/// The downloader will substitute the `{accessToken}` placeholder with the
/// accessToken in both query parameters and headers before executing the task.
///
/// ### Key Properties
/// - [accessToken]: The current access token used for authentication.
/// - [refreshToken]: The refresh token used to obtain a new access token.
/// - [accessHeaders]: Headers to include in authenticated requests, with
///   optional `{accessToken}` placeholders for dynamic token insertion.
/// - [refreshHeaders]: Headers to include when making a refresh token request,
///   with option `{refreshToken}` placeholders for dynamic token insertion.
/// - [onAuth]: callback to be called before the task starts if access token is
///   expired. Callback should return a modified Task, or null to try with the
///   original
///
/// ### Key Methods
/// - [getAccessUri]: Returns the URI with authentication query parameters,
///   automatically refreshing the access token if needed.
/// - [getAccessHeaders]: Returns the headers to be used with the access
///   request, with the `{accessToken}` placeholder replaced
/// - [refreshAccessToken]: Refreshes the access token using the configured
///   refresh token and updates the expiry time. Called by [getAccessUri]
/// - [isTokenExpired]: Checks if the access token is nearing expiry.
///
/// ### Example
/// ```dart
/// final auth = Auth(
///   accessToken: 'initialAccessToken',
///   refreshToken: 'initialRefreshToken',
///   refreshUrl: 'https://example.com/token/refresh',
/// );
///
/// // Make a request with updated headers and query parameters
/// Uri uri = await auth.getAccessUri(url: 'https://example.com/data');
/// Map<String, String> headers = auth.getAccessHeaders();
/// ```
class Auth {
  static final log = Logger('Auth');

  /// The access token used for authentication
  String? accessToken;

  /// Headers to use for access requests. Can contain {accessToken} and
  /// {refreshToken} which will be replaced by the actual tokens
  Map<String, String> accessHeaders;

  /// Query parameters to use for access requests. Can contain {accessToken} and
  /// {refreshToken} which will be replaced by the actual tokens
  Map<String, String> accessQueryParams;

  /// Time when the access token expires
  DateTime? accessTokenExpiryTime;

  /// The refresh token used to obtain a new access token
  String? refreshToken;

  /// Headers to use for refresh requests. Can contain {accessToken} and
  /// {refreshToken} which will be replaced by the actual tokens
  Map<String, String> refreshHeaders;

  /// Query parameters to use for refresh requests. Can contain {accessToken} and
  /// {refreshToken} which will be replaced by the actual tokens
  Map<String, String> refreshQueryParams;

  /// The URL to use for refreshing the token
  String? refreshUrl;
  int? _onAuthRawHandle; // for callback

  /// Creates an [Auth] object
  ///
  /// [accessToken] is the initial access token
  /// [accessHeaders] are headers to use for access requests
  /// [accessQueryParams] are query parameters to use for access requests
  /// [accessTokenExpiryTime] is the time when the access token expires
  /// [refreshToken] is the initial refresh token
  /// [refreshUrl] is the URL to use for refreshing the token
  /// [refreshHeaders] are headers to use for refresh requests
  /// [refreshQueryParams] are query parameters to use for refresh requests
  /// [onAuth] is a callback to be called when the access token expires
  Auth({
    this.accessToken,
    this.accessHeaders = const {},
    this.accessQueryParams = const {},
    this.accessTokenExpiryTime,
    this.refreshToken,
    this.refreshUrl,
    this.refreshHeaders = const {},
    this.refreshQueryParams = const {},
    OnAuthCallback? onAuth,
  }) : _onAuthRawHandle = onAuth != null
           ? PluginUtilities.getCallbackHandle(onAuth)?.toRawHandle()
           : null;

  /// Convert the Auth instance to JSON
  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'accessHeaders': accessHeaders,
    'accessQueryParams': accessQueryParams,
    'accessTokenExpiryTime': accessTokenExpiryTime?.millisecondsSinceEpoch,
    'refreshToken': refreshToken,
    'refreshUrl': refreshUrl,
    'refreshHeaders': refreshHeaders,
    'refreshQueryParams': refreshQueryParams,
    'onAuthRawHandle': _onAuthRawHandle,
  };

  /// Create an Auth instance from JSON
  Auth.fromJson(Map<String, dynamic> json)
    : accessToken = json['accessToken'],
      accessHeaders = json['accessHeaders'] != null
          ? Map<String, String>.from(json['accessHeaders'])
          : const {},
      accessQueryParams = json['accessQueryParams'] != null
          ? Map<String, String>.from(json['accessQueryParams'])
          : const {},
      accessTokenExpiryTime = json['accessTokenExpiryTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['accessTokenExpiryTime'] as int,
            )
          : null,
      refreshToken = json['refreshToken'],
      refreshUrl = json['refreshUrl'],
      refreshHeaders = json['refreshHeaders'] != null
          ? Map<String, String>.from(json['refreshHeaders'])
          : const {},
      refreshQueryParams = json['refreshQueryParams'] != null
          ? Map<String, String>.from(json['refreshQueryParams'])
          : const {},
      _onAuthRawHandle = json['onAuthRawHandle'] as int?;

  /// Returns the [OnAuthCallback] registered with this [Auth], or null
  OnAuthCallback? get onAuthCallback => _onAuthRawHandle != null
      ? PluginUtilities.getCallbackFromHandle(
          CallbackHandle.fromRawHandle(_onAuthRawHandle!),
        ) as OnAuthCallback
      : null;

  /// Set the [OnAuthCallback]
  set onAuthCallback(OnAuthCallback? onAuth) =>
      _onAuthRawHandle = onAuth != null
      ? PluginUtilities.getCallbackHandle(onAuth)?.toRawHandle()
      : null;

  /// Returns the Uri for accessing the resource
  ///
  /// Refreshes the [accessToken] if required, and returns the original
  /// [url] or [uri] with access query parameters. If headers are used to
  /// authenticate, then call [getAccessHeaders] after this call, to make sure
  /// they contain updated access tokens.
  Future<Uri> getAccessUri({
    String? url,
    Uri? uri,
    http.Client? httpClient,
    String? refreshUrl,
    Uri? refreshUri,
  }) async {
    if (uri == null && url == null) {
      throw ArgumentError('Either uri or url must be provided');
    }
    final accessUri = uri ?? Uri.parse(url!);
    if (isTokenExpired()) {
      // make the refresh request
      final (updatedAccesstoken, _) = await refreshAccessToken(
        httpClient: httpClient,
        refreshUrl: refreshUrl,
        refreshUri: refreshUri,
      );
      if (!updatedAccesstoken) {
        throw const HttpException('Could not refresh access token');
      }
    }
    return addOrUpdateQueryParams(
      uri: accessUri,
      queryParams: getAccessQueryParams(),
    );
  }

  /// Returns the URL string for accessing the resource
  ///
  /// Refreshes the [accessToken] if required, and returns the original
  /// [url] or [uri] with access query parameters. If headers are used to
  /// authenticate, then call [getAccessHeaders] after this call, to make sure
  /// they contain updated access tokens.
  Future<String> getAccessUrl({
    String? url,
    Uri? uri,
    http.Client? httpClient,
    String? refreshUrl,
    Uri? refreshUri,
  }) async {
    final accessUri = await getAccessUri(
      url: url,
      uri: uri,
      httpClient: httpClient,
      refreshUrl: refreshUrl,
      refreshUri: refreshUri,
    );
    return accessUri.toString();
  }

  /// Refresh the [accessToken] by calling [refreshUrl] or [refreshUri] using
  /// [httpClient], adding [refreshHeaders] and [refreshQueryParams]
  /// to the request and obtaining the token from the json response
  /// 'access_token' and potential 'expires_in'.
  /// If the response contains 'refresh_token' that will be updated as well.
  ///
  /// Returns (bool updatedAccessToken, bool updatedRefreshToken)
  ///
  /// If neither [refreshUrl] nor [refreshUri] are given, the Auth object's
  /// [Auth.refreshUrl] is used
  Future<(bool, bool)> refreshAccessToken({
    http.Client? httpClient,
    String? refreshUrl,
    Uri? refreshUri,
  }) async {
    if (refreshUrl == null && refreshUri == null && this.refreshUrl == null) {
      throw ArgumentError(
        'refreshUrl, refreshUri or Auth object refreshUrl required',
      );
    }
    var updatedAccessToken = false;
    var updatedRefreshToken = false;
    final client = httpClient ?? http.Client();
    try {
      final selectedRefreshUri =
          refreshUri ?? Uri.parse(refreshUrl ?? this.refreshUrl!);
      final uri = addOrUpdateQueryParams(
        uri: selectedRefreshUri,
        queryParams: expandMap(refreshQueryParams),
      );
      final headers = expandMap(refreshHeaders);
      headers['Content-type'] = 'application/json';
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAuthToken = data['access_token'];
        if (newAuthToken != null) {
          accessToken = newAuthToken;
          updatedAccessToken = true;
          final newExpiresIn = data['expires_in'];
          if (newExpiresIn != null) {
            accessTokenExpiryTime = DateTime.now().add(
              Duration(seconds: newExpiresIn),
            );
          }
        } else {
          log.fine(
            'Failed to refresh access token: no access_token in response body.\n'
            'Body is ${response.body}',
          );
        }
        final newRefreshToken = data['refresh_token'];
        if (newRefreshToken != null) {
          refreshToken = newRefreshToken;
          updatedRefreshToken = true;
        }
      } else {
        log.fine('Failed to refresh token: ${response.statusCode}');
      }
    } catch (e) {
      log.warning('Error refreshing token: $e');
    }
    return (updatedAccessToken, updatedRefreshToken);
  }

  /// Returns the headers specified for the access request, with the
  /// template {accessToken} and {refreshToken} replaced
  Map<String, String> getAccessHeaders() => expandMap(accessHeaders);

  /// Returns the query params specified for the access request, with the
  /// template {accessToken} and {refreshToken} replaced
  Map<String, String> getAccessQueryParams() => expandMap(accessQueryParams);

  /// Add/update the query parameters in this [url] or [uri] with [queryParams]
  /// and return the new uri
  Uri addOrUpdateQueryParams({
    String? url,
    Uri? uri,
    Map<String, String> queryParams = const {},
  }) {
    if (uri == null && url == null) {
      throw ArgumentError('Either uri or url must be provided');
    }
    final startUri = uri ?? Uri.parse(url!);
    if (queryParams.isEmpty) {
      return startUri;
    }
    final updatedQueryParams = Map<String, String>.from(
      startUri.queryParameters,
    );
    queryParams.forEach((key, value) {
      updatedQueryParams[key] = value;
    });
    return startUri.replace(queryParameters: updatedQueryParams);
  }

  /// Returns true if the [accessTokenExpiryTime is after now plus
  /// the [bufferTime], otherwise returns false
  bool isTokenExpired({Duration bufferTime = const Duration(seconds: 10)}) {
    if (accessTokenExpiryTime == null) return false;
    return DateTime.now().add(bufferTime).isAfter(accessTokenExpiryTime!);
  }

  /// Expands the [mapToExpand] by replacing {accessToken} and {refreshToken}
  ///
  /// Returns the expanded map, without changing the original
  Map<String, String> expandMap(Map<String, String> mapToExpand) {
    final (access, refresh) = (accessToken, refreshToken);
    final newMap = <String, String>{};
    mapToExpand.forEach((key, value) {
      var newValue = value;
      if (access != null) {
        newValue = newValue.replaceAll('{accessToken}', access);
      }
      if (refresh != null) {
        newValue = newValue.replaceAll('{refreshToken}', refresh);
      }
      newMap[key] = newValue;
    });
    return newMap;
  }
}
