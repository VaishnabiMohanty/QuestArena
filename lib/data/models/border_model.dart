class BorderModel {
  final String id;
  final String name;
  final String image;
  final String requiredLeague;
  final bool isUnlocked;

  const BorderModel({
    required this.id,
    required this.name,
    required this.image,
    required this.requiredLeague,
    this.isUnlocked = false,
  });

  BorderModel copyWith({
    bool? isUnlocked,
  }) {
    return BorderModel(
      id: id,
      name: name,
      image: image,
      requiredLeague: requiredLeague,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  factory BorderModel.fromJson(Map<String, dynamic> json) {
    return BorderModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      image: json['image'] ?? '',
      requiredLeague: json['requiredLeague'] ?? 'Bronze',
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'requiredLeague': requiredLeague,
        'isUnlocked': isUnlocked,
      };
}
