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
    };
  }
}
