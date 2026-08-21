import 'dart:convert';

import 'package:http/http.dart' as http;

/// JSON-encodes [body] into an [http.Response] carrying a JSON content type.
http.Response jsonResponse(Object body, {int status = 200}) =>
    http.Response(jsonEncode(body), status, headers: const {'content-type': 'application/json'});
