import 'package:web/web.dart' as web;

bool setWebSessionItem(String key, String value) {
  web.window.sessionStorage.setItem(key, value);
  return true;
}

String? getWebSessionItem(String key) {
  return web.window.sessionStorage.getItem(key);
}

bool removeWebSessionItem(String key) {
  web.window.sessionStorage.removeItem(key);
  return true;
}