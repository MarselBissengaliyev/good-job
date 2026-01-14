class City {
  final int id;
  final String name;

  City({required this.id, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(id: json['id'], name: json['name']);
  }

  static List<City> get sampleCities => [
    City(id: 1, name: 'Уральск'),
    City(id: 2, name: 'Алматы'),
    City(id: 3, name: 'Астана'),
  ];
}
