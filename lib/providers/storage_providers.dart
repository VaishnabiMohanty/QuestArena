import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/storage_service.dart';

final storageServiceProvider = Provider((ref) => StorageService());
