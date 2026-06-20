class Post {
  final String id;
  final DateTime createdAt;
  final String mobileUrl;
  final String thumbnailUrl;
  final String rawUrl;
  final int likeCount;
  final bool isLiked;

  Post({
    required this.id,
    required this.createdAt,
    required this.likeCount,
    required this.mobileUrl,
    required this.rawUrl,
    required this.thumbnailUrl,
    required this.isLiked,
  });


  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? "",
      createdAt: DateTime.parse(json['created_at']),
      likeCount: json['like_count'] ?? 0,
      mobileUrl: json['media_mobile_url'] ?? "",
      rawUrl: json['media_raw_url'] ?? "",
      thumbnailUrl: json['media_thumb_url'] ?? "",
      isLiked: false,
    );
  }

  Post copyWith({int? likeCount, bool? isLiked}) => Post(
        id: id,
        createdAt: createdAt,
        thumbnailUrl: thumbnailUrl,
        mobileUrl: mobileUrl,
        rawUrl: rawUrl,
        likeCount: likeCount ?? this.likeCount,
        isLiked: isLiked ?? this.isLiked,
      );
}