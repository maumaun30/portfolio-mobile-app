class Keyword {
  Keyword({
    required this.id,
    required this.term,
    required this.enabled,
    this.lastUsedAt,
    required this.createdAt,
  });

  final String id;
  final String term;
  final bool enabled;
  final DateTime? lastUsedAt;
  final DateTime createdAt;

  factory Keyword.fromJson(Map<String, dynamic> json) => Keyword(
        id: json['id'] as String,
        term: json['term'] as String,
        enabled: json['enabled'] as bool? ?? true,
        lastUsedAt: _parseDate(json['lastUsedAt']),
        createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
