class FoodDiary {
  final String foodId;
  final String meal;
  final String date;
  final double calories;
  final String? image;
  final String name;

  FoodDiary({
    required this.foodId,
    required this.meal,
    required this.date,
    required this.calories,
    required this.name,
    this.image,
  });
}