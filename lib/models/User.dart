class User {
  final String uid;
  final String email;
  final String name;
  final int age;
  final double weight;
  final double height;
  final String gender;
  final String activity;
  final String goal;
  final List<String> diseases;
  final String avatar;
  final String role;
  final Map<String, dynamic>? nutrition;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.age,
    required this.weight,
    required this.height,
    required this.gender,
    required this.activity,
    required this.goal,
    required this.diseases,
    required this.avatar,
    required this.role,
    this.nutrition,
  });

  Map<String, dynamic> toMap() {
    return {
      "uid": uid,
      "email": email,
      "name": name,
      "age": age,
      "weight": weight,
      "height": height,
      "gender": gender,
      "activity": activity,
      "goal": goal,
      "diseases": diseases,
      "avatar": avatar,
      "role": role,
      "nutrition": nutrition
    };
  }
  factory User.fromMap(Map<String, dynamic> map, String id) {

    return User(

      uid: id,
      email: map["email"] ?? "",
      name: map["name"] ?? "",

      age: map["age"] ?? 0,

      weight: (map["weight"] ?? 0).toDouble(),
      height: (map["height"] ?? 0).toDouble(),

      gender: map["gender"] ?? "",
      activity: map["activity"] ?? "",
      goal: map["goal"] ?? "",

      diseases: List<String>.from(map["diseases"] ?? []),

      avatar: map["avatar"] ??
          "https://cdn-icons-png.flaticon.com/512/149/149071.png",

      role: map["role"] ?? "user",

      nutrition: map["nutrition"],

    );
  }
}