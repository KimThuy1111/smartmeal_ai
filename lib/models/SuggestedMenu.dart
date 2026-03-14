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
      "createdAt": DateTime.now(),
    };
  }
}