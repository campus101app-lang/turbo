import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/screens/expenses/expenses_screen.dart';

final selectedExpenseProvider = StateProvider<Expense?>((ref) => null);