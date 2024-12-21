import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

/// This is an implementation of the `import_js_library` plugin that is used
/// until that plugin is migrated to null safety.
/// See https://github.com/florent37/flutter_web_import_js_library/pull/6#issuecomment-735349208.

/// Imports a JS script file from the given [url] given the relative
/// [flutterPluginName].
Future<void> importJsLibrary(
    {required String url, String? flutterPluginName}) async {
  if (flutterPluginName == null) {
    return _importJSLibraries([url]);
  } else {
    return _importJSLibraries([_libraryUrl(url, flutterPluginName)]);
  }
}

String _libraryUrl(String url, String pluginName) {
  // Added suggested changes as per
  // https://github.com/fluttercommunity/wakelock_plus/issues/19#issuecomment-2301963609
  if (url.startsWith('./')) {
    url = url.replaceFirst('./', '');
  }

  if (url.startsWith('assets/')) {
    return ui_web.assetManager.getAssetUrl(
      'packages/$pluginName/$url',
    );
  }

  return url;
}

web.HTMLScriptElement _createScriptTag(String library) {
  final script = web.document.createElement('script') as web.HTMLScriptElement
    ..type = 'text/javascript'
    ..charset = 'utf-8'
    ..async = true
    ..src = library;
  return script;
}

/// Injects a bunch of libraries in the `<head>` and returns a
/// Future that resolves when all load.
Future<void> _importJSLibraries(List<String> libraries) {
  final loading = <Future<void>>[];
  final head = web.document.head;

  for (final library in libraries) {
    if (!_isImported(library)) {
      final scriptTag = _createScriptTag(library);
      head!.appendChild(scriptTag);
      loading.add(scriptTag.onLoad.first);
      scriptTag.onError.listen((event) {
        final scriptElement = event.target.isA<web.HTMLScriptElement>()
            ? event.target as web.HTMLScriptElement
            : null;
        if (scriptElement != null) {
          loading.add(
            Future.error(
              Exception('Error loading: ${scriptElement.src}'),
            ),
          );
        }
      });
    }
  }

  return Future.wait(loading);
}

bool _isImported(String url) {
  final head = web.document.head!;
  return _isLoaded(head, url);
}

bool _isLoaded(web.HTMLHeadElement head, String url) {
  if (url.startsWith('./')) {
    url = url.replaceFirst('./', '');
  }
  for (int i = 0; i < head.children.length; i++) {
    final element = head.children.item(i)!;
    if (element.instanceOfString('HTMLScriptElement')) {
      if ((element as web.HTMLScriptElement).src.endsWith(url)) {
        return true;
      }
    }
  }
  return false;
}
