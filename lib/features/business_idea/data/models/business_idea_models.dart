class BusinessIdeaRequestModel {
  final String budget;
  final String city;
  final String niche;

  const BusinessIdeaRequestModel({
    required this.budget,
    required this.city,
    required this.niche,
  });

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'city': city,
      'niche': niche,
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

  const BusinessIdeaModel({
    required this.title,
    required this.description,
    required this.steps,
    required this.estimatedProfit,
    required this.pros,
    required this.cons,
  });

  factory BusinessIdeaModel.fromJson(Map<String, dynamic> json) {
    return BusinessIdeaModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      estimatedProfit: json['estimatedProfit'] ?? '',
      pros: List<String>.from(json['pros'] ?? []),
      cons: List<String>.from(json['cons'] ?? []),
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
    };
  }
}
