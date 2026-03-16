import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smartmeal_ai/utils/notifier.dart';
import '../component/BackgroundGradient.dart';
import '../component/FoodItemCard.dart';
import '../component/Footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/Food.dart';
import '../models/SuggestedMenu.dart';
import 'FoodDetailScreen.dart';

class SuggestMealScreen extends StatefulWidget {

  final String? addedFoodId;

  const SuggestMealScreen({super.key, this.addedFoodId});

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
    loadMenuFromFirestore().then((_) {

      /// nếu có món vừa thêm
      if(widget.addedFoodId != null){

        bool exists = isFoodInMenu(widget.addedFoodId!);

        /// nếu không có trong menu → gọi lại API
        if(!exists){
          fetchMenu();
        }

      }

    });
  }

  //Load menu

  Future<void> loadMenuFromFirestore() async {

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    setState(() => isLoading = true);

    /// FIX: đọc doc theo user + date
    final doc = await FirebaseFirestore.instance
        .collection("suggested_menus")
        .doc("${user.uid}_$today")
        .get();

    /// FIX: nếu chưa có menu → gọi API
    if(!doc.exists){
      await fetchMenu();
      return;
    }

    /// parse model
    final suggestedMenu =
    SuggestedMenu.fromMap(doc.data()!);

    liked = suggestedMenu.liked;

    /// load food chi tiết
    Map<String,List<Map<String,dynamic>>> loadedMenu = {
      "Breakfast": [],
      "Lunch": [],
      "Dinner": []
    };

    for(String meal in suggestedMenu.menu.keys){

      List<String> ids = suggestedMenu.menu[meal]!;

      /// OPTIMIZE: load song song
      List<Future<DocumentSnapshot>> futures = ids.map((id){
        return FirebaseFirestore.instance
            .collection("food")
            .doc(id)
            .get();
      }).toList();

      final docs = await Future.wait(futures);

      for(var d in docs){

        if(!d.exists) continue;

        final data = d.data() as Map<String,dynamic>;
        data["id"] = d.id;

        loadedMenu[meal]!.add(data);
      }

    }

    setState(() {
      menu = loadedMenu;
      isLoading = false;
    });

  }
  bool isFoodInMenu(String foodId){

    if(menu == null) return false;

    for(var meal in menu!.values){

      for(var food in meal){

        if(food["id"] == foodId){
          return true;
        }

      }

    }

    return false;
  }

  /// ====================================================
  /// LOAD CALORIES ĐÃ ĂN TRONG NGÀY
  /// ====================================================

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

    /// OPTIMIZE: load food song song

    List<Future<DocumentSnapshot>> futures = [];

    for (var doc in snapshot.docs) {

      futures.add(
          FirebaseFirestore.instance
              .collection("food")
              .doc(doc["foodId"])
              .get()
      );

    }

    final foodDocs = await Future.wait(futures);

    for(int i=0;i<foodDocs.length;i++){

      final meal = snapshot.docs[i]["meal"];
      final data = foodDocs[i].data() as Map<String,dynamic>?;

      if(data == null) continue;

      final cal = (data["calories"] ?? 0).toDouble();

      if (meal == "breakfast") breakfastCalories += cal;
      if (meal == "lunch") lunchCalories += cal;
      if (meal == "dinner") dinnerCalories += cal;

    }

  }

  /// ====================================================
  /// GỌI FAST API
  /// ====================================================

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

      /// CALL FAST API

      final response = await http.post(
        // Uri.parse("https://smartmeal-ai-wp3g.onrender.com/recommend"),
        Uri.parse("http://10.0.2.2:8000/recommend"),
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

          /// tìm food theo stt
          final snapshot = await FirebaseFirestore.instance
              .collection("food")
              .where("stt", isEqualTo: item["stt"])
              .limit(1)
              .get();

          if(snapshot.docs.isEmpty) continue;

          final doc = snapshot.docs.first;
          final foodData = doc.data();

          foodData["id"] = doc.id;

          foods.add(foodData);
        }

        fullMenu[meal] = foods;
      }

      /// lưu firestore
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

  /// ====================================================
  /// LƯU MENU FIRESTORE
  /// ====================================================

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

    final suggestedMenu = SuggestedMenu(
      userId: user.uid,
      date: today,
      menu: foodIds,
      liked: null,
    );

    await FirebaseFirestore.instance
        .collection("suggested_menus")
        .doc("${user.uid}_$today")
        .set(suggestedMenu.toMap());

  }
  // Kiểm tra xem menu có món k
  bool hasMenuFood() {

    if(menu == null) return false;

    for(var meal in menu!.values){
      if(meal.isNotEmpty){
        return true;
      }
    }

    return false;
  }
  Future<void> rateMenu(bool like) async {

    final user = FirebaseAuth.instance.currentUser;
    if(user == null) return;

    /// FIX: update trực tiếp docId (không cần query)

    await FirebaseFirestore.instance
        .collection("suggested_menus")
        .doc("${user.uid}_$today")
        .update({"liked": like});

    setState(() {
      liked = like;
    });

    Notifier.showNotify(
        context,
        like
            ? "Cảm ơn bạn đã thích thực đơn hôm nay"
            : "Cập nhật món ăn thành công"
    );

  }
  // Hàm thêm món ăn vào nhật kí
  Future<void> addFoodToDiary(String foodId, String meal) async {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance.collection("food_diary").add({

      "userId": user.uid,

      /// FIX: lưu id món ăn
      "foodId": foodId,

      "meal": meal,

      "date": today,

      "createdAt": FieldValue.serverTimestamp(),

    });

    Notifier.showNotify(context, "Thêm vào nhật ký thành công");
  }

  //UI

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
                      const SizedBox(height:5),
                      Text(
                        "Các món ăn chỉ mang tính chất tham khảo!!!!",
                        style: const TextStyle(color: Colors.red),
                      ),

                      const SizedBox(height:20),

                      buildMealSection("Bữa Sáng", menu?["Breakfast"] ?? [], "breakfast"),
                      buildMealSection("Bữa Trưa", menu?["Lunch"] ?? [], "lunch"),
                      buildMealSection("Bữa Tối", menu?["Dinner"] ?? [], "dinner"),
                      /// FIX: nếu không còn món gợi ý
                      if(!hasMenuFood())
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Column(
                            children: [

                              Icon(
                                Icons.emoji_food_beverage,
                                size: 60,
                                color: Colors.green,
                              ),

                              SizedBox(height: 10),

                              Text(
                                "Hôm nay bạn đã ăn đủ calo 🎉",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),

                              SizedBox(height: 6),

                              Text(
                                "Không cần gợi ý thêm món ăn",
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),

                            ],
                          ),
                        ),

                      const SizedBox(height:30),

                      if(liked == null && hasMenuFood())
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

  Widget buildMealSection(String title, List foods, String meal){

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

          return FoodItemCard(

            id: id,
            name: name,
            image: image,
            calories: calories.toDouble(),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodDetailScreen(foodId: id),
                ),
              );
            },

            /// FIX: icon thêm món
            trailing: IconButton(
              icon: const Icon(
                Icons.add_circle,
                color: Colors.green,
              ),
              onPressed: () {
                addFoodToDiary(id, meal);
              },
            ),
          );

        }).toList()

      ],
    );

  }

}