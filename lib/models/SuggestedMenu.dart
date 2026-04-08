class SuggestedMenu {

  final String userId;
  final String date;
  final Map<String, List<String>> menu;
  final bool? liked;

  SuggestedMenu({
    required this.userId,
    required this.date,
    required this.menu,
    this.liked,
  });

  Map<String, dynamic> toMap() {
    return {
      "userId": userId,
      "date": date,
      "menu": menu,
      "liked": liked,
    };
  }

  factory SuggestedMenu.fromMap(Map<String, dynamic> data) {

    Map<String,List<String>> parsedMenu = {};

    data["menu"].forEach((key,value){
      parsedMenu[key] = List<String>.from(value);
    });

    return SuggestedMenu(
      userId: data["userId"],
      date: data["date"],
      menu: parsedMenu,
      liked: data["liked"],
    );
  }
}