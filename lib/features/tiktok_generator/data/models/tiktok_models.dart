class TiktokRequestModel {
  final String product;
  final String targetAudience;
  final String style;
  final String? details;

  const TiktokRequestModel({
    required this.product,
    required this.targetAudience,
    required this.style,
    this.details,
  });
}

class TiktokScriptModel {
  final String hook;
  final List<ScriptPart> body;
  final String cta;
  final List<String> alternativeHooks;
  final List<String> instructions;
  final int viralScore;
  final String viralReason;

  const TiktokScriptModel({
    required this.hook,
    required this.body,
    required this.cta,
    required this.alternativeHooks,
    required this.instructions,
    this.viralScore = 80, // Default for backward compatibility
    this.viralReason = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'hook': hook,
      'body': body.map((e) => e.toJson()).toList(),
      'cta': cta,
      'alternativeHooks': alternativeHooks,
      'instructions': instructions,
      'viralScore': viralScore,
      'viralReason': viralReason,
    };
  }
}

class ScriptPart {
  final String timestamp;
  final String content;

  const ScriptPart({
    required this.timestamp,
    required this.content,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'content': content,
    };
  }
}
