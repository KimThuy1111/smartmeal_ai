import 'package:flutter/material.dart';
import '../../models/User.dart';
import '../FoodDetailScreen.dart';
import '../../component/FoodItemCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuDetailScreen extends StatefulWidget {

  final User user;
  final Map<String,List<String>> menu;

  const MenuDetailScreen({
    super.key,
    required this.user,
    required this.menu
  });

  @override
  State<MenuDetailScreen> createState() => _MenuDetailScreenState();
}

class _MenuDetailScreenState extends State<MenuDetailScreen> {

  Map<String,List<Map<String,dynamic>>> foods = {};

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  Future<void> loadFoods() async {

    Map<String,List<Map<String,dynamic>>> result = {};

    for(String meal in widget.menu.keys){

      List<Map<String,dynamic>> list = [];

      for(String id in widget.menu[meal]!){

        final doc = await FirebaseFirestore.instance
            .collection("food")
            .doc(id)
            .get();

        if(doc.exists){
          final data = doc.data()!;
          data["id"] = doc.id;
          list.add(data);
        }

      }

      result[meal] = list;
    }

    setState(() {
      foods = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.user.name),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          buildMeal("Bữa sáng", foods["Breakfast"] ?? []),
          buildMeal("Bữa trưa", foods["Lunch"] ?? []),
          buildMeal("Bữa tối", foods["Dinner"] ?? []),

        ],
      ),
    );
  }

  Widget buildMeal(String title,List foods){

    if(foods.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(
              fontSize:18,
              fontWeight: FontWeight.bold),
        ),

        const SizedBox(height:10),

        ...foods.map((food){

          return FoodItemCard(

            id: food["id"],
            name: food["name"],
            image: food["image"],
            calories: food["calories"].toDouble(),

            onTap: (){
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FoodDetailScreen(foodId: food["id"]),
                ),
              );
            },

            trailing: const SizedBox(),

          );

        })

      ],
    );
  }
}