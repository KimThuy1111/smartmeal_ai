import 'package:flutter/material.dart';

class UserItemCard extends StatelessWidget {

  final String avatar;
  final String name;
  final String email;
  final VoidCallback onTap;

  const UserItemCard({
    super.key,
    required this.avatar,
    required this.name,
    required this.email,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(

          color: Colors.white,

          borderRadius: BorderRadius.circular(20),

          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
            )
          ],
        ),

        child: Row(

          children: [

            CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(avatar),
            ),

            const SizedBox(width: 14),

            Expanded(

              child: Column(

                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    email,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}