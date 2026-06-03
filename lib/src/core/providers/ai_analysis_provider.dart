import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../services/ai_analysis_service.dart';
import 'repository_provider.dart';

final aiAnalysisServiceProvider = Provider<AiAnalysisService?>((ref) {
  // Will be loaded from meta values
  return null;
});

final aiAnalysisResultProvider = StateProvider<String?>((ref) => null);
final aiAnalysisLoadingProvider = StateProvider<bool>((ref) => false);
