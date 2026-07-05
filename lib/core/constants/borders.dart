import '../../data/models/border_model.dart';

class AppBorders {
  AppBorders._();

  static const List<BorderModel> borders = [
    BorderModel(
      id: 'no_border',
      name: 'None',
      image: '',
      requiredLeague: 'Unranked',
    ),
    BorderModel(
      id: 'bronze_border',
      name: 'Bronze Border',
      image: 'assets/borders/bronze_border.png',
      requiredLeague: 'Bronze',
    ),
    BorderModel(
      id: 'silver_border',
      name: 'Silver Border',
      image: 'assets/borders/silver_border.png',
      requiredLeague: 'Silver',
    ),
    BorderModel(
      id: 'gold_border',
      name: 'Gold Border',
      image: 'assets/borders/gold_border.png',
      requiredLeague: 'Gold',
    ),
    BorderModel(
      id: 'platinum_border',
      name: 'Platinum Border',
      image: 'assets/borders/platinum_border.png',
      requiredLeague: 'Platinum',
    ),
    BorderModel(
      id: 'diamond_border',
      name: 'Diamond Border',
      image: 'assets/borders/diamond_border.png',
      requiredLeague: 'Diamond',
    ),
  ];

  static BorderModel getBorderById(String? id) {
    if (id == null) return borders[0];
    return borders.firstWhere(
      (b) => b.id == id,
      orElse: () => borders[0],
    );
  }
}
