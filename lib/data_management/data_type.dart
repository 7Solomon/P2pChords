class SongData {
  final String name;
  final int age;

  SongData({required this.name, required this.age});

  factory SongData.fromJson(Map<String, dynamic> json) {
    return SongData(
      name: json['name'],
      age: json['age'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
    };
  }
}