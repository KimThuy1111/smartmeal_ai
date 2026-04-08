import 'package:flutter/material.dart';

class FoodItemCard extends StatelessWidget {
  final String id;
  final String name;
  final String? image;
  final double calories;
  final Widget? trailing;
  //6. Người dùng chọn vào món ăn cần xem thông tin
  final VoidCallback? onTap;

  const FoodItemCard({
    super.key,
    required this.id,
    required this.name,
    required this.calories,
    this.image,
    this.trailing, // FIX
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: (image != null && image!.isNotEmpty) ? Image.network(
              image!, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset("assets/images/default_food.png", fit: BoxFit.cover,),
            ) : Image.asset("assets/images/default_food.png", fit: BoxFit.cover,),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold),),
        subtitle: Text("${calories.toStringAsFixed(0)} cal"),
        trailing: trailing,
      ),
    );
  }
  Widget buildImage() {
    if (image == null || image!.trim().isEmpty) {
      return Image.asset(
        "assets/images/default_food.png",
        fit: BoxFit.cover,
      );
    }
    return Image.network(image!, fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset("assets/images/default_food.png", fit: BoxFit.cover,);
      },
    );
  }
}