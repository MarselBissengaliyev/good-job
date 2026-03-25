// lib/models/master_review.dart

class MasterReview {
  final int id;
  final int rating;
  final String? comment;
  final DateTime? createdAt;
  final MasterReviewClient client;

  MasterReview({
    required this.id,
    required this.rating,
    this.comment,
    this.createdAt,
    required this.client,
  });

  factory MasterReview.fromJson(Map<String, dynamic> json) {
    return MasterReview(
      id: json['id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      client: MasterReviewClient.fromJson(json['client'] ?? {}),
    );
  }

  static List<MasterReview> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => MasterReview.fromJson(json)).toList();
  }
}

class MasterReviewClient {
  final String id;
  final String firstname;
  final String lastname;

  MasterReviewClient({
    required this.id,
    required this.firstname,
    required this.lastname,
  });

  factory MasterReviewClient.fromJson(Map<String, dynamic> json) {
    return MasterReviewClient(
      id: json['id']?.toString() ?? '',
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
    );
  }

  String get fullName => '$firstname $lastname'.trim();
}