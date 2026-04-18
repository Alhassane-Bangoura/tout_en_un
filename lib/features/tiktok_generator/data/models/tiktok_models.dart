class TiktokRequestModel {
  final String product;
  final String targetAudience;
  final String style;

  const TiktokRequestModel({
    required this.product,
    required this.targetAudience,
    required this.style,
  });
}

class TiktokScriptModel {
  final String hook;
  final List<ScriptPart> body;
  final String cta;
  final List<String> alternativeHooks;
  final List<String> instructions;

  const TiktokScriptModel({
    required this.hook,
    required this.body,
    required this.cta,
    required this.alternativeHooks,
    required this.instructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'hook': hook,
      'body': body.map((e) => e.toJson()).toList(),
      'cta': cta,
      'alternativeHooks': alternativeHooks,
      'instructions': instructions,
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
