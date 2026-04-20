class BusinessIdeaRequestModel {
  final String budget;
  final String city;
  final String niche;
  final String? businessIdea;

  const BusinessIdeaRequestModel({
    required this.budget,
    required this.city,
    required this.niche,
    this.businessIdea,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'city': city,
      'niche': niche,
      if (businessIdea != null) 'businessIdea': businessIdea,
    };
  }
}

class BusinessIdeaModel {
  final String title;
  final String description;
  final List<String> steps;
  final String estimatedProfit;
  final List<String> pros;
  final List<String> cons;
  final List<String> actionPlan30Days; // Plan d'action stratégique
  final String aiConclusion; // Nouveau: Conclusion motivante de l'IA

  const BusinessIdeaModel({
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedProfit,
    required this.pros,
    required this.cons,
    required this.actionPlan30Days,
    required this.aiConclusion,
  });

  factory BusinessIdeaModel.fromJson(Map<String, dynamic> json) {
    return BusinessIdeaModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      estimatedProfit: json['estimatedProfit'] ?? '',
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
      actionPlan30Days: List<String>.from(json['actionPlan30Days'] ?? []),
      aiConclusion: json['aiConclusion'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'steps': steps,
      'estimatedProfit': estimatedProfit,
      'pros': pros,
      'cons': cons,
      'actionPlan30Days': actionPlan30Days,
      'aiConclusion': aiConclusion,
    };
  }
}
