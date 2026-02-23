class Food {
  String id;
  String name;
  String? englishName;
  String? image;
  double calories;
  double protein;
  double fat;
  double carbs;

  double calcium;
  double iron;
  double zinc;
  double sodium;
  double magnesium;
  double vitaminA;
  double potassium;
  double mufaPufa;

  Food({
    required this.id,
    required this.name,
    this.englishName,
    this.image,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.calcium,
    required this.iron,
    required this.zinc,
    required this.sodium,
    required this.magnesium,
    required this.vitaminA,
    required this.potassium,
    required this.mufaPufa,
  });

  factory Food.fromMap(Map<String, dynamic> map, String docId) {
    return Food(
      id: docId,
      name: map["name"] ?? "",
      englishName: map['englishName'],
      image: map["image"],
      calories: (map["calories"] ?? 0).toDouble(),
      protein: (map["protein"] ?? 0).toDouble(),
      fat: (map["fat"] ?? 0).toDouble(),
      carbs: (map["carbs"] ?? 0).toDouble(),
      calcium: (map["calcium"] ?? 0).toDouble(),
      iron: (map["iron"] ?? 0).toDouble(),
      zinc: (map["zinc"] ?? 0).toDouble(),
      sodium: (map["sodium"] ?? 0).toDouble(),
      magnesium: (map["magnesium"] ?? 0).toDouble(),
      vitaminA: (map["vitaminA"] ?? 0).toDouble(),
      potassium: (map["potassium"] ?? 0).toDouble(),
      mufaPufa: (map["mufaPufa"] ?? 0).toDouble(),
    );
  }
}