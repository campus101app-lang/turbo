// lib/screens/workflows/workflow_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../providers/selected_workflow_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import 'workflows_screen.dart';

class WorkflowDetailScreen extends ConsumerStatefulWidget {
  final bool insideShell;
  const WorkflowDetailScreen({super.key, this.insideShell = false});

  @override
  ConsumerState<WorkflowDetailScreen> createState() =>
      _WorkflowDetailScreenState();
}

class _WorkflowDetailScreenState extends ConsumerState<WorkflowDetailScreen> {
  bool _running = false;
  bool _toggling = false;
  bool _deleting = false;
  bool _editMode = false;

  // Edit controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _toCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _msgCtrl;
  late String _triggerType;
  late String _actionType;
  late String _interval;
  late String _asset;
  bool _saving = false;

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

  @override
  void initState() {
    super.initState();
    _initEditControllers();
  }

  void _initEditControllers([Workflow? w]) {
    final workflow = w ?? ref.read(selectedWorkflowProvider);
    _nameCtrl = TextEditingController(text: workflow?.name ?? '');
    _descCtrl = TextEditingController(text: workflow?.description ?? '');
    _toCtrl = TextEditingController(
      text: (workflow?.actionConfig['to'] ?? workflow?.actionConfig['recipient'] ?? '').toString(),
    );
    _amountCtrl = TextEditingController(
      text: (workflow?.actionConfig['amount'] ?? workflow?.triggerConfig['threshold'] ?? '').toString(),
    );
    _msgCtrl = TextEditingController(
      text: (workflow?.actionConfig['message'] ?? '').toString(),
    );
    _triggerType = workflow?.triggerType ?? 'scheduled';
    _actionType = workflow?.actionType ?? 'notifyUser';
    _interval = (workflow?.triggerConfig['interval'] ?? 'monthly').toString();
    _asset = (workflow?.actionConfig['asset'] ?? workflow?.triggerConfig['asset'] ?? 'USDC').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _runNow(Workflow w) async {
    setState(() => _running = true);
    try {
      await apiService.runWorkflow(w.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workflow triggered')),
        );
      }
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _toggle(Workflow w) async {
    setState(() => _toggling = true);
    try {
      if (w.isActive) {
        await apiService.pauseWorkflow(w.id);
      } else {
        await apiService.resumeWorkflow(w.id);
      }
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _delete(Workflow w) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive workflow?'),
        content: const Text('This workflow will stop running.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Archive', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _deleting = true);
    try {
      await apiService.deleteWorkflow(w.id);
      if (mounted) ref.read(shellNavProvider.notifier).goBack();
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
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
        return {'to': _toCtrl.text.trim(), 'amount': double.tryParse(_amountCtrl.text) ?? 0, 'asset': _asset};
      case 'notifyUser':
      case 'sendReminder':
        return {'message': _msgCtrl.text.trim()};
      case 'flagExpense':
        return {'reason': _msgCtrl.text.trim().isEmpty ? 'Flagged by workflow' : _msgCtrl.text.trim()};
      default:
        return {};
    }
  }

  Future<void> _save(Workflow w) async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await apiService.updateWorkflow(w.id, {
        'name': _nameCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
        'triggerType': _triggerType,
        'triggerConfig': _buildTriggerConfig(),
        'actionType': _actionType,
        'actionConfig': _buildActionConfig(),
      });
      if (mounted) {
        setState(() => _editMode = false);
        ref.read(shellNavProvider.notifier).goBack();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow updated')));
      }
    } catch (e) {
      if (mounted) _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _triggerLabel(String t) => const {
        'scheduled': 'Scheduled',
        'balanceThreshold': 'Balance Threshold',
        'invoicePaid': 'Invoice Paid',
        'expenseApproved': 'Expense Approved',
        'manualRun': 'Manual',
      }[t] ??
      t;

  String _actionLabel(String a) => const {
        'sendPayment': 'Send Payment',
        'sendReminder': 'Send Reminder',
        'notifyUser': 'Push Notify',
        'flagExpense': 'Flag Expense',
      }[a] ??
      a;

  @override
  Widget build(BuildContext context) {
    final w = ref.watch(selectedWorkflowProvider);
    if (w == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(shellNavProvider.notifier).goBack();
      });
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;

    Widget body = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_editMode) {
              setState(() => _editMode = false);
            } else {
              ref.read(shellNavProvider.notifier).goBack();
            }
          },
        ),
        title: Text(
          _editMode ? 'Edit Workflow' : w.name,
          style: GoogleFonts.bricolageGrotesque(
              fontWeight: FontWeight.w700, fontSize: 17, color: cs.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!_editMode)
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => setState(() {
                _initEditControllers(w);
                _editMode = true;
              }),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _editMode
            ? _EditForm(
                key: const ValueKey('edit'),
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
                saving: _saving,
                onTriggerChanged: (v) => setState(() => _triggerType = v),
                onActionChanged: (v) => setState(() => _actionType = v),
                onIntervalChanged: (v) => setState(() => _interval = v),
                onAssetChanged: (v) => setState(() => _asset = v),
                onSave: () => _save(w),
                onCancel: () => setState(() => _editMode = false),
              )
            : _DetailView(
                key: const ValueKey('detail'),
                workflow: w,
                running: _running,
                toggling: _toggling,
                deleting: _deleting,
                triggerLabel: _triggerLabel,
                actionLabel: _actionLabel,
                onRunNow: () => _runNow(w),
                onToggle: () => _toggle(w),
                onDelete: () => _delete(w),
              ),
      ),
    );

    return widget.insideShell ? body : AppBackground(child: body);
  }
}

