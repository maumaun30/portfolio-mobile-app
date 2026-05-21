class Skill {
  Skill({
    required this.id,
    required this.slug,
    required this.label,
    required this.sort,
  });

  final String id;
  final String slug;
  final String label;
  final int sort;

  /// Single-color SVG from simpleicons.org, tinted to ink so it reads on
  /// the dark canvas. Same trick the web admin uses.
  String get iconUrl => 'https://cdn.simpleicons.org/$slug/efe6d4';

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
        id: json['id'] as String,
        slug: json['slug'] as String,
        label: json['label'] as String,
        sort: (json['sort'] as num?)?.toInt() ?? 0,
      );

  Skill copyWith({String? slug, String? label, int? sort}) => Skill(
        id: id,
        slug: slug ?? this.slug,
        label: label ?? this.label,
        sort: sort ?? this.sort,
      );
}
