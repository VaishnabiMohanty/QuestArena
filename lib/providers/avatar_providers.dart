import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/avatar_service.dart';

final avatarServiceProvider = Provider((ref) => AvatarService());
