enum ActivityKind {
  postPublished,
  postUpdated,
  postCreated,
  projectUpdated,
  projectCreated,
  keywordGenerated,
  unknown,
}

ActivityKind _parseKind(String s) => switch (s) {
      'post_published' => ActivityKind.postPublished,
      'post_updated' => ActivityKind.postUpdated,
      'post_created' => ActivityKind.postCreated,
      'project_updated' => ActivityKind.projectUpdated,
      'project_created' => ActivityKind.projectCreated,
      'keyword_generated' => ActivityKind.keywordGenerated,
      _ => ActivityKind.unknown,
    };

class Activity {
  Activity({
    required this.id,
    required this.kind,
    required this.title,
    required this.sub,
    required this.at,
    this.href,
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String sub;
  final DateTime at;
  final String? href;

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
        id: json['id'] as String,
        kind: _parseKind(json['kind'] as String? ?? ''),
        title: json['title'] as String? ?? '',
        sub: json['sub'] as String? ?? '',
        at: DateTime.tryParse(json['at'] as String? ?? '') ??
            DateTime.now(),
        href: json['href'] as String?,
      );
}
