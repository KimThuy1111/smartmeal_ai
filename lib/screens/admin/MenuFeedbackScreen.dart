import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/SuggestedMenu.dart';
import '../../models/User.dart';
import '../../models/Food.dart';
import 'MenuDetailScreen.dart';

class MenuFeedbackScreen extends StatefulWidget {
  const MenuFeedbackScreen({super.key});

  @override
  State<MenuFeedbackScreen> createState() => _MenuFeedbackScreenState();
}

class _MenuFeedbackScreenState extends State<MenuFeedbackScreen> {

  bool loading = true;

  int likeCount = 0;
  int dislikeCount = 0;
  int notRatedCount = 0;

  String filter = "all";

  List<Map<String,dynamic>> menus = [];

  @override
  void initState() {
    super.initState();
    loadMenus();
  }

  Future<void> loadMenus() async {

    likeCount = 0;
    dislikeCount = 0;
    notRatedCount = 0;

    final snap = await FirebaseFirestore.instance
        .collection("suggested_menus")
        .get();

    List<Map<String,dynamic>> result = [];

    for (var doc in snap.docs) {

      final suggested = SuggestedMenu.fromMap(doc.data());

      if (suggested.liked == true) likeCount++;
      else if (suggested.liked == false) dislikeCount++;
      else notRatedCount++;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(suggested.userId)
          .get();

      if(!userDoc.exists) continue;

      final user = User.fromMap(userDoc.data()!, userDoc.id);

      List<String> allFoodIds = [];

      suggested.menu.forEach((key,value){
        allFoodIds.addAll(value);
      });

      List<String> names = [];

      for (var id in allFoodIds){

        final foodDoc = await FirebaseFirestore.instance
            .collection("food")
            .doc(id)
            .get();

        if(foodDoc.exists){
          final food = Food.fromMap(
              foodDoc.data() as Map<String,dynamic>, foodDoc.id);
          names.add(food.name);
        }

      }

      result.add({
        "user": user,
        "foods": names,
        "liked": suggested.liked,
        "menu": suggested.menu
      });

    }

    setState(() {
      menus = result;
      loading = false;
    });
  }

  double get likeRate {

    int total = likeCount + dislikeCount;

    if(total == 0) return 0;

    return likeCount / total * 100;
  }

  @override
  Widget build(BuildContext context) {

    final filteredMenus = menus.where((m){

      if(filter == "like") return m["liked"] == true;
      if(filter == "dislike") return m["liked"] == false;
      if(filter == "none") return m["liked"] == null;

      return true;

    }).toList();

    return Scaffold(

      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: Column(

            children: [

              const SizedBox(height:10),

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Đánh giá thực đơn AI",
                        style: TextStyle(
                            fontSize:22,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width:40)

                ],
              ),

              const SizedBox(height:10),

              Text(
                "Tỉ lệ phù hợp ${likeRate.toStringAsFixed(1)}%",
                style: const TextStyle(
                    fontSize:18,
                    fontWeight: FontWeight.bold
                ),
              ),

              const SizedBox(height:10),

              buildPieChart(),

              const SizedBox(height:10),

              buildLegend(),

              const SizedBox(height:20),

              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMenus.length,
                  itemBuilder: (context,index){

                    final item = filteredMenus[index];
                    final user = item["user"] as User;
                    final foods = item["foods"] as List<String>;

                    String foodText = foods.join(", ");

                    if(foodText.length > 50){
                      foodText = foodText.substring(0,50) + "...";
                    }

                    return GestureDetector(

                      onTap: (){

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MenuDetailScreen(
                              user: user,
                              menu: item["menu"],
                            ),
                          ),
                        );

                      },

                      child: Container(

                        margin: const EdgeInsets.only(bottom:14),
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6)
                          ],
                        ),

                        child: Row(

                          children: [

                            CircleAvatar(
                              radius:28,
                              backgroundImage:
                              NetworkImage(user.avatar),
                            ),

                            const SizedBox(width:12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize:16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height:4),

                                  Text(
                                    foodText,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )

                                ],
                              ),
                            )

                          ],
                        ),
                      ),
                    );
                  },
                ),
              )

            ],
          ),
        ),
      ),
    );
  }

  Widget buildPieChart(){

    int total = likeCount + dislikeCount + notRatedCount;

    double likePercent = total == 0 ? 0 : likeCount / total * 100;
    double dislikePercent = total == 0 ? 0 : dislikeCount / total * 100;
    double nonePercent = total == 0 ? 0 : notRatedCount / total * 100;

    return SizedBox(
      height:180,
      child: PieChart(

        PieChartData(

          sectionsSpace: 2,

          sections: [

            PieChartSectionData(
              value: likeCount.toDouble(),
              color: Colors.green,
              radius: 90,
              title: "${likePercent.toStringAsFixed(0)}%",
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),

            PieChartSectionData(
              value: dislikeCount.toDouble(),
              color: Colors.red,
              radius: 90,
              title: "${dislikePercent.toStringAsFixed(0)}%",
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),

            PieChartSectionData(
              value: notRatedCount.toDouble(),
              color: Colors.orange,
              radius: 90,
              title: "${nonePercent.toStringAsFixed(0)}%",
              titleStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget buildLegend(){

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        legendPill(Colors.green,"Thích","like"),
        const SizedBox(width:10),
        legendPill(Colors.red,"Không Thích","dislike"),
        const SizedBox(width:10),
        legendPill(Colors.orange,"Chưa đánh giá","none"),

      ],
    );
  }

  Widget legendPill(Color color,String text,String type){

    bool active = filter == type;

    return GestureDetector(

      onTap: (){
        setState(() {
          filter = type;
        });
      },

      child: Container(

        padding: const EdgeInsets.fromLTRB(8, 7, 15, 7),

        decoration: BoxDecoration(

          color: active ? Colors.grey[200] : Colors.white,

          borderRadius: BorderRadius.circular(40),

          border: Border.all(
            color: Colors.grey.shade400,
          ),

        ),

        child: Row(

          children: [

            Container(
              width:14,
              height:14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width:8),

            Text(
              text,
              style: const TextStyle(
                fontSize:13,
              ),
            ),

          ],
        ),
      ),
    );
  }
}