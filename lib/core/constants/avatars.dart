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
    // --- BRONZE (Starting) ---
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
    AvatarModel(
      id: 'bronze_m3',
      name: 'Max',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Max',
      gender: AvatarGender.male,
      requiredLeague: 'Bronze',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'bronze_f3',
      name: 'Cookie',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Cookie',
      gender: AvatarGender.female,
      requiredLeague: 'Bronze',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'bronze_m4',
      name: 'Leo',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Leo',
      gender: AvatarGender.male,
      requiredLeague: 'Bronze',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'bronze_f4',
      name: 'Mia',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Mia',
      gender: AvatarGender.female,
      requiredLeague: 'Bronze',
      style: 'Sporty',
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
    AvatarModel(
      id: 'silver_m3',
      name: 'Oliver',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Oliver',
      gender: AvatarGender.male,
      requiredLeague: 'Silver',
      style: 'Casual',
    ),
    AvatarModel(
      id: 'silver_f3',
      name: 'Zoe',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Zoe',
      gender: AvatarGender.female,
      requiredLeague: 'Silver',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'silver_m4',
      name: 'Finn',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Finn',
      gender: AvatarGender.male,
      requiredLeague: 'Silver',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'silver_f4',
      name: 'Maya',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Maya',
      gender: AvatarGender.female,
      requiredLeague: 'Silver',
      style: 'Sporty',
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
    AvatarModel(
      id: 'gold_m3',
      name: 'Oscar',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Oscar',
      gender: AvatarGender.male,
      requiredLeague: 'Gold',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'gold_f3',
      name: 'Bella',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Bella',
      gender: AvatarGender.female,
      requiredLeague: 'Gold',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'gold_m4',
      name: 'Hugo',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Hugo',
      gender: AvatarGender.male,
      requiredLeague: 'Gold',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'gold_f4',
      name: 'Iris',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Iris',
      gender: AvatarGender.female,
      requiredLeague: 'Gold',
      style: 'Gamer',
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
    AvatarModel(
      id: 'plat_m3',
      name: 'Rex',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Rex',
      gender: AvatarGender.male,
      requiredLeague: 'Platinum',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'plat_f3',
      name: 'Ruby',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Ruby',
      gender: AvatarGender.female,
      requiredLeague: 'Platinum',
      style: 'Gamer',
    ),
    AvatarModel(
      id: 'plat_m4',
      name: 'Duke',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Duke',
      gender: AvatarGender.male,
      requiredLeague: 'Platinum',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'plat_f4',
      name: 'Sasha',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Sasha',
      gender: AvatarGender.female,
      requiredLeague: 'Platinum',
      style: 'Sporty',
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
    AvatarModel(
      id: 'diamond_m3',
      name: 'Thor',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Thor',
      gender: AvatarGender.male,
      requiredLeague: 'Diamond',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'diamond_f3',
      name: 'Freya',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Freya',
      gender: AvatarGender.female,
      requiredLeague: 'Diamond',
      style: 'Fantasy',
    ),
    AvatarModel(
      id: 'diamond_m4',
      name: 'Odin',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Odin',
      gender: AvatarGender.male,
      requiredLeague: 'Diamond',
      style: 'Professional',
    ),
    AvatarModel(
      id: 'diamond_f4',
      name: 'Frigg',
      image: 'https://api.dicebear.com/7.x/avataaars/png?seed=Frigg',
      gender: AvatarGender.female,
      requiredLeague: 'Diamond',
      style: 'Fantasy',
    ),
  ];
}
