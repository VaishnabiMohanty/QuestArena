// WHAT THIS FILE DOES:
// Provides a curated list of avatars with league requirements, names, and genders.

enum AvatarGender { male, female }

class AvatarModel {
  final String id;
  final String name;
  final String image;
  final AvatarGender gender;
  final String requiredLeague;
  final String style;

  const AvatarModel({
    required this.id,
    required this.name,
    required this.image,
    required this.gender,
    required this.requiredLeague,
    this.style = 'Casual',
  });
}

class AppAvatars {
  AppAvatars._();

  static const List<AvatarModel> avatars = [
    // --- DEFAULT (Unranked) ---
    AvatarModel(
      id: 'default_m1',
      name: 'Veer',
      image: 'm1',
      gender: AvatarGender.male,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'default_f1',
      name: 'Nova',
      image: 'f1',
      gender: AvatarGender.female,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'default_f2',
      name: 'Arya',
      image: 'f2',
      gender: AvatarGender.female,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'default_m2',
      name: 'Zane',
      image: 'm2',
      gender: AvatarGender.male,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'default_f3',
      name: 'Lyra',
      image: 'f3',
      gender: AvatarGender.female,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'default_m3',
      name: 'Ryo',
      image: 'm3',
      gender: AvatarGender.male,
      requiredLeague: 'Unranked',
      style: 'Casual',
    ),

    // --- BRONZE ---
    AvatarModel(
      id: 'bronze_m1',
      name: 'Felix',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Felix',
      gender: AvatarGender.male,
      requiredLeague: 'Bronze',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'bronze_f1',
      name: 'Aneka',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Aneka',
      gender: AvatarGender.female,
      requiredLeague: 'Bronze',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'bronze_m2',
      name: 'Buddy',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Buddy',
      gender: AvatarGender.male,
      requiredLeague: 'Bronze',
      style: 'Sporty',
    ),
    AvatarModel(
      id: 'bronze_f2',
      name: 'Kiki',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Kiki',
      gender: AvatarGender.female,
      requiredLeague: 'Bronze',
      style: 'Gamer',
    ),

    // --- SILVER ---
    AvatarModel(
      id: 'silver_m1',
      name: 'Jasper',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Jasper',
      gender: AvatarGender.male,
      requiredLeague: 'Silver',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'silver_f1',
      name: 'Luna',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Luna',
      gender: AvatarGender.female,
      requiredLeague: 'Silver',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'silver_m2',
      name: 'Toby',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Toby',
      gender: AvatarGender.male,
      requiredLeague: 'Silver',
      style: 'Sporty',
    ),
    AvatarModel(
      id: 'silver_f2',
      name: 'Nala',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Nala',
      gender: AvatarGender.female,
      requiredLeague: 'Silver',
      style: 'Professional',
    ),

    // --- GOLD ---
    AvatarModel(
      id: 'gold_m1',
      name: 'Simba',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Simba',
      gender: AvatarGender.male,
      requiredLeague: 'Gold',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'gold_f1',
      name: 'Peanut',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Peanut',
      gender: AvatarGender.female,
      requiredLeague: 'Gold',
      style: 'Sporty',
    ),
    AvatarModel(
      id: 'gold_m2',
      name: 'Milo',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Milo',
      gender: AvatarGender.male,
      requiredLeague: 'Gold',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'gold_f2',
      name: 'Daisy',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Daisy',
      gender: AvatarGender.female,
      requiredLeague: 'Gold',
      style: 'Casual',
    ),

    // --- PLATINUM ---
    AvatarModel(
      id: 'plat_m1',
      name: 'Harley',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Harley',
      gender: AvatarGender.male,
      requiredLeague: 'Platinum',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'plat_f1',
      name: 'Ginger',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Ginger',
      gender: AvatarGender.female,
      requiredLeague: 'Platinum',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'plat_m2',
      name: 'Bruno',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Bruno',
      gender: AvatarGender.male,
      requiredLeague: 'Platinum',
      style: 'Sporty',
    ),
    AvatarModel(
      id: 'plat_f2',
      name: 'Penny',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Penny',
      gender: AvatarGender.female,
      requiredLeague: 'Platinum',
      style: 'Professional',
    ),

    // --- DIAMOND ---
    AvatarModel(
      id: 'diamond_m1',
      name: 'Apollo',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Apollo',
      gender: AvatarGender.male,
      requiredLeague: 'Diamond',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'diamond_f1',
      name: 'Athena',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Athena',
      gender: AvatarGender.female,
      requiredLeague: 'Diamond',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'diamond_m2',
      name: 'Zeus',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Zeus',
      gender: AvatarGender.male,
      requiredLeague: 'Diamond',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'diamond_f2',
      name: 'Hera',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Hera',
      gender: AvatarGender.female,
      requiredLeague: 'Diamond',
      style: 'Professional',
    ),

    // --- MASTER ---
    AvatarModel(
      id: 'master_m1',
      name: 'Ares',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Ares',
      gender: AvatarGender.male,
      requiredLeague: 'Master',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'master_f1',
      name: 'Artemis',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Artemis',
      gender: AvatarGender.female,
      requiredLeague: 'Master',
      style: 'Fantasy',
    ),

    // --- CHAMPION ---
    AvatarModel(
      id: 'champ_m1',
      name: 'Hades',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Hades',
      gender: AvatarGender.male,
      requiredLeague: 'Champion',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'champ_f1',
      name: 'Persephone',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Persephone',
      gender: AvatarGender.female,
      requiredLeague: 'Champion',
      style: 'Fantasy',
    ),

    // --- LEGEND ---
    AvatarModel(
      id: 'legend_m1',
      name: 'Kronos',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Kronos',
      gender: AvatarGender.male,
      requiredLeague: 'Legend',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'legend_f1',
      name: 'Gaia',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Gaia',
      gender: AvatarGender.female,
      requiredLeague: 'Legend',
      style: 'Fantasy',
    ),
  ];

  static AvatarModel getAvatarByImage(String image) {
    return avatars.firstWhere(
      (a) => a.image == image,
      orElse: () => avatars[0],
    );
  }
}
