/// Represents a model in the API
class Model {
  final String id;
  final String object;
  final String ownedBy;

  Model({
    required this.id,
    required this.object,
    required this.ownedBy,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] as String,
      object: json['object'] as String,
      ownedBy: json['owned_by'] as String,
    );
  }
}

/// Represents the response from the models endpoint
class ModelsResponse {
  final String object;
  final List<Model> data;

  ModelsResponse({
    required this.object,
    required this.data,
  });

  factory ModelsResponse.fromJson(Map<String, dynamic> json) {
    return ModelsResponse(
      object: json['object'] as String,
      data: (json['data'] as List)
          .map((m) => Model.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}
