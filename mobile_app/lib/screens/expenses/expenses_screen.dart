// lib/screens/expenses/expenses_screen.dart
//
// Features:
//   - Tab 0: "My Expenses" — submissions I created (can edit/delete drafts, submit when ready)
//   - Tab 1: "Pending Approval" — expenses awaiting my approval (manager/merchant only)
//   - Create expense form: title, amount, category, description, receipt upload (optional)
//   - View expense detail with full info + approval/rejection action
//   - Status pills: draft | submitted | approved | rejected

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/services/api_service.dart';

// ─── Expense Model ────────────────────────────────────────────────────────────

class Expense {
  final String id;
  final String title;
  final String? description;
  final double amount;
  final String category;
  final String currency;
  final String status; // draft, submitted, approved, rejected
  final String? receiptUrl;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? approvedAt;
  final Map<String, dynamic>? user;
  final Map<String, dynamic>? approver;

  Expense({
    required this.id,
    required this.title,
    this.description,
    required this.amount,
    required this.category,
    this.currency = 'NGN',
    required this.status,
    this.receiptUrl,
    this.rejectionReason,
    required this.createdAt,
    this.submittedAt,
    this.approvedAt,
    this.user,
    this.approver,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'other',
      currency: json['currency'] ?? 'NGN',
      status: json['status'] ?? 'draft',
      receiptUrl: json['receiptUrl'],
      rejectionReason: json['rejectionReason'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      submittedAt: json['submittedAt'] != null ? DateTime.parse(json['submittedAt']) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      user: json['user'],
      approver: json['approver'],
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────────

final expenseListProvider = FutureProvider.family<List<Expense>, String>((ref, status) async {
  final apiService = ApiService();
  final response = await apiService.getExpenses(
    status: status.isNotEmpty ? status : null,
    limit: 50,
  );
  final expenses = (response['expenses'] as List<dynamic>)
      .map((e) => Expense.fromJson(e as Map<String, dynamic>))
      .toList();
  return expenses;
});

final userInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ApiService();
  return await apiService.getMe();
});

// ─── Expense Screen ───────────────────────────────────────────────────────────

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'My Expenses'),
              Tab(text: 'Pending Approval'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[300],
          ),
          // actions: [
           
          // ],
        ),
        floatingActionButton:  IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.push('/expenses/create'),
            ),
        body: const TabBarView(
          children: [
            _MyExpensesTab(),
            _PendingApprovalTab(),
          ],
        ),
      ),
    );
  }
}

// ─── My Expenses Tab ──────────────────────────────────────────────────────────

class _MyExpensesTab extends ConsumerWidget {
  const _MyExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all my expenses (any status)
    final expensesAsync = ref.watch(expenseListProvider(''));

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: ${err.toString()}', textAlign: TextAlign.center),
      ),
      data: (expenses) {
        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No expenses yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expenses.length,
          itemBuilder: (context, idx) {
            final expense = expenses[idx];
            return _ExpenseCard(
              expense: expense,
              onTap: () => context.push('/expenses/${expense.id}'),
            );
          },
        );
      },
    );
  }
}

// ─── Pending Approval Tab ─────────────────────────────────────────────────────

class _PendingApprovalTab extends ConsumerWidget {
  const _PendingApprovalTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get expenses with status 'submitted'
    final expensesAsync = ref.watch(expenseListProvider('submitted'));
    final userAsync = ref.watch(userInfoProvider);

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, st) => Center(
        child: Text('Error: ${err.toString()}', textAlign: TextAlign.center),
      ),
      data: (expenses) {
        // Show message if user is not merchant/manager
        return userAsync.when(
          data: (user) {
            final isMerchant = user['isMerchant'] ?? false;

            if (!isMerchant) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('You do not have approval permissions'),
                  ],
                ),
              );
            }

            if (expenses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                    const SizedBox(height: 16),
                    const Text('No expenses pending approval'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expenses.length,
              itemBuilder: (context, idx) {
                final expense = expenses[idx];
                return _ExpenseCard(
                  expense: expense,
                  showApprovalActions: true,
                  onTap: () => context.push('/expenses/${expense.id}'),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => const Center(child: Text('Error loading user info')),
        );
      },
    );
  }
}

// ─── Expense Card ─────────────────────────────────────────────────────────────

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final bool showApprovalActions;
  final VoidCallback onTap;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    this.showApprovalActions = false,
  });

  Color _statusColor() {
    switch (expense.status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.category.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₦${expense.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor().withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          expense.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (expense.description != null && expense.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  expense.description!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Submitted: ${expense.submittedAt != null ? _formatDate(expense.submittedAt!) : 'Not yet'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  if (expense.status == 'rejected' && expense.rejectionReason != null)
                    Tooltip(
                      message: expense.rejectionReason!,
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Colors.red[400],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// ─── Create/Edit Expense Screen ───────────────────────────────────────────────

class CreateEditExpenseScreen extends ConsumerStatefulWidget {
  final String? expenseId; // null = create, provided = edit

  const CreateEditExpenseScreen({Key? key, this.expenseId}) : super(key: key);

  @override
  ConsumerState<CreateEditExpenseScreen> createState() =>
      _CreateEditExpenseScreenState();
}

class _CreateEditExpenseScreenState
    extends ConsumerState<CreateEditExpenseScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController amountController;
  String selectedCategory = 'other';
  String selectedCurrency = 'NGN';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController();
    descriptionController = TextEditingController();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    if (amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount is required')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final apiService = ApiService();
      final data = {
        'title': titleController.text,
        'description': descriptionController.text,
        'amount': double.parse(amountController.text),
        'category': selectedCategory,
        'currency': selectedCurrency,
      };

      if (widget.expenseId == null) {
        // Create
        await apiService.createExpense(data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense created')),
        );
      } else {
        // Update — for now using the invoice update method placeholder
        // TODO: implement updateExpense in API service
        await apiService.updateInvoice(widget.expenseId!, data);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated')),
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expenseId == null ? 'New Expense' : 'Edit Expense'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'e.g., Flight to Lagos',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: selectedCurrency,
                  items: const [
                    DropdownMenuItem(value: 'NGN', child: Text('NGN')),
                    DropdownMenuItem(value: 'USD', child: Text('USD')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedCurrency = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Category',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              isExpanded: true,
              value: selectedCategory,
              items: const [
                DropdownMenuItem(value: 'travel', child: Text('Travel')),
                DropdownMenuItem(value: 'meals', child: Text('Meals')),
                DropdownMenuItem(
                  value: 'accommodation',
                  child: Text('Accommodation'),
                ),
                DropdownMenuItem(value: 'equipment', child: Text('Equipment')),
                DropdownMenuItem(value: 'software', child: Text('Software')),
                DropdownMenuItem(value: 'marketing', child: Text('Marketing')),
                DropdownMenuItem(value: 'utilities', child: Text('Utilities')),
                DropdownMenuItem(value: 'salary', child: Text('Salary')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => selectedCategory = val);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Description (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Any additional details...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _saveExpense,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(),
                      )
                    : Text(
                        widget.expenseId == null
                            ? 'Create Expense'
                            : 'Update Expense',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
