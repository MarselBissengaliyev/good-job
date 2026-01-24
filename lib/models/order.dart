class Order {
  final int id;
  final String title;
  final String price;
  final DateTime? createdAt;
  final Map<String, dynamic>? category;
  final Map<String, dynamic>? city;
  final Map<String, dynamic>? client;
  final List<String> images;
  final String telephone;

  Order({
    required this.id,
    required this.title,
    required this.price,
    this.createdAt,
    this.category,
    this.city,
    this.client,
    required this.images,
    required this.telephone,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      price: json['price']?.toString() ?? '0',
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      category: json['category'] is Map ? Map<String, dynamic>.from(json['category']) : null,
      city: json['city'] is Map ? Map<String, dynamic>.from(json['city']) : null,
      client: json['client'] is Map ? Map<String, dynamic>.from(json['client']) : null,
      images: List<String>.from(json['images'] ?? []),
      telephone: json['telephone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'created_at': createdAt?.toIso8601String(),
      'category': category,
      'city': city,
      'client': client,
      'images': images,
      'telephone': telephone,
    };
  }
}