import 'dart:io';

class OrderEditForm {
  String title;
  String description;
  double price;
  int? categoryId;
  int? cityId;
  String addressStreet;
  String addressHouse;
  String addressApartment;
  String telephone;
  List<String> images;
  List<File>? newImageFiles;
  List<String> imagesToDelete;

  OrderEditForm({
    required this.title,
    required this.description,
    required this.price,
    this.categoryId,
    this.cityId,
    required this.addressStreet,
    required this.addressHouse,
    required this.addressApartment,
    required this.telephone,
    required this.images,
    this.newImageFiles,
    List<String>? imagesToDelete,
  }) : imagesToDelete = imagesToDelete ?? [];

  factory OrderEditForm.fromOrder(Map<String, dynamic> order) {
    return OrderEditForm(
      title: order['title'] ?? '',
      description: order['description'] ?? '',
      price: (order['price'] as num?)?.toDouble() ?? 0,
      categoryId: order['category']?['id'] is String
          ? int.tryParse(order['category']['id'].toString())
          : order['category']?['id'],
      cityId: order['city']?['id'],
      addressStreet: order['address_street'] ?? '',
      addressHouse: order['address_house'] ?? '',
      addressApartment: order['address_apartment'] ?? '',
      telephone: order['telephone'] ?? '',
      images: List<String>.from(order['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      if (categoryId != null) 'category_id': categoryId,
      if (cityId != null) 'city_id': cityId,
      'address_street': addressStreet,
      'address_house': addressHouse,
      'address_apartment': addressApartment,
      'telephone': telephone,
      'images': images,
    };
  }
}