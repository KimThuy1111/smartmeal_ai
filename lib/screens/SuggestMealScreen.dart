import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartmeal_ai/utils/notifier.dart';
import '../component/BackgroundGradient.dart';
import '../component/Footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FoodDetailScreen.dart';

class SuggestMealScreen extends StatefulWidget {
  const SuggestMealScreen({super.key});

  @override
  State<SuggestMealScreen> createState() => _SuggestMealScreenState();
}

class _SuggestMealScreenState extends State<SuggestMealScreen> {

  Map<String, List<Map<String,dynamic>>>? menu;
  Map<String,dynamic>? nutrition;

  bool isLoading = false;
  bool? liked;

  double breakfastCalories = 0;
  double lunchCalories = 0;
  double dinnerCalories = 0;

  String today = DateTime.now().toString().substring(0,10);

  @override
  void initState() {
    super.initState();
    loadMenuFromFirestore();
  }

  /// ==============================
  /// LOAD MENU TỪ FIRESTORE (CACHE)
  /// ==============================

  Future<void> loadMenuFromFirestore() async {

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection("suggested_menus")
        .where("userId", isEqualTo: user.uid)
        .where("date", isEqualTo: today)
        .limit(1)
        .get();

    if(snapshot.docs.isEmpty){
      await fetchMenu(); // chưa có menu → gọi API
      return;
    }

    final data = snapshot.docs.first.data();

    liked = data["liked"];

    Map<String,dynamic> storedMenu = data["menu"];

    Map<String,List<Map<String,dynamic>>> loadedMenu = {
      "Breakfast":[],
      "Lunch":[],
      "Dinner":[]
    };

    for(String meal in storedMenu.keys){

      List ids = storedMenu[meal];

      for(String id in ids){

        final foodDoc = await FirebaseFirestore.instance
            .collection("food")
            .doc(id)
            .get();

        if(foodDoc.exists){

          final food = foodDoc.data()!;
          food["id"] = foodDoc.id;

          loadedMenu[meal]!.add(food);

        }

      }

    }

    setState(() {
      menu = loadedMenu;
      isLoading = false;
    });

  }

  /// ==============================
  /// LOAD CALORIES ĐÃ ĂN
  /// ==============================

  Future<void> loadTodayCalories() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("food_diary")
        .where("userId", isEqualTo: user.uid)
        .where("date", isEqualTo: today)
        .get();

    breakfastCalories = 0;
    lunchCalories = 0;
    dinnerCalories = 0;

