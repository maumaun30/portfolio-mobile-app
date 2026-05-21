enum PostType { blog, caseStudy }

extension PostTypeJson on PostType {
  String get apiValue => switch (this) {
        PostType.blog => 'blog',
        PostType.caseStudy => 'case_study',
      };
  String get label => switch (this) {
        PostType.blog => 'Blog',
        PostType.caseStudy => 'Case study',
      };
  static PostType fromApi(String s) =>
      s == 'case_study' ? PostType.caseStudy : PostType.blog;
}

class Post {
  Post({
    required this.id,
    required this.type,
    required this.slug,
    required this.title,
    required this.excerpt,
    required this.coverImage,
    required this.body,
    required this.status,
    required this.sort,
    this.publishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final PostType type;
  final String slug;
  final String title;
  final String excerpt;
  final String coverImage;
  final String body;
  final String status; // 'published' | 'draft'
  final int sort;
  final DateTime? publishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPublished => status == 'published';

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as String,
        type: PostTypeJson.fromApi(json['type'] as String? ?? 'blog'),
        slug: json['slug'] as String? ?? '',
        title: json['title'] as String? ?? '',
        excerpt: json['excerpt'] as String? ?? '',
        coverImage: json['coverImage'] as String? ?? '',
        body: json['body'] as String? ?? '',
        status: json['status'] as String? ?? 'published',
        sort: (json['sort'] as num?)?.toInt() ?? 0,
        publishedAt: _parseDate(json['publishedAt']),
        createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
        updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  return null;
}
