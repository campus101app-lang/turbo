// lib/screens/workflows/workflows_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/selected_workflow_provider.dart';
import '../../providers/shell_navigation_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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

        floatingActionButton: Container(
        height: 60,
        width: 60,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
        ),
        child: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
          onTap: () => _showCreateSheet(context, ref),
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.add,
              size: 22,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
            ),
          ),
        ),
      ).animate().fadeIn(delay: 10.ms).slideY(begin: 0.1, end: 0),
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
      return _EmptyState(
        onTap: () => _showCreateSheet(context, ref),
        onTemplateTap: () => _showTemplatesSheet(context, ref),
      );
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
    ref.read(shellNavProvider.notifier).goTo(ShellDest.createWorkflow);
  }

  void _showTemplatesSheet(BuildContext context, WidgetRef ref) {
    ref.read(shellNavProvider.notifier).goTo(ShellDest.createWorkflow);
  }

  void _showDetailSheet(BuildContext context, WidgetRef ref, Workflow w) {
    ref.read(selectedWorkflowProvider.notifier).state = w;
    ref.read(shellNavProvider.notifier).goTo(ShellDest.workflowDetail);
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
            style: GoogleFonts.bricolageGrotesque(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
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
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: GoogleFonts.bricolageGrotesque(
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
                color: Theme.of(context).colorScheme.surface,
                          
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          , width: .5),
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
                    style: GoogleFonts.bricolageGrotesque(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_triggerLabel(w.triggerType)} → ${_actionLabel(w.actionType)}',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 12,
                      color: ext.secondaryText,
                    ),
                  ),
                  if (w.lastRunAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last run ${DateFormat('MMM d').format(w.lastRunAt!)}',
                      style: GoogleFonts.bricolageGrotesque(
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
      // case 'createInvoice':
        //   return 'Create invoice'; // Blocked by backend
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
  final VoidCallback onTemplateTap;
  const _EmptyState({required this.onTap, required this.onTemplateTap});

  @override
  Widget build(BuildContext context) {
    final ext = AppThemeExtension.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Stack(
            children: [
              Center(
                child: Container(
                  height: 54,
                  width: MediaQuery.of(context).size.width * .85,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          .withValues(alpha: 0.5),
                      width: 1,
                    ),
                    color: ext.monthlyCardSurface,
                  ),
                ),
              ),

              Container(
                margin: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.04)
                          , width: .5),
                        color: Theme.of(context).colorScheme.surface,
                          
                ),
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'automate recurring tasks and payments',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: .4,
                        color: ext.sectionHeader,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Theme.of(
                                context,
                              ).textTheme.bodySmall!.color!.withOpacity(0.1),
                              foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: onTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'CREATE',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  height: 1,
                                  color: ext.sectionHeader,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: Theme.of(
                                context,
                              ).textTheme.bodySmall!.color!.withOpacity(0.1),
                              foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.555)
                          ,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: onTemplateTap,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 15, 0, 15),
                              child: Text(
                                'TEMPLATES',
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .2,
                                  height: 1,
                                  color: ext.sectionHeader,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Template model ──────────────────────────────────────────────────────────

class WorkflowTemplate {
  final String name;
  final String description;
  final IconData icon;
  final String triggerType;
  final String actionType;
  final String interval;

  const WorkflowTemplate({
    required this.name,
    required this.description,
    required this.icon,
    required this.triggerType,
    required this.actionType,
    this.interval = 'monthly',
  });
}

const kWorkflowTemplates = [
  WorkflowTemplate(
    name: 'Weekly Payment Reminder',
    description: 'Remind clients about outstanding invoices every week',
    icon: Icons.notifications_active_rounded,
    triggerType: 'scheduled',
    actionType: 'sendReminder',
    interval: 'weekly',
  ),
  WorkflowTemplate(
    name: 'Monthly Payroll',
    description: 'Send salary payments automatically every month',
    icon: Icons.people_rounded,
    triggerType: 'scheduled',
    actionType: 'sendPayment',
    interval: 'monthly',
  ),
  WorkflowTemplate(
    name: 'Low Balance Alert',
    description: 'Get notified when your wallet balance drops too low',
    icon: Icons.account_balance_wallet_rounded,
    triggerType: 'balanceThreshold',
    actionType: 'notifyUser',
  ),
  WorkflowTemplate(
    name: 'Auto-flag Overdue Invoices',
    description: 'Flag expenses automatically when an invoice is paid',
    icon: Icons.flag_rounded,
    triggerType: 'invoicePaid',
    actionType: 'flagExpense',
  ),
  WorkflowTemplate(
    name: 'Daily Summary',
    description: 'Receive a daily push notification with your finance summary',
    icon: Icons.summarize_rounded,
    triggerType: 'scheduled',
    actionType: 'notifyUser',
    interval: 'daily',
  ),
];