    for (var doc in snapshot.docs) {

      final foodId = doc["foodId"];
      final meal = doc["meal"];

      final foodDoc = await FirebaseFirestore.instance
          .collection("food")
          .doc(foodId)
          .get();

      final data = foodDoc.data();
      if (data == null) continue;

      final cal = (data["calories"] ?? 0).toDouble();

      if (meal == "breakfast") breakfastCalories += cal;
      if (meal == "lunch") lunchCalories += cal;
      if (meal == "dinner") dinnerCalories += cal;
    }
  }

  /// ==============================
  /// GỌI FAST API
  /// ==============================

  Future<void> fetchMenu() async {

    setState(() => isLoading = true);

    try {

      await loadTodayCalories();

      final user = FirebaseAuth.instance.currentUser;
      if(user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if(userData == null) return;

      final response = await http.post(
        Uri.parse("https://smartmeal-ai-wp3g.onrender.com/recommend"),
        headers: {"Content-Type":"application/json"},
        body: jsonEncode({
          "age": userData["age"],
          "gender": userData["gender"],
          "height": userData["height"],
          "weight": userData["weight"],
          "activity": userData["activity"],
          "disease": userData["diseases"]?.isNotEmpty == true
              ? userData["diseases"][0]
              : "None",
          "breakfast_cal": breakfastCalories,
          "lunch_cal": lunchCalories,
          "dinner_cal": dinnerCalories
        }),
      );

      if(response.statusCode != 200){
        print("API ERROR");
        return;
      }

      final data = jsonDecode(response.body);

      nutrition = data["nutrition"];

      final aiMenu = data["menu"];

      Map<String,List<Map<String,dynamic>>> fullMenu = {};

      for(String meal in ["Breakfast","Lunch","Dinner"]){

        List items = aiMenu[meal] ?? [];
        List<Map<String,dynamic>> foods = [];

        for(var item in items){

          final snapshot = await FirebaseFirestore.instance
              .collection("food")
              .where("stt", isEqualTo: item["stt"])
              .limit(1)
              .get();

          if(snapshot.docs.isNotEmpty){

            final doc = snapshot.docs.first;

            final foodData = doc.data();
            foodData["id"] = doc.id;

            foods.add(foodData);
          }
        }

        fullMenu[meal] = foods;
      }

      await saveSuggestedMenu(fullMenu);

      setState(() {
        menu = fullMenu;
        liked = null;
      });

    } catch(e){
      print(e);
    }

    setState(() => isLoading = false);

  }

  /// ==============================
  /// LƯU MENU FIRESTORE
  /// ==============================

  Future<void> saveSuggestedMenu(
      Map<String,List<Map<String,dynamic>>> menu) async {

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    Map<String,List<String>> foodIds = {};

    menu.forEach((meal,foods){

      foodIds[meal] = foods
          .map((f) => f["id"].toString())
          .toList();

    });

    await FirebaseFirestore.instance
        .collection("suggested_menus")
        .add({
      "userId": user.uid,
      "date": today,
      "menu": foodIds,
      "liked": null,
      "createdAt": FieldValue.serverTimestamp()
    });

  }

  /// ==============================
  /// LIKE / DISLIKE
  /// ==============================

  Future<void> rateMenu(bool like) async {

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection("suggested_menus")
        .where("userId", isEqualTo: user.uid)
        .where("date", isEqualTo: today)
        .limit(1)
        .get();

    if(snapshot.docs.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("suggested_menus")
        .doc(snapshot.docs.first.id)
        .update({"liked": like});

    setState(() {
      liked = like;
    });
    Notifier.showNotify(context, like ? "Cảm ơn bạn đã thích thực đơn hôm nay" : "Cập nhật món ăn thành công");

  }

  /// ==============================
  /// UI
  /// ==============================

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      bottomNavigationBar: const Footer(currentIndex: 2),

      body: BackgroundGradient(
        child: SafeArea(
          child: Column(
            children: [

              Row(
                children: [

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Gợi ý thực đơn",
                        style: TextStyle(
                            fontSize:22,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),

                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: fetchMenu,
                  )

                ],
              ),

              Expanded(

                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : menu == null
                    ? const Center(child: Text("Không có dữ liệu"))
                    : SingleChildScrollView(

                  padding: const EdgeInsets.all(16),

                  child: Column(
                    children: [

                      Text(
                        "Dựa trên mục tiêu ${nutrition?["Calories"] ?? 0} Calo/ngày",
                        style: const TextStyle(color: Colors.grey),
                      ),

                      const SizedBox(height:20),

                      buildMealSection("Bữa Sáng", menu?["Breakfast"] ?? []),
                      buildMealSection("Bữa Trưa", menu?["Lunch"] ?? []),
                      buildMealSection("Bữa Tối", menu?["Dinner"] ?? []),
                      const SizedBox(height:30),

                      if(liked == null)
                        Column(
                          children: [

                            const Text(
                              "Bạn có thích danh sách món ăn này không?",
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height:10),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                ElevatedButton.icon(
                                  icon: const Icon(Icons.thumb_up),
                                  label: const Text("Thích"),
                                  onPressed: () => rateMenu(true),
                                ),

                                const SizedBox(width:20),

                                ElevatedButton.icon(
                                  icon: const Icon(Icons.thumb_down),
                                  label: const Text("Không thích"),
                                  onPressed: () => rateMenu(false),
                                ),

                              ],
                            )

                          ],
                        )

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ==============================
  /// ITEM FOOD
  /// ==============================

  Widget buildMealSection(String title, List foods){

    if(foods.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height:20),

        Text(
          title,
          style: const TextStyle(
              fontSize:18,
              fontWeight: FontWeight.bold
          ),
        ),

        const SizedBox(height:10),

        ...foods.map((food){

          final name = food["name"];
          final image = food["image"];
          final calories = food["calories"];
          final id = food["id"];

          return Card(
            child: ListTile(

              onTap: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => FoodDetailScreen(foodId: id)
                  ),
                );
              },

              leading: Image.network(
                image,
                width:60,
                height:60,
                fit: BoxFit.cover,
              ),

              title: Text(name),
              subtitle: Text("$calories cal"),

            ),
          );

        }).toList()

      ],
    );

  }

}