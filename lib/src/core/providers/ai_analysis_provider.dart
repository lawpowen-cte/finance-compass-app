import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiAnalysisResultProvider = StateProvider<String?>((ref) => null);
final aiAnalysisLoadingProvider = StateProvider<bool>((ref) => false);
