class FoodCategory {
  String id;
  String name;

  FoodCategory({
    required this.id,
    required this.name,
  });

  factory FoodCategory.fromMap(Map<String, dynamic> map, String docId) {
    return FoodCategory(
      id: docId,
      name: map["name"] ?? "",
    );
  }
}