// ─── Detail view ──────────────────────────────────────────────────────────────

class _DetailView extends StatelessWidget {
  final Workflow workflow;
  final bool running, toggling, deleting;
  final String Function(String) triggerLabel, actionLabel;
  final VoidCallback onRunNow, onToggle, onDelete;

  const _DetailView({
    super.key,
    required this.workflow,
    required this.running,
    required this.toggling,
    required this.deleting,
    required this.triggerLabel,
    required this.actionLabel,
    required this.onRunNow,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final w = workflow;
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (w.description != null && w.description!.isNotEmpty) ...[
            Text(
              w.description!,
              style: TextStyle(fontSize: 14, color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 20),
          ],

          // Stats
          Row(
            children: [
              _StatChip(label: 'Runs', value: '${w.runCount}', color: const Color(0xFF6C47FF)),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Fails',
                value: '${w.failCount}',
                color: w.failCount > 0 ? DayFiColors.red : DayFiColors.green,
              ),
              const SizedBox(width: 10),
              _StatChip(
                label: 'Status',
                value: w.status,
                color: w.isActive ? DayFiColors.green : const Color(0xFFFFA726),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _WfDetailRow(label: 'Trigger', value: triggerLabel(w.triggerType)),
          _WfDetailRow(label: 'Action', value: actionLabel(w.actionType)),
          if (w.lastRunAt != null)
            _WfDetailRow(
              label: 'Last run',
              value: DateFormat('MMM d, yyyy HH:mm').format(w.lastRunAt!),
            ),
          if (w.nextRunAt != null)
            _WfDetailRow(
              label: 'Next run',
              value: DateFormat('MMM d, yyyy HH:mm').format(w.nextRunAt!),
            ),
          if (w.lastError != null)
            _WfDetailRow(label: 'Last error', value: w.lastError!, isWarning: true),

          const SizedBox(height: 28),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: running ? null : onRunNow,
                  icon: running
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text('Run now',
                      style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                      color: w.isActive
                          ? const Color(0xFFFFA726).withValues(alpha: 0.5)
                          : DayFiColors.green.withValues(alpha: 0.5),
                    ),
                  ),
                  onPressed: toggling ? null : onToggle,
                  icon: toggling
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Icon(
                          w.isActive ? Icons.pause_circle_outline_rounded : Icons.play_circle_outline_rounded,
                          size: 18,
                          color: w.isActive ? const Color(0xFFFFA726) : DayFiColors.green,
                        ),
                  label: Text(
                    w.isActive ? 'Pause' : 'Resume',
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      color: w.isActive ? const Color(0xFFFFA726) : DayFiColors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: DayFiColors.red.withValues(alpha: 0.4)),
                ),
                onPressed: deleting ? null : onDelete,
                child: deleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DayFiColors.red))
                    : const Icon(Icons.delete_outline_rounded, size: 18, color: DayFiColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Edit form ────────────────────────────────────────────────────────────────

class _EditForm extends StatelessWidget {
  final TextEditingController nameCtrl, descCtrl, toCtrl, amountCtrl, msgCtrl;
  final String triggerType, actionType, interval, asset;
  final List<(String, String, IconData)> triggers, actions;
  final bool saving;
  final ValueChanged<String> onTriggerChanged, onActionChanged, onIntervalChanged, onAssetChanged;
  final VoidCallback onSave, onCancel;

  const _EditForm({
    super.key,
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
    required this.saving,
    required this.onTriggerChanged,
    required this.onActionChanged,
    required this.onIntervalChanged,
    required this.onAssetChanged,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WfLabel('Name'),
          const SizedBox(height: 6),
          _WfEditField(controller: nameCtrl, hint: 'Workflow name'),
          const SizedBox(height: 12),
          _WfLabel('Description (optional)'),
          const SizedBox(height: 6),
          _WfEditField(controller: descCtrl, hint: 'Description', maxLines: 2),
          const SizedBox(height: 16),

          _WfLabel('Trigger'),
          const SizedBox(height: 8),
          ...triggers.map((t) {
            final sel = triggerType == t.$1;
            return GestureDetector(
              onTap: () => onTriggerChanged(t.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? cs.primary.withValues(alpha: 0.10)
                      : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(t.$3, size: 16, color: sel ? cs.primary : cs.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(t.$2, style: TextStyle(color: sel ? cs.primary : cs.onSurface)),
                    const Spacer(),
                    if (sel) Icon(Icons.check_rounded, size: 16, color: cs.primary),
                  ],
                ),
              ),
            );
          }),

          if (triggerType == 'scheduled') ...[
            const SizedBox(height: 8),
            Row(
              children: ['daily', 'weekly', 'monthly'].map((iv) {
                final sel = interval == iv;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onIntervalChanged(iv),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(right: iv != 'monthly' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: sel ? cs.primary.withValues(alpha: 0.12) : cs.onSurface.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? cs.primary.withValues(alpha: 0.4) : Colors.transparent),
                      ),
                      child: Center(
                        child: Text('${iv[0].toUpperCase()}${iv.substring(1)}',
                            style: GoogleFonts.bricolageGrotesque(
                              color: sel ? cs.primary : cs.onSurface,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 16),
          _WfLabel('Action'),
          const SizedBox(height: 8),
          ...actions.map((a) {
            final sel = actionType == a.$1;
            return GestureDetector(
              onTap: () => onActionChanged(a.$1),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? cs.primary.withValues(alpha: 0.10) : cs.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(a.$3, size: 16, color: sel ? cs.primary : cs.onSurface.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(a.$2, style: TextStyle(color: sel ? cs.primary : cs.onSurface)),
                    const Spacer(),
                    if (sel) Icon(Icons.check_rounded, size: 16, color: cs.primary),
                  ],
                ),
              ),
            );
          }),

          if (actionType == 'notifyUser' || actionType == 'sendReminder' || actionType == 'flagExpense') ...[
            const SizedBox(height: 10),
            _WfEditField(controller: msgCtrl, hint: 'Message / Reason', maxLines: 2),
          ],
          if (actionType == 'sendPayment') ...[
            const SizedBox(height: 10),
            _WfEditField(controller: toCtrl, hint: 'Recipient'),
            const SizedBox(height: 8),
            _WfEditField(controller: amountCtrl, hint: 'Amount', keyboardType: TextInputType.number),
          ],

          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel',
                      style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: saving ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text('Save changes',
                          style: GoogleFonts.bricolageGrotesque(
                              fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Text(value,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16, fontWeight: FontWeight.w700, color: color)),
              Text(label,
                  style: GoogleFonts.bricolageGrotesque(
                      fontSize: 10, color: color.withValues(alpha: 0.7))),
            ],
          ),
        ),
      );
}

class _WfDetailRow extends StatelessWidget {
  final String label, value;
  final bool isWarning;
  const _WfDetailRow({required this.label, required this.value, this.isWarning = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isWarning ? DayFiColors.red : null)),
            ),
          ],
        ),
      );
}

class _WfLabel extends StatelessWidget {
  final String text;
  const _WfLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.bricolageGrotesque(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)));
}

class _WfEditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _WfEditField(
      {required this.controller, required this.hint, this.maxLines = 1, this.keyboardType});

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
        hintStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.35), fontSize: 14),
        filled: true,
        fillColor: cs.onSurface.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
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
