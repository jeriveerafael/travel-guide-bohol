import 'dart:io';

/// Serves the release web build locally so the PWA service worker can be
/// tested (service workers do not run under `flutter run`).
///
/// Usage: dart run tool/serve_web.dart [port] [--lan]
/// Add --lan to accept connections from a phone on the same network.
Future<void> main(List<String> args) async {
  final port = args.map(int.tryParse).whereType<int>().firstOrNull ?? 8123;
  final lan = args.contains('--lan');
  final root = Directory('build/web').absolute;
  if (!root.existsSync()) {
    stderr.writeln('Build the website first: flutter build web --release');
    exitCode = 1;
    return;
  }

  final server = await HttpServer.bind(
    lan ? InternetAddress.anyIPv4 : InternetAddress.loopbackIPv4,
    port,
  );
  stdout.writeln('Serving ${root.path} at http://localhost:$port');
  if (lan) {
    for (final interface in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) {
          stdout.writeln('Phone address: http://${address.address}:$port');
        }
      }
    }
  }

  await for (final request in server) {
    var path = Uri.decodeComponent(request.uri.path);
    if (path == '/' || path.isEmpty) path = '/index.html';
    final file = File('${root.path}$path');
    final resolved = file.absolute.path;
    if (!resolved.startsWith(root.path) || !file.existsSync()) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      continue;
    }

    final extension = path.split('.').last.toLowerCase();
    request.response.headers.contentType = switch (extension) {
      'js' || 'mjs' => ContentType('application', 'javascript', charset: 'utf-8'),
      'json' => ContentType.json,
      'wasm' => ContentType('application', 'wasm'),
      'html' => ContentType.html,
      'pdf' => ContentType('application', 'pdf'),
      'css' => ContentType('text', 'css', charset: 'utf-8'),
      'png' => ContentType('image', 'png'),
      'jpg' || 'jpeg' => ContentType('image', 'jpeg'),
      'svg' => ContentType('image', 'svg+xml'),
      'otf' => ContentType('font', 'otf'),
      'ttf' => ContentType('font', 'ttf'),
      _ => ContentType.binary,
    };
    request.response.headers.set('Cache-Control', 'no-cache');
    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}
