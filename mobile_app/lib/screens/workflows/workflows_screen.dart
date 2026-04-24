// lib/screens/workflows/workflows_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottomsheet.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

class Workflow {
  final String id;
  final String name;
  final String? description;
  final String triggerType;
  final Map<String, dynamic> triggerConfig;
  final String actionType;
  final Map<String, dynamic> actionConfig;
  final String status;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  final int runCount;
  final int failCount;
  final String? lastError;
  final DateTime createdAt;

  const Workflow({
    required this.id,
    required this.name,
    this.description,
    required this.triggerType,
    required this.triggerConfig,
    required this.actionType,
    required this.actionConfig,
    required this.status,
    this.lastRunAt,
    this.nextRunAt,
    this.runCount = 0,
    this.failCount = 0,
    this.lastError,
    required this.createdAt,
  });

  factory Workflow.fromJson(Map<String, dynamic> j) => Workflow(
    id: j['id'] ?? '',
    name: j['name'] ?? '',
    description: j['description'],
    triggerType: j['triggerType'] ?? 'scheduled',
    triggerConfig: Map<String, dynamic>.from(j['triggerConfig'] ?? {}),
    actionType: j['actionType'] ?? 'notifyUser',
    actionConfig: Map<String, dynamic>.from(j['actionConfig'] ?? {}),
    status: j['status'] ?? 'active',
    lastRunAt: j['lastRunAt'] != null
        ? DateTime.tryParse(j['lastRunAt'])
        : null,
    nextRunAt: j['nextRunAt'] != null
        ? DateTime.tryParse(j['nextRunAt'])
        : null,
    runCount: j['runCount'] ?? 0,
    failCount: j['failCount'] ?? 0,
    lastError: j['lastError'],
    createdAt: DateTime.tryParse(j['createdAt'] ?? '') ?? DateTime.now(),
  );

