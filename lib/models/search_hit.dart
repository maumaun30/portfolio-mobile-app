enum HitKind { project, post, skill, keyword, unknown }

HitKind _parseKind(String s) => switch (s) {
      'project' => HitKind.project,
      'post' => HitKind.post,
      'skill' => HitKind.skill,
      'keyword' => HitKind.keyword,
      _ => HitKind.unknown,
    };

class SearchHit {
  SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    required this.sub,
    required this.href,
  });

  final String id;
  final HitKind kind;
  final String title;
  final String sub;
  final String href;

  factory SearchHit.fromJson(Map<String, dynamic> json) => SearchHit(
        id: json['id'] as String,
        kind: _parseKind(json['kind'] as String? ?? ''),
        title: json['title'] as String? ?? '',
        sub: json['sub'] as String? ?? '',
        href: json['href'] as String? ?? '',
      );
}
