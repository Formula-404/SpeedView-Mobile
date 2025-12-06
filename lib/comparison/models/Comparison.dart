import 'dart:convert';

class Comparison {
  final String id;
  final String title;
  final String module;
  final String moduleLabel;
  final bool isPublic;
  final String ownerName;
  final DateTime? createdAt;
  final String detailUrl;
  final List<String> items;

  Comparison({
    required this.id,
    required this.title,
    required this.module,
    required this.moduleLabel,
    required this.isPublic,
    required this.ownerName,
    required this.createdAt,
    required this.detailUrl,
    required this.items,
  });

  factory Comparison.fromJson(Map<String, dynamic> json) {
    final created = json['created_at'] as String? ?? '';
    DateTime? createdAt;
    if (created.isNotEmpty) {
      try {
        createdAt = DateTime.parse(created);
      } catch (_) {
        createdAt = null;
      }
    }

    return Comparison(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Untitled',
      module: json['module'] as String? ?? '',
      moduleLabel: json['module_label'] as String? ?? (json['module'] as String? ?? '—'),
      isPublic: json['is_public'] as bool? ?? false,
      ownerName: json['owner_name'] as String? ?? '—',
      createdAt: createdAt,
      detailUrl: json['detail_url'] as String? ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static List<Comparison> listFromResponseBody(String body) {
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final ok = decoded['ok'] as bool? ?? false;
    if (!ok) {
      throw Exception(decoded['error'] ?? 'Failed to load comparisons');
    }
    final data = decoded['data'] as List<dynamic>? ?? <dynamic>[];
    return data.map((e) => Comparison.fromJson(e as Map<String, dynamic>)).toList();
  }
}
