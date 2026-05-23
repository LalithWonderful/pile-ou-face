import 'dart:io';

/// Simple HTTP server that receives raw PNG bytes from the integration test
/// running on the iOS simulator and writes them to disk.
///
/// Usage (run on host, BEFORE the integration test):
///   dart marketing/screenshot_server.dart
void main() async {
  final outputDir = Directory('marketing/screenshots/daily_message');
  outputDir.createSync(recursive: true);

  final server = await HttpServer.bind('localhost', 8765);
  print('Screenshot server listening on http://localhost:8765');
  print('Output directory: ${outputDir.absolute.path}');

  await for (final request in server) {
    if (request.method == 'POST' && request.uri.path == '/screenshot') {
      final filename = request.uri.queryParameters['name'];
      if (filename == null || filename.isEmpty) {
        request.response.statusCode = 400;
        await request.response.close();
        continue;
      }

      final bytes = <int>[];
      await for (final chunk in request) {
        bytes.addAll(chunk);
      }

      File('${outputDir.path}/$filename').writeAsBytesSync(bytes);
      print('Saved $filename (${bytes.length} bytes)');
      request.response.statusCode = 200;
      await request.response.close();
    } else {
      request.response.statusCode = 404;
      await request.response.close();
    }
  }
}
