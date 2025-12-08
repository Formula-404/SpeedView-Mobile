const String speedViewBaseUrl = String.fromEnvironment(
  'SPEEDVIEW_BASE_URL',
  defaultValue: 'https://helven-marcia-speedview.pbp.cs.ui.ac.id', // http://127.0.0.1:8000
);

String buildSpeedViewUrl(String path) {
  if (path.isEmpty) return speedViewBaseUrl;
  if (path.startsWith('/')) return '$speedViewBaseUrl$path';
  return '$speedViewBaseUrl/$path';
}
