// // const String speedViewBaseUrl = String.fromEnvironment(
// //   'SPEEDVIEW_BASE_URL',
// //   defaultValue: 'https://helven-marcia-speedview.pbp.cs.ui.ac.id',
// // );

// const String speedViewBaseUrl = String.fromEnvironment(
//   'SPEEDVIEW_BASE_URL',
//   defaultValue: 'https://localhost:8000',
// );

// String buildSpeedViewUrl(String path) {
//   if (path.isEmpty) return speedViewBaseUrl;
//   if (path.startsWith('/')) return '$speedViewBaseUrl$path';
//   return '$speedViewBaseUrl/$path';
// }

// lib/common/constants.dart

// Untuk development lokal pakai HTTP (Django runserver tidak support HTTPS).
// Untuk deploy ke server PBP, override pakai:
// flutter run --dart-define=SPEEDVIEW_BASE_URL=https://helven-marcia-speedview.pbp.cs.ui.ac.id
// lib/common/constants.dart

/// Base URL backend SpeedView.
///
/// Untuk development lokal, Django jalan di http://127.0.0.1:8000.
/// Kalau nanti pakai server produksi, ubah defaultValue atau
/// set environment variable SPEEDVIEW_BASE_URL saat build.
const String speedViewBaseUrl = String.fromEnvironment(
  'SPEEDVIEW_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
  // Catatan:
  // - Android emulator biasanya pakai http://10.0.2.2:8000
  // - iOS simulator & Flutter web bisa pakai http://127.0.0.1:8000
);

String buildSpeedViewUrl(String path) {
  if (path.isEmpty) return speedViewBaseUrl;
  if (path.startsWith('/')) return '$speedViewBaseUrl$path';
  return '$speedViewBaseUrl/$path';
}
