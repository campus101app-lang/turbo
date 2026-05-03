// lib/screens/workflows/create_workflow_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import 'workflows_screen.dart';

class CreateWorkflowScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const CreateWorkflowScreen({super.key, this.insideShell = false});

  @override
  ConsumerState<CreateWorkflowScreen> createState() =>
      _CreateWorkflowScreenState();
}

class _CreateWorkflowScreenState extends ConsumerState<CreateWorkflowScreen> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();

  String _triggerType = 'scheduled';
  String _actionType = 'notifyUser';
  String _interval = 'monthly';
  String _asset = 'USDC';
  bool _loading = false;
  bool _showTemplates = false;

  static const _triggers = [
    ('scheduled', 'Scheduled', Icons.schedule_rounded),
    ('balanceThreshold', 'Balance Threshold', Icons.account_balance_wallet_rounded),
    ('invoicePaid', 'Invoice Paid', Icons.receipt_long_rounded),
    ('expenseApproved', 'Expense Approved', Icons.check_circle_outline_rounded),
    ('manualRun', 'Manual Trigger', Icons.play_circle_outline_rounded),
  ];

  static const _actions = [
    ('sendPayment', 'Send Payment', Icons.send_rounded),
    ('sendReminder', 'Send Reminder', Icons.notifications_rounded),
    ('notifyUser', 'Push Notify', Icons.notification_important_rounded),
    ('flagExpense', 'Flag Expense', Icons.flag_rounded),
  ];

  void _applyTemplate(WorkflowTemplate tpl) {
    setState(() {
      _nameCtrl.text = tpl.name;
      _triggerType = tpl.triggerType;
      _actionType = tpl.actionType;
      _interval = tpl.interval;
      _showTemplates = false;
    });
  }

  Map<String, dynamic> _buildTriggerConfig() {
    switch (_triggerType) {
      case 'scheduled':
        return {'interval': _interval, 'hour': 9};
      case 'balanceThreshold':
        return {'asset': _asset, 'threshold': double.tryParse(_amountCtrl.text) ?? 10};
      default:
        return {};
    }
  }

  Map<String, dynamic> _buildActionConfig() {
    switch (_actionType) {
      case 'sendPayment':
        return {
          'to': _toCtrl.text.trim(),
          'amount': double.tryParse(_amountCtrl.text) ?? 0,
          'asset': _asset,
        };
      case 'notifyUser':
      case 'sendReminder':
        return {'message': _msgCtrl.text.trim()};
      case 'flagExpense':
        return {'reason': _msgCtrl.text.trim().isEmpty ? 'Flagged by workflow' : _msgCtrl.text.trim()};
      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Workflow name is required');
      return;
    }
    setState(() => _loading = true);
    try {
      await apiService.createWorkflow({
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'triggerType': _triggerType,
        'triggerConfig': _buildTriggerConfig(),
        'actionType': _actionType,
        'actionConfig': _buildActionConfig(),
      });
      if (mounted) {
        ref.read(shellNavProvider.notifier).goBack();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow created!')),
        );
      }
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget body = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => ref.read(shellNavProvider.notifier).goBack(),
        ),
        title: Text(
          'New Workflow',
          style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700, fontSize: 17, color: cs.onSurface),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _showTemplates = !_showTemplates),
            icon: Icon(
              _showTemplates ? Icons.close_rounded : Icons.auto_awesome_rounded,
              size: 16,
              color: cs.primary,
            ),
            label: Text(
              _showTemplates ? 'Close' : 'Templates',
              style: GoogleFonts.bricolageGrotesque(
                  color: cs.primary, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _showTemplates
            ? _TemplatesPicker(onSelect: _applyTemplate)
            : _FormBody(
                nameCtrl: _nameCtrl,
                descCtrl: _descCtrl,
                toCtrl: _toCtrl,
                amountCtrl: _amountCtrl,
                msgCtrl: _msgCtrl,
                triggerType: _triggerType,
                actionType: _actionType,
                interval: _interval,
                asset: _asset,
                triggers: _triggers,
                actions: _actions,
                loading: _loading,
                onTriggerChanged: (v) => setState(() => _triggerType = v),
                onActionChanged: (v) => setState(() => _actionType = v),
                onIntervalChanged: (v) => setState(() => _interval = v),
                onAssetChanged: (v) => setState(() => _asset = v),
                onSubmit: _submit,
              ),
      ),
    );

    return widget.insideShell ? body : AppBackground(child: body);
  }
}

// ─── Form body ────────────────────────────────────────────────────────────────

class _FormBody extends StatelessWidget {
  final TextEditingController nameCtrl, descCtrl, toCtrl, amountCtrl, msgCtrl;
  final String triggerType, actionType, interval, asset;
  final List<(String, String, IconData)> triggers, actions;
  final bool loading;
  final ValueChanged<String> onTriggerChanged, onActionChanged,
      onIntervalChanged, onAssetChanged;
  final VoidCallback onSubmit;

