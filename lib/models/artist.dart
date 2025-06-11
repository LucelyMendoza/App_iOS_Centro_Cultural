class Artist {
  final int id;
  final String name;
  final String username;
  final String image;

  Artist({
    required this.id,
    required this.name,
    required this.username,
    required this.image,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'username': username,
      'image': image,
    };
  }

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as int,
      name: map['name'] as String,
      username: map['username'] as String,
      image: map['image'] as String,
    );
  }
}
