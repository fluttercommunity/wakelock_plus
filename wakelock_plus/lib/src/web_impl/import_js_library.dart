import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

/// This is an implementation of the `import_js_library` plugin that is used
/// until that plugin is migrated to null safety.
/// See https://github.com/florent37/flutter_web_import_js_library/pull/6#issuecomment-735349208.

/// Imports a JS script file from the given [url] given the relative
/// [flutterPluginName].
///
/// Returns a Future that resolves when the library is loaded.
Future<void> importJsLibrary({required String url, String? flutterPluginName}) {
  if (flutterPluginName == null) {
    return _importJSLibraries([url]);
  }
  return _importJSLibraries([_libraryUrl(url, flutterPluginName)]);
}

String _libraryUrl(String url, String pluginName) {
  return ui_web.assetManager.getAssetUrl(url);
  //
  //   TODO: Fix this properly!
  //
  // if (url.startsWith('./')) {
  //   url = url.replaceFirst('./', '');
  //   return './assets/packages/$pluginName/$url';
  // }
  // if (url.startsWith('assets/')) {
  //   return './assets/packages/$pluginName/$url';
  // } else {
  //   return url;
  // }
}

html.ScriptElement _createScriptTag(String library) {
  final script = html.ScriptElement()
    ..type = 'text/javascript'
    ..charset = 'utf-8'
    ..async = true
    ..src = library;
  return script;
}

/// Injects a bunch of libraries in the <head> and returns a
/// Future that resolves when all load.
Future<void> _importJSLibraries(List<String> libraries) {
  final loading = <Future<void>>[];
  final head = html.querySelector('head');

  for (final library in libraries) {
    if (!_isImported(library)) {
      final scriptTag = _createScriptTag(library);
      head!.children.add(scriptTag);
      loading.add(scriptTag.onLoad.first);
      // Recommended: add an onError listener to know that something
      // went wrong here, rather than swallowing the problem.
      scriptTag.onError.listen((html.Event e) {
        final String src = (e.target as html.ScriptElement).src;
        loading.add(Future.error(
          Exception('Error loading: $src')
        ));
      });
    }
  }

  return Future.wait(loading);
}

bool _isImported(String url) {
  final head = html.querySelector('head')!;
  return _isLoaded(head, url);
}

bool _isLoaded(html.Element head, String url) {
  if (url.startsWith('./')) {
    url = url.replaceFirst('./', '');
  }
  for (var element in head.children) {
    if (element is html.ScriptElement) {
      if (element.src.endsWith(url)) {
        return true;
      }
    }
  }
  return false;
}
