class Project {
  Project({
    required this.id,
    required this.name,
    this.slug,
    required this.domain,
    required this.link,
    required this.featuredImage,
    this.description,
    this.caseStudySlug,
    this.stacks = const [],
    this.status = 'published',
    this.sort = 0,
    this.isCurrent = false,
  });

  final String id;
  final String? slug;
  final String name;
  final String domain;
  final String link;
  final String featuredImage;
  final String? description;
  final String? caseStudySlug;
  final List<String> stacks;
  final String status;
  final int sort;
  final bool isCurrent;

  bool get isPublished => status == 'published';

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as String,
        slug: json['slug'] as String?,
        name: json['name'] as String,
        domain: json['domain'] as String? ?? '',
        link: json['link'] as String? ?? '',
        featuredImage: json['featuredImage'] as String? ?? '',
        description: json['description'] as String?,
        caseStudySlug: json['caseStudySlug'] as String?,
        stacks: (json['stacks'] as List?)?.cast<String>() ?? const [],
        status: json['status'] as String? ?? 'published',
        sort: (json['sort'] as num?)?.toInt() ?? 0,
        isCurrent: json['isCurrent'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'domain': domain,
        'link': link,
        'featuredImage': featuredImage,
        'description': description,
        'caseStudySlug': caseStudySlug,
        'stacks': stacks,
        'status': status,
        'sort': sort,
        'isCurrent': isCurrent,
      };

  Project copyWith({
    String? slug,
    String? name,
    String? domain,
    String? link,
    String? featuredImage,
    String? description,
    String? caseStudySlug,
    List<String>? stacks,
    String? status,
    int? sort,
    bool? isCurrent,
  }) {
    return Project(
      id: id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      domain: domain ?? this.domain,
      link: link ?? this.link,
      featuredImage: featuredImage ?? this.featuredImage,
      description: description ?? this.description,
      caseStudySlug: caseStudySlug ?? this.caseStudySlug,
      stacks: stacks ?? this.stacks,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      isCurrent: isCurrent ?? this.isCurrent,
    );
  }
}
