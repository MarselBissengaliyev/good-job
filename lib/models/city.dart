class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }

  static List<City> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((cityJson) => City.fromJson(cityJson))
        .toList();
  }

  // Удаляем статический список sampleCities
  // static List<City> get sampleCities => [...]
}