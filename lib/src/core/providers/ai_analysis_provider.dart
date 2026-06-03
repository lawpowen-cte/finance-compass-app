import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/finance_repository.dart';
import '../services/ai_analysis_service.dart';
import 'repository_provider.dart';

/// AI 分析状态
class AiAnalysisState {
  final bool loading;
  final String? html;
  final String? error;
  final bool completed; // 已完成但用户还没看

  const AiAnalysisState({
    this.loading = false,
    this.html,
    this.error,
    this.completed = false,
  });

  AiAnalysisState copyWith({
    bool? loading,
    String? html,
    String? error,
    bool? completed,
  }) {
    return AiAnalysisState(
      loading: loading ?? this.loading,
      html: html ?? this.html,
      error: error ?? this.error,
      completed: completed ?? this.completed,
    );
  }
}

/// 全局 AI 分析 Provider，后台运行不受页面切换影响
class AiAnalysisNotifier extends Notifier<AiAnalysisState> {
  @override
  AiAnalysisState build() => const AiAnalysisState();

  Future<void> runAnalysis() async {
    final repoAsync = ref.read(financeRepositoryProvider);
    final repo = repoAsync.value;
    if (repo == null) return;

    final gatewayUrl = repo.aiGatewayUrl;
    if (gatewayUrl.isEmpty) {
      state = state.copyWith(error: '请先在设置中配置 AI 网关地址');
      return;
    }

    // 已在运行则跳过
    if (state.loading) return;

    state = const AiAnalysisState(loading: true);

    try {
      final service = AiAnalysisService(gatewayUrl: gatewayUrl);
      final html = await service.generateAnalysis(repo);
      state = AiAnalysisState(html: html, completed: true);
    } catch (e) {
      final msg = e is AiNetworkException ? e.message : 'AI 分析失败：$e';
      state = AiAnalysisState(error: msg);
    }
  }

  void dismissCompleted() {
    state = state.copyWith(completed: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final aiAnalysisProvider =
    NotifierProvider<AiAnalysisNotifier, AiAnalysisState>(
  AiAnalysisNotifier.new,
);
