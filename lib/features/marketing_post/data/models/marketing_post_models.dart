class MarketingPostRequestModel {
  final String product;
  final String platform;
  final String tone;

  const MarketingPostRequestModel({
    required this.product,
    required this.platform,
    required this.tone,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'platform': platform,
      'tone': tone,
    };
  }
}

class MarketingPostModel {
  final String headline;
  final String content;
  final String cta;
  final List<String> hashtags;

  const MarketingPostModel({
    required this.headline,
    required this.content,
    required this.cta,
    required this.hashtags,
  });

  factory MarketingPostModel.fromJson(Map<String, dynamic> json) {
    return MarketingPostModel(
      headline: json['headline'] ?? '',
      content: json['content'] ?? '',
      cta: json['cta'] ?? '',
      hashtags: List<String>.from(json['hashtags'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'headline': headline,
      'content': content,
      'cta': cta,
      'hashtags': hashtags,
    };
  }
}