  const _FormBody({
    required this.nameCtrl,
    required this.descCtrl,
    required this.toCtrl,
    required this.amountCtrl,
    required this.msgCtrl,
    required this.triggerType,
    required this.actionType,
    required this.interval,
    required this.asset,
    required this.triggers,
    required this.actions,
    required this.loading,
    required this.onTriggerChanged,
    required this.onActionChanged,
    required this.onIntervalChanged,
    required this.onAssetChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('Name'),
          const SizedBox(height: 6),
          _WfField(controller: nameCtrl, hint: 'e.g. Monthly Payroll'),
          const SizedBox(height: 14),

          _SectionLabel('Description (optional)'),
          const SizedBox(height: 6),
          _WfField(controller: descCtrl, hint: 'What does this do?', maxLines: 2),
          const SizedBox(height: 20),

          _SectionLabel('Trigger — when should this run?'),
          const SizedBox(height: 10),
          ...triggers.map((item) {
            final selected = triggerType == item.$1;
            return _SelectRow(
              icon: item.$3,
              label: item.$2,
              selected: selected,
              onTap: () => onTriggerChanged(item.$1),
            );
          }),

          if (triggerType == 'scheduled') ...[
            const SizedBox(height: 12),
            _SectionLabel('Repeat every'),
            const SizedBox(height: 8),
            Row(
              children: ['daily', 'weekly', 'monthly'].map((iv) {
                final sel = interval == iv;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onIntervalChanged(iv),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: EdgeInsets.only(right: iv != 'monthly' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${iv[0].toUpperCase()}${iv.substring(1)}',
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? cs.primary : cs.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          if (triggerType == 'balanceThreshold') ...[
            const SizedBox(height: 12),
            _SectionLabel('Threshold amount'),
            const SizedBox(height: 6),
            _WfField(
              controller: amountCtrl,
              hint: 'e.g. 100',
              keyboardType: TextInputType.number,
            ),
          ],

          const SizedBox(height: 20),
          _SectionLabel('Action — what should happen?'),
          const SizedBox(height: 10),
          ...actions.map((item) {
            final selected = actionType == item.$1;
            return _SelectRow(
              icon: item.$3,
              label: item.$2,
              selected: selected,
              onTap: () => onActionChanged(item.$1),
            );
          }),

          if (actionType == 'sendPayment') ...[
            const SizedBox(height: 12),
            _SectionLabel('Recipient address'),
            const SizedBox(height: 6),
            _WfField(controller: toCtrl, hint: 'Wallet address or username'),
            const SizedBox(height: 10),
            _SectionLabel('Amount & asset'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                    child: _WfField(
                        controller: amountCtrl,
                        hint: 'Amount',
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                ...['USDC', 'NGNT'].map((a) {
                  final sel = asset == a;
                  return GestureDetector(
                    onTap: () => onAssetChanged(a),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel
                            ? cs.primary.withValues(alpha: 0.12)
                            : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: sel
                              ? cs.primary.withValues(alpha: 0.4)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(a,
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? cs.primary : cs.onSurface,
                          )),
                    ),
                  );
                }),
              ],
            ),
          ],

          if (actionType == 'notifyUser' ||
              actionType == 'sendReminder' ||
              actionType == 'flagExpense') ...[
            const SizedBox(height: 12),
            _SectionLabel('Message / Reason'),
            const SizedBox(height: 6),
            _WfField(controller: msgCtrl, hint: 'e.g. Don\'t forget to pay', maxLines: 2),
          ],

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: loading ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : Text(
                      'Create Workflow',
                      style: GoogleFonts.bricolageGrotesque(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Templates picker ─────────────────────────────────────────────────────────

class _TemplatesPicker extends StatelessWidget {
  final void Function(WorkflowTemplate) onSelect;
  const _TemplatesPicker({required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      key: const ValueKey('templates'),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      children: [
        Text(
          'Choose a template',
          style: GoogleFonts.bricolageGrotesque(
              fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        Text(
          'Tap to pre-fill the form',
          style: TextStyle(
              fontSize: 13, color: cs.onSurface.withValues(alpha: 0.45)),
        ),
        const SizedBox(height: 16),
        ...kWorkflowTemplates.map((tpl) => GestureDetector(
              onTap: () => onSelect(tpl),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: cs.onSurface.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(tpl.icon, size: 20, color: cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tpl.name,
                              style: GoogleFonts.bricolageGrotesque(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: cs.onSurface)),
                          const SizedBox(height: 2),
                          Text(tpl.description,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18,
                        color: cs.onSurface.withValues(alpha: 0.3)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.bricolageGrotesque(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          letterSpacing: 0.2,
        ),
      );
}

class _SelectRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectRow(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.08)
              : cs.onSurface.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: selected
                    ? cs.primary
                    : cs.onSurface.withValues(alpha: 0.7)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? cs.primary : cs.onSurface,
              ),
            ),
            const Spacer(),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

class _WfField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _WfField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.bricolageGrotesque(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.35), fontSize: 14),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.onSurface.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