  bool get isActive => status == 'active';
  bool get isPaused => status == 'paused';
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final _workflowsProvider = FutureProvider.autoDispose<List<Workflow>>((
  ref,
) async {
  final result = await apiService.getWorkflows();
  return (result['workflows'] as List)
      .map((w) => Workflow.fromJson(w as Map<String, dynamic>))
      .toList();
});

// ─── Screen ───────────────────────────────────────────────────────────────────

class WorkflowsScreen extends ConsumerWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workAsync = ref.watch(_workflowsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: workAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _buildError(context, ref, e.toString()),
        data: (workflows) => _buildBody(context, ref, workflows),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'New Workflow',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, String err) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Failed to load workflows',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(_workflowsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<Workflow> workflows,
  ) {
    if (workflows.isEmpty) {
      return _EmptyState(onTap: () => _showCreateSheet(context, ref));
    }

    final active = workflows.where((w) => w.isActive).toList();
    final paused = workflows.where((w) => w.isPaused).toList();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(_workflowsProvider),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 140, 16, 100),
        children: [
          _SummaryRow(workflows: workflows),
          const SizedBox(height: 20),

          if (active.isNotEmpty) ...[
            _SectionHeader(
              label: 'Active',
              count: active.length,
              color: DayFiColors.green,
            ),
            const SizedBox(height: 8),
            ...active.map(
              (w) => _WorkflowTile(
                workflow: w,
                onTap: () => _showDetailSheet(context, ref, w),
                onToggle: () => _toggleWorkflow(context, ref, w),
              ),
            ),
          ],

          if (paused.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(
              label: 'Paused',
              count: paused.length,
              color: const Color(0xFFFFA726),
            ),
            const SizedBox(height: 8),
            ...paused.map(
              (w) => _WorkflowTile(
                workflow: w,
                onTap: () => _showDetailSheet(context, ref, w),
                onToggle: () => _toggleWorkflow(context, ref, w),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleWorkflow(
    BuildContext context,
    WidgetRef ref,
    Workflow w,
  ) async {
    try {
      if (w.isActive) {
        await apiService.pauseWorkflow(w.id);
      } else {
        await apiService.resumeWorkflow(w.id);
      }
      ref.invalidate(_workflowsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    }
  }

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _CreateWorkflowSheet(
        onCreated: () => ref.invalidate(_workflowsProvider),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, Workflow w) {
    showDayFiBottomSheet(
      context: context,
      isScrollControlled: true,
      child: _WorkflowDetailSheet(
        workflow: w,
        onRefresh: () => ref.invalidate(_workflowsProvider),
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<Workflow> workflows;
  const _SummaryRow({required this.workflows});

  @override
  Widget build(BuildContext context) {
    final active = workflows.where((w) => w.isActive).length;
    final paused = workflows.where((w) => w.isPaused).length;
    final totalRuns = workflows.fold<int>(0, (s, w) => s + w.runCount);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Active',
            value: '$active',
            color: DayFiColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Paused',
            value: '$paused',
            color: const Color(0xFFFFA726),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            label: 'Total Runs',
            value: '$totalRuns',
            color: const Color(0xFF6C47FF),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SectionHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          ),
        ),
      ],
    );
  }
}

// ─── Workflow tile ────────────────────────────────────────────────────────────

class _WorkflowTile extends StatelessWidget {
  final Workflow workflow;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  const _WorkflowTile({
    required this.workflow,
    required this.onTap,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);
    final w = workflow;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: ext.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ext.cardBorder, width: .5),
        ),
        child: Row(
          children: [
            // Trigger icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _triggerIcon(w.triggerType),
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    w.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: ext.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_triggerLabel(w.triggerType)} → ${_actionLabel(w.actionType)}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: ext.secondaryText,
                    ),
                  ),
                  if (w.lastRunAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last run ${DateFormat('MMM d').format(w.lastRunAt!)}',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.35),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Toggle switch
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 44,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: w.isActive
                      ? DayFiColors.green.withOpacity(0.85)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 220),
                  alignment: w.isActive
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _triggerIcon(String t) {
    switch (t) {
      case 'scheduled':
        return Icons.schedule_rounded;
      case 'balanceThreshold':
        return Icons.account_balance_wallet_rounded;
      case 'invoicePaid':
        return Icons.receipt_long_rounded;
      case 'expenseApproved':
        return Icons.check_circle_outline_rounded;
      case 'manualRun':
        return Icons.play_circle_outline_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  String _triggerLabel(String t) {
    switch (t) {
      case 'scheduled':
        return 'Scheduled';
      case 'balanceThreshold':
        return 'Balance low';
      case 'invoicePaid':
        return 'Invoice paid';
      case 'expenseApproved':
        return 'Expense approved';
      case 'manualRun':
        return 'Manual';
      default:
        return t;
    }
  }

  String _actionLabel(String a) {
    switch (a) {
      case 'sendPayment':
        return 'Send payment';
      case 'createInvoice':
        return 'Create invoice';
      case 'sendReminder':
        return 'Send reminder';
      case 'notifyUser':
        return 'Notify';
      case 'flagExpense':
        return 'Flag expense';
      default:
        return a;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onTap;
  const _EmptyState({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_tree_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
          ),
          const SizedBox(height: 6),
          Text(
            'No workflows yet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Automate recurring tasks and payments',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Workflow'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Create workflow sheet ────────────────────────────────────────────────────

class _CreateWorkflowSheet extends ConsumerStatefulWidget {
  final VoidCallback onCreated;
  const _CreateWorkflowSheet({required this.onCreated});

  @override
  ConsumerState<_CreateWorkflowSheet> createState() =>
      _CreateWorkflowSheetState();
}

class _CreateWorkflowSheetState extends ConsumerState<_CreateWorkflowSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _triggerType = 'scheduled';
  String _actionType = 'notifyUser';
  String _interval = 'monthly';
  bool _loading = false;

  // Action config controllers
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  String _asset = 'USDC';

  static const _triggers = [
    ('scheduled', 'Scheduled', Icons.schedule_rounded),
    (
      'balanceThreshold',
      'Balance Threshold',
      Icons.account_balance_wallet_rounded,
    ),
    ('invoicePaid', 'Invoice Paid', Icons.receipt_long_rounded),
    ('expenseApproved', 'Expense Approved', Icons.check_circle_outline_rounded),
    ('manualRun', 'Manual Trigger', Icons.play_circle_outline_rounded),
  ];

  static const _actions = [
    ('sendPayment', 'Send Payment', Icons.send_rounded),
    ('sendReminder', 'Send Reminder', Icons.notifications_rounded),
    ('notifyUser', 'Push Notify', Icons.notification_important_rounded),
    ('createInvoice', 'Create Invoice', Icons.note_add_rounded),
    ('flagExpense', 'Flag Expense', Icons.flag_rounded),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildTriggerConfig() {
    switch (_triggerType) {
      case 'scheduled':
        return {'interval': _interval, 'hour': 9};
      case 'balanceThreshold':
        return {
          'asset': _asset,
          'threshold': double.tryParse(_amountCtrl.text) ?? 10,
        };
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
        'description': _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        'triggerType': _triggerType,
        'triggerConfig': _buildTriggerConfig(),
        'actionType': _actionType,
        'actionConfig': _buildActionConfig(),
      });
      widget.onCreated();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(apiService.parseError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'New Workflow',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: ext.primaryText,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            const _Label('Name'),
            const SizedBox(height: 6),
            _Field(controller: _nameCtrl, hint: 'e.g. Monthly Payroll'),
            const SizedBox(height: 16),

            // Description
            const _Label('Description (optional)'),
            const SizedBox(height: 6),
            _Field(
              controller: _descCtrl,
              hint: 'What does this do?',
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // ── Trigger ──────────────────────────────────────────────
            const _Label('Trigger — when should this run?'),
            const SizedBox(height: 10),
            ..._triggers.map(((String t, String label, IconData icon) item) {
              final selected = _triggerType == item.$1;
              return GestureDetector(
                onTap: () => setState(() => _triggerType = item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.08)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$3,
                        size: 18,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.$2,
                        style: GoogleFonts.outfit(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),

            // Scheduled interval picker
            if (_triggerType == 'scheduled') ...[
              const SizedBox(height: 12),
              const _Label('Repeat every'),
              const SizedBox(height: 8),
              Row(
                children: ['daily', 'weekly', 'monthly'].map((iv) {
                  final sel = _interval == iv;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _interval = iv),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        margin: EdgeInsets.only(right: iv != 'monthly' ? 8 : 0),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.12)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel
                                ? Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.4)
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${iv[0].toUpperCase()}${iv.substring(1)}',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: sel
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // ── Action ───────────────────────────────────────────────
            const _Label('Action — what should happen?'),
            const SizedBox(height: 10),
            ..._actions.map(((String a, String label, IconData icon) item) {
              final selected = _actionType == item.$1;
              return GestureDetector(
                onTap: () => setState(() => _actionType = item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.08)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.$3,
                        size: 18,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.45),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.$2,
                        style: GoogleFonts.outfit(
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (selected)
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            }),

            // Action config fields
            if (_actionType == 'sendPayment') ...[
              const SizedBox(height: 12),
              const _Label('Recipient (DayFi username or Stellar address)'),
              const SizedBox(height: 6),
              _Field(controller: _toCtrl, hint: 'e.g. john@dayfi.me'),
              const SizedBox(height: 12),
              const _Label('Amount'),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _Field(
                      controller: _amountCtrl,
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SegmentPicker(
                    options: const ['USDC', 'NGNT'],
                    selected: _asset,
                    onChanged: (v) => setState(() => _asset = v),
                  ),
                ],
              ),
            ],

            if (_actionType == 'notifyUser' ||
                _actionType == 'sendReminder') ...[
              const SizedBox(height: 12),
              const _Label('Message'),
              const SizedBox(height: 6),
              _Field(
                controller: _msgCtrl,
                hint: 'e.g. Your monthly payment is due',
                maxLines: 2,
              ),
            ],

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Create Workflow',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Workflow detail sheet ────────────────────────────────────────────────────

class _WorkflowDetailSheet extends StatefulWidget {
  final Workflow workflow;
  final VoidCallback onRefresh;
  const _WorkflowDetailSheet({required this.workflow, required this.onRefresh});

  @override
  State<_WorkflowDetailSheet> createState() => _WorkflowDetailSheetState();
}

class _WorkflowDetailSheetState extends State<_WorkflowDetailSheet> {
  bool _running = false;
  bool _toggling = false;
  bool _deleting = false;

  Future<void> _runNow() async {
    setState(() => _running = true);
    try {
      await apiService.runWorkflow(widget.workflow.id);
      widget.onRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Workflow triggered successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  Future<void> _toggle() async {
    setState(() => _toggling = true);
    try {
      if (widget.workflow.isActive) {
        await apiService.pauseWorkflow(widget.workflow.id);
      } else {
        await apiService.resumeWorkflow(widget.workflow.id);
      }
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive workflow?'),
        content: const Text('This workflow will be archived and stop running.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Archive',
              style: TextStyle(color: DayFiColors.red),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _deleting = true);
    try {
      await apiService.deleteWorkflow(widget.workflow.id);
      widget.onRefresh();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiService.parseError(e))));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.workflow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  w.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),

          if (w.description != null && w.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                w.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatChip(
                label: 'Runs',
                value: '${w.runCount}',
                color: const Color(0xFF6C47FF),
              ),
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

          _DetailRow(label: 'Trigger', value: _triggerLabel(w.triggerType)),
          _DetailRow(label: 'Action', value: _actionLabel(w.actionType)),
          if (w.lastRunAt != null)
            _DetailRow(
              label: 'Last run',
              value: DateFormat('MMM d, yyyy HH:mm').format(w.lastRunAt!),
            ),
          if (w.nextRunAt != null)
            _DetailRow(
              label: 'Next run',
              value: DateFormat('MMM d, yyyy HH:mm').format(w.nextRunAt!),
            ),
          if (w.lastError != null)
            _DetailRow(
              label: 'Last error',
              value: w.lastError!,
              isWarning: true,
            ),

          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              // Run now
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _running ? null : _runNow,
                  icon: _running
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    'Run now',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Pause / resume
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: w.isActive
                          ? const Color(0xFFFFA726).withOpacity(0.5)
                          : DayFiColors.green.withOpacity(0.5),
                    ),
                  ),
                  onPressed: _toggling ? null : _toggle,
                  icon: _toggling
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          w.isActive
                              ? Icons.pause_circle_outline_rounded
                              : Icons.play_circle_outline_rounded,
                          size: 18,
                          color: w.isActive
                              ? const Color(0xFFFFA726)
                              : DayFiColors.green,
                        ),
                  label: Text(
                    w.isActive ? 'Pause' : 'Resume',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: w.isActive
                          ? const Color(0xFFFFA726)
                          : DayFiColors.green,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Archive
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 13,
                    horizontal: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: DayFiColors.red.withOpacity(0.4)),
                ),
                onPressed: _deleting ? null : _delete,
                child: _deleting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DayFiColors.red,
                        ),
                      )
                    : const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: DayFiColors.red,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _triggerLabel(String t) {
    const m = {
      'scheduled': 'Scheduled',
      'balanceThreshold': 'Balance Threshold',
      'invoicePaid': 'Invoice Paid',
      'expenseApproved': 'Expense Approved',
      'manualRun': 'Manual',
    };
    return m[t] ?? t;
  }

  String _actionLabel(String a) {
    const m = {
      'sendPayment': 'Send Payment',
      'createInvoice': 'Create Invoice',
      'sendReminder': 'Send Reminder',
      'notifyUser': 'Push Notify',
      'flagExpense': 'Flag Expense',
    };
    return m[a] ?? a;
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool isWarning;
  const _DetailRow({
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: isWarning ? DayFiColors.red : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: GoogleFonts.outfit(
      fontWeight: FontWeight.w500,
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.outfit(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.35),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      ),
    );
  }
}

class _SegmentPicker extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  const _SegmentPicker({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((o) {
        final isSel = o == selected;
        return GestureDetector(
          onTap: () => onChanged(o),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSel
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.4)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              o,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                color: isSel
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
