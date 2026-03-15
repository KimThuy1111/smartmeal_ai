import 'package:flutter/material.dart';

class FoodItemCard extends StatelessWidget {

  final String id;
  final String name;
  final String? image;
  final double calories;

  /// FIX: thêm trailing để custom icon (add hoặc menu 3 chấm)
  final Widget? trailing;

  /// khi bấm vào item
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

            child: (image != null && image!.isNotEmpty)
                ? Image.network(
              image!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset(
                    "assets/images/default_food.png",
                    fit: BoxFit.cover,
                  ),
            )
                : Image.asset(
              "assets/images/default_food.png",
              fit: BoxFit.cover,
            ),
          ),
        ),

        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        subtitle: Text("${calories.toStringAsFixed(0)} cal"),

        /// FIX: trailing có thể là + hoặc ⋮
        trailing: trailing,
      ),
    );
  }
}