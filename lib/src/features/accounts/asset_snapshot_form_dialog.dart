import 'package:flutter/material.dart';

import '../../core/data/finance_repository.dart';
import '../../core/models/asset_snapshot.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/id_generator.dart';
import '../shared/finance_form_fields.dart';

class AssetSnapshotFormDialog extends StatefulWidget {
  const AssetSnapshotFormDialog({
    super.key,
    required this.repository,
    this.initialSnapshot,
  });

  final FinanceRepository repository;
  final AssetSnapshot? initialSnapshot;

  @override
  State<AssetSnapshotFormDialog> createState() => _AssetSnapshotFormDialogState();
}

class _AssetSnapshotFormDialogState extends State<AssetSnapshotFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController marketValueController;
  late final TextEditingController cashBalanceController;
  late final TextEditingController costBasisController;

  late DateTime snapshotDate;
  String? accountId;

  double get _marketValue => double.tryParse(marketValueController.text.trim()) ?? 0;
  double get _cashBalance => double.tryParse(cashBalanceController.text.trim()) ?? 0;
  double get _manualCostBasis => double.tryParse(costBasisController.text.trim()) ?? 0;

  bool get _canEditInitialCostBasis {
    if (accountId == null) {
      return false;
    }
    final initialSnapshot = widget.initialSnapshot;
    if (initialSnapshot == null) {
      return widget.repository.firstSnapshotForAccount(accountId!) == null;
    }
    final firstSnapshot = widget.repository.firstSnapshotForAccount(accountId!);
    return firstSnapshot?.id == initialSnapshot.id;
  }

  InvestmentFlowSummary get _totalFlowSummary => accountId == null
      ? const InvestmentFlowSummary(contribution: 0, withdrawal: 0)
      : widget.repository.investmentFlowSummaryForAccount(
          accountId!,
          upToDate: snapshotDate,
        );

  InvestmentFlowSummary get _deltaFlowSummary {
    if (accountId == null || _canEditInitialCostBasis) {
      return const InvestmentFlowSummary(contribution: 0, withdrawal: 0);
    }
    final firstSnapshot = widget.repository.firstSnapshotForAccount(accountId!);
    if (firstSnapshot == null) {
      return const InvestmentFlowSummary(contribution: 0, withdrawal: 0);
    }
    return widget.repository.investmentFlowSummaryForAccount(
      accountId!,
      fromDateExclusive: firstSnapshot.snapshotDate,
      upToDate: snapshotDate,
    );
  }

  double get _effectiveCostBasis {
    if (_canEditInitialCostBasis) {
      return _manualCostBasis;
    }
    final firstSnapshot = accountId == null ? null : widget.repository.firstSnapshotForAccount(accountId!);
    if (firstSnapshot == null) {
      return _totalFlowSummary.netContribution;
    }
    return (_manualCostBasis + _deltaFlowSummary.netContribution)
        .clamp(0, double.infinity)
        .toDouble();
  }

  double get _unrealizedPnl => _marketValue - _effectiveCostBasis;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialSnapshot;
    marketValueController = TextEditingController(text: initial?.marketValue.toString() ?? '');
    cashBalanceController = TextEditingController(text: initial?.cashBalance.toString() ?? '0');
    costBasisController = TextEditingController(text: initial?.costBasis.toString() ?? '0');
    snapshotDate = initial?.snapshotDate ?? DateTime.now();
    final investments = widget.repository.investmentAccounts();
    accountId = initial?.accountId ?? (investments.isNotEmpty ? investments.first.id : null);
    marketValueController.addListener(_refreshPreview);
    cashBalanceController.addListener(_refreshPreview);
    costBasisController.addListener(_refreshPreview);

    if (!_canEditInitialCostBasis && accountId != null) {
      final firstSnapshot = widget.repository.firstSnapshotForAccount(accountId!);
      if (firstSnapshot != null) {
        costBasisController.text = firstSnapshot.costBasis.toString();
      }
    }
  }

  @override
  void dispose() {
    marketValueController.removeListener(_refreshPreview);
    cashBalanceController.removeListener(_refreshPreview);
    costBasisController.removeListener(_refreshPreview);
    marketValueController.dispose();
    cashBalanceController.dispose();
    costBasisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investments = widget.repository.investmentAccounts();
    return AlertDialog(
      title: Text(widget.initialSnapshot == null ? '新增资产快照' : '编辑资产快照'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: accountId,
                  decoration: const InputDecoration(
                    labelText: '投资账户',
                    border: OutlineInputBorder(),
                  ),
                  items: investments
                      .map((account) => DropdownMenuItem(
                            value: account.id,
                            child: Text(account.name),
                          ))
                      .toList(),
                  onChanged: widget.initialSnapshot == null
                      ? (value) {
                          setState(() {
                            accountId = value;
                            final firstSnapshot =
                                value == null ? null : widget.repository.firstSnapshotForAccount(value);
                            costBasisController.text = (firstSnapshot?.costBasis ?? 0).toString();
                          });
                        }
                      : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('快照日期'),
                  subtitle: Text(
                    '${snapshotDate.year}-${snapshotDate.month.toString().padLeft(2, '0')}-${snapshotDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: TextButton(
                    onPressed: _pickDate,
                    child: const Text('修改'),
                  ),
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: marketValueController,
                  label: '账户总市值',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                const SizedBox(height: 12),
                FinanceTextField(
                  controller: cashBalanceController,
                  label: '账户现金余额',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: _numberRequired,
                ),
                if (_canEditInitialCostBasis) ...[
                  const SizedBox(height: 12),
                  FinanceTextField(
                    controller: costBasisController,
                    label: '累计成本基线',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _numberRequired,
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).cardColor.withValues(alpha: 0.72),
                    border: Border.all(color: Theme.of(context).cardColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('自动计算', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      if (_canEditInitialCostBasis)
                        Text('累计成本基线: ${formatMoney(_manualCostBasis)}')
                      else ...[
                        Text('累计投入: ${formatMoney(_totalFlowSummary.contribution)}'),
                        const SizedBox(height: 4),
                        Text('累计取出: ${formatMoney(_totalFlowSummary.withdrawal)}'),
                        const SizedBox(height: 4),
                      ],
                      Text('累计成本: ${formatMoney(_effectiveCostBasis)}'),
                      const SizedBox(height: 4),
                      Text('未实现盈亏: ${formatMoney(_unrealizedPnl)}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('取消')),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: snapshotDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => snapshotDate = picked);
    }
  }

  void _submit() {
    if (!formKey.currentState!.validate() || accountId == null) {
      return;
    }

    Navigator.of(context).pop(
      AssetSnapshot(
        id: widget.initialSnapshot?.id ?? buildId('snap'),
        accountId: accountId!,
        snapshotDate: snapshotDate,
        marketValue: _marketValue,
        costBasis: _effectiveCostBasis,
        cashBalance: _cashBalance,
        unrealizedPnl: _unrealizedPnl,
      ),
    );
  }

  void _refreshPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  String? _numberRequired(String? value) =>
      double.tryParse(value ?? '') == null ? '请输入数字' : null;
}
