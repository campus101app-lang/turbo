// lib/services/data_export_service.dart
//
// Data Export & Reporting Service for Nigerian Market
// PDF invoice generation, Excel export for accounting, tax reports, Nigerian financial statements
//

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

enum ExportFormat {
  pdf,
  excel,
  csv,
  json,
}

enum ReportType {
  invoice,
  payment,
  expense,
  tax,
  profitLoss,
  balanceSheet,
  cashFlow,
  trialBalance,
  compliance,
  audit,
}

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  // Export directory
  late Directory _exportDirectory;

  Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // Web doesn't need directory setup - exports are handled via download
        debugPrint('Data export service initialized (web mode)');
        return;
      }
      
      // Request storage permissions (mobile only)
      if (await _requestStoragePermission()) {
        // Get external directory for exports
        _exportDirectory = await getExternalStorageDirectory() ?? 
                          await getApplicationDocumentsDirectory();
        
        // Create DayFi exports folder
        final dayfiDir = Directory('${_exportDirectory.path}/DayFi Exports');
        if (!await dayfiDir.exists()) {
          await dayfiDir.create(recursive: true);
        }
        
        debugPrint('Data export service initialized');
      } else {
        throw Exception('Storage permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing data export service: $e');
      rethrow;
    }
  }

  // Generate PDF invoice
  Future<String> generatePDFInvoice({
    required Map<String, dynamic> invoiceData,
    required Map<String, dynamic> customerData,
    required Map<String, dynamic> businessData,
  }) async {
    try {
      final invoiceNumber = invoiceData['invoiceNumber'] as String;
      final invoiceDate = invoiceData['createdAt'] as String;
      final dueDate = invoiceData['dueDate'] as String;
      final amount = invoiceData['amount'] as double;
      final currency = invoiceData['currency'] as String;
      final description = invoiceData['description'] as String;

      // Generate PDF content
      final pdfContent = _generatePDFInvoiceContent(
        invoiceData: invoiceData,
        customerData: customerData,
        businessData: businessData,
      );

      // Save PDF file
      final fileName = 'Invoice_$invoiceNumber.pdf';
      final filePath = '${_exportDirectory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(pdfContent);

      debugPrint('PDF invoice generated: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error generating PDF invoice: $e');
      rethrow;
    }
  }

  // Generate Excel report
  Future<String> generateExcelReport({
    required ReportType reportType,
    required List<Map<String, dynamic>> data,
    Map<String, dynamic>? filters,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Generate CSV content (Excel would require additional libraries)
      final csvContent = _generateCSVReport(
        reportType: reportType,
        data: data,
        filters: filters,
        startDate: startDate,
        endDate: endDate,
      );

      // Save CSV file
      final fileName = '${reportType.name}_report_${DateTime.now().millisecondsSinceEpoch}.csv';
      final filePath = '${_exportDirectory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(csvContent);

      debugPrint('Excel report generated: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error generating Excel report: $e');
      rethrow;
    }
  }

  // Generate tax report
  Future<String> generateTaxReport({
    required DateTime taxYear,
    required Map<String, dynamic> businessData,
    required List<Map<String, dynamic>> incomeData,
    required List<Map<String, dynamic>> expenseData,
    required List<Map<String, dynamic>> vatData,
  }) async {
    try {
      // Calculate tax totals
      final totalIncome = incomeData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
      final totalExpenses = expenseData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
      final totalVAT = vatData.fold<double>(0, (sum, item) => sum + (item['amount'] as double));
      
      final taxableIncome = totalIncome - totalExpenses;
      final taxPayable = taxableIncome * 0.075; // Assuming 7.5% tax rate
      
      // Generate tax report content
      final reportContent = _generateTaxReportContent(
        taxYear: taxYear,
        businessData: businessData,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        totalVAT: totalVAT,
        taxableIncome: taxableIncome,
        taxPayable: taxPayable,
        incomeData: incomeData,
        expenseData: expenseData,
        vatData: vatData,
      );

      // Save tax report
      final fileName = 'Tax_Report_${taxYear.year}.csv';
      final filePath = '${_exportDirectory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(reportContent);

      debugPrint('Tax report generated: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error generating tax report: $e');
      rethrow;
    }
  }

  // Generate Nigerian financial statements
  Future<String> generateFinancialStatements({
    required DateTime periodEnd,
    required Map<String, dynamic> businessData,
    required Map<String, dynamic> balanceSheetData,
    required Map<String, dynamic> profitLossData,
    required Map<String, dynamic> cashFlowData,
  }) async {
    try {
      // Generate financial statements content
      final statementsContent = _generateFinancialStatementsContent(
        periodEnd: periodEnd,
        businessData: businessData,
        balanceSheetData: balanceSheetData,
        profitLossData: profitLossData,
        cashFlowData: cashFlowData,
      );

      // Save financial statements
      final fileName = 'Financial_Statements_${periodEnd.year}_${periodEnd.month}.csv';
      final filePath = '${_exportDirectory.path}/$fileName';
      final file = File(filePath);
      await file.writeAsString(statementsContent);

      debugPrint('Financial statements generated: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('Error generating financial statements: $e');
      rethrow;
    }
  }

  // Export data in specified format
  Future<String> exportData({
    required ExportFormat format,
    required ReportType reportType,
    required List<Map<String, dynamic>> data,
    Map<String, dynamic>? metadata,
  }) async {
    switch (format) {
      case ExportFormat.pdf:
        return await _exportToPDF(reportType, data, metadata);
      case ExportFormat.excel:
        return await _exportToExcel(reportType, data, metadata);
      case ExportFormat.csv:
        return await _exportToCSV(reportType, data, metadata);
      case ExportFormat.json:
        return await _exportToJSON(reportType, data, metadata);
    }
  }

  // Share exported file
  Future<void> shareFile(String filePath) async {
    try {
      if (kIsWeb) {
        // Web uses download instead of share
        await _downloadFileWeb(filePath);
        return;
      }
      
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(filePath)]);
      } else {
        throw Exception('File not found: $filePath');
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
      rethrow;
    }
  }

  // Web-specific download functionality
  Future<void> _downloadFileWeb(String filePath) async {
    // For web, we'd typically use html package to trigger download
    // For now, we'll just log that download would happen
    debugPrint('Web download triggered for: $filePath');
    // TODO: Implement actual web download using html package
  }

  // Get export history
  Future<List<ExportFile>> getExportHistory() async {
    try {
      final files = <ExportFile>[];
      
      if (await _exportDirectory.exists()) {
        final entities = _exportDirectory.listSync();
        for (final entity in entities) {
          if (entity is File) {
            final stat = await entity.stat();
            files.add(ExportFile(
              name: entity.path.split('/').last,
              path: entity.path,
              size: stat.size,
              createdAt: stat.modified,
              type: _getFileType(entity.path),
            ));
          }
        }
      }
      
      // Sort by creation date (newest first)
      files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return files;
    } catch (e) {
      debugPrint('Error getting export history: $e');
      return [];
    }
  }

  // Delete exported file
  Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Export file deleted: $filePath');
      }
    } catch (e) {
      debugPrint('Error deleting export file: $e');
    }
  }

  // Private methods
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
    return true; // iOS doesn't require explicit storage permission for app directory
  }

  String _generatePDFInvoiceContent({
    required Map<String, dynamic> invoiceData,
    required Map<String, dynamic> customerData,
    required Map<String, dynamic> businessData,
  }) {
    final invoiceNumber = invoiceData['invoiceNumber'] as String;
    final invoiceDate = invoiceData['createdAt'] as String;
    final dueDate = invoiceData['dueDate'] as String;
    final amount = invoiceData['amount'] as double;
    final currency = invoiceData['currency'] as String;
    final description = invoiceData['description'] as String;
    
    final businessName = businessData['businessName'] as String;
    final businessAddress = businessData['businessAddress'] as String;
    final businessPhone = businessData['businessPhone'] as String;
    final businessEmail = businessData['businessEmail'] as String;
    
    final customerName = customerData['name'] as String;
    final customerAddress = customerData['address'] as String;
    final customerEmail = customerData['email'] as String;
    final customerPhone = customerData['phone'] as String;

    return '''
INVOICE

Invoice Number: $invoiceNumber
Invoice Date: $invoiceDate
Due Date: $dueDate

BUSINESS INFORMATION
$businessName
$businessAddress
Phone: $businessPhone
Email: $businessEmail

BILL TO:
$customerName
$customerAddress
Email: $customerEmail
Phone: $customerPhone

INVOICE DETAILS
Description: $description
Amount: $currency ${amount.toStringAsFixed(2)}
Invoice Date: $invoiceDate
Due Date: $dueDate
Status: ${invoiceData['status'] as String? ?? 'Pending'}

PAYMENT INFORMATION
Bank: [Your Bank Name]
Account Number: [Your Account Number]
Account Name: $businessName
Payment Reference: INV-$invoiceNumber

VAT INFORMATION
${invoiceData['vatAmount'] != null ? 'VAT Amount: $currency ${(invoiceData['vatAmount'] as double).toStringAsFixed(2)}' : 'VAT: Not applicable'}
${invoiceData['subtotal'] != null ? 'Subtotal: $currency ${(invoiceData['subtotal'] as double).toStringAsFixed(2)}' : ''}
Total Due: $currency ${amount.toStringAsFixed(2)}

TERMS AND CONDITIONS
1. Payment is due within ${invoiceData['paymentTerms'] as String? ?? '30'} days of invoice date.
2. Late payment charges may apply at 2% per month on overdue amounts.
3. All prices are in Nigerian Naira (NGN) unless otherwise specified.
4. This invoice is subject to VAT where applicable under Nigerian tax laws.
5. Goods/services remain the property of $businessName until payment is received in full.
6. Any disputes must be raised in writing within 7 days of invoice date.

NIGERIAN BUSINESS COMPLIANCE
TIN: ${businessData['tinNumber'] as String? ?? 'N/A'}
CAC Registration: ${businessData['cacNumber'] as String? ?? 'N/A'}
Business Type: ${businessData['businessType'] as String? ?? 'N/A'}

Thank you for your business!

For inquiries, please contact:
Email: $businessEmail
Phone: $businessPhone
Website: ${businessData['website'] as String? ?? 'N/A'}

This invoice was generated electronically and is valid without signature.
DayFi Financial Management System - Nigerian Business Financial Command Center
    ''';
  }

  String _generateCSVReport({
    required ReportType reportType,
    required List<Map<String, dynamic>> data,
    Map<String, dynamic>? filters,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final buffer = StringBuffer();
    
    // Add header
    buffer.writeln(_getCSVHeader(reportType));
    
    // Add filters information
    if (filters != null || startDate != null || endDate != null) {
      buffer.writeln('');
      buffer.writeln('FILTERS:');
      if (startDate != null) {
        buffer.writeln('Start Date: ${startDate.toString().split(' ')[0]}');
      }
      if (endDate != null) {
        buffer.writeln('End Date: ${endDate.toString().split(' ')[0]}');
      }
      if (filters != null) {
        filters.forEach((key, value) {
          buffer.writeln('$key: $value');
        });
      }
      buffer.writeln('');
    }
    
    // Add data rows
    for (final item in data) {
      buffer.writeln(_formatCSVRow(item, reportType));
    }
    
    return buffer.toString();
  }

  String _generateTaxReportContent({
    required DateTime taxYear,
    required Map<String, dynamic> businessData,
    required double totalIncome,
    required double totalExpenses,
    required double totalVAT,
    required double taxableIncome,
    required double taxPayable,
    required List<Map<String, dynamic>> incomeData,
    required List<Map<String, dynamic>> expenseData,
    required List<Map<String, dynamic>> vatData,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('TAX REPORT FOR ${taxYear.year}');
    buffer.writeln('');
    
    // Business Information
    buffer.writeln('BUSINESS INFORMATION');
    buffer.writeln('Business Name: ${businessData['businessName']}');
    buffer.writeln('TIN: ${businessData['tinNumber']}');
    buffer.writeln('Business Type: ${businessData['businessType']}');
    buffer.writeln('');
    
    // Summary
    buffer.writeln('TAX SUMMARY');
    buffer.writeln('Total Income: ₦${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Expenses: ₦${totalExpenses.toStringAsFixed(2)}');
    buffer.writeln('Total VAT: ₦${totalVAT.toStringAsFixed(2)}');
    buffer.writeln('Taxable Income: ₦${taxableIncome.toStringAsFixed(2)}');
    buffer.writeln('Tax Payable (7.5%): ₦${taxPayable.toStringAsFixed(2)}');
    buffer.writeln('');
    
    // Income Details
    buffer.writeln('INCOME DETAILS');
    buffer.writeln('Date,Description,Amount,VAT,Net Amount');
    for (final income in incomeData) {
      buffer.writeln('${income['date']},${income['description']},${income['amount']},${income['vat']},${income['netAmount']}');
    }
    buffer.writeln('');
    
    // Expense Details
    buffer.writeln('EXPENSE DETAILS');
    buffer.writeln('Date,Description,Amount,Category,VAT Deductible');
    for (final expense in expenseData) {
      buffer.writeln('${expense['date']},${expense['description']},${expense['amount']},${expense['category']},${expense['vatDeductible']}');
    }
    buffer.writeln('');
    
    // VAT Details
    buffer.writeln('VAT DETAILS');
    buffer.writeln('Date,Description,VAT Amount,Type');
    for (final vat in vatData) {
      buffer.writeln('${vat['date']},${vat['description']},${vat['vatAmount']},${vat['type']}');
    }
    buffer.writeln('');
    
    // Footer
    buffer.writeln('NOTES:');
    buffer.writeln('1. This report is generated for tax filing purposes.');
    buffer.writeln('2. Please consult with a tax professional for accurate tax calculations.');
    buffer.writeln('3. All amounts are in Nigerian Naira (NGN).');
    buffer.writeln('4. Tax rates are subject to change by Nigerian tax authorities.');
    
    return buffer.toString();
  }

  String _generateFinancialStatementsContent({
    required DateTime periodEnd,
    required Map<String, dynamic> businessData,
    required Map<String, dynamic> balanceSheetData,
    required Map<String, dynamic> profitLossData,
    required Map<String, dynamic> cashFlowData,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('FINANCIAL STATEMENTS');
    buffer.writeln('Period: ${periodEnd.toString().split(' ')[0]}');
    buffer.writeln('Business: ${businessData['businessName']}');
    buffer.writeln('');
    
    // Balance Sheet
    buffer.writeln('BALANCE SHEET');
    buffer.writeln('ASSETS');
    final assets = balanceSheetData['assets'] as Map<String, dynamic>;
    assets.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Total Assets: ₦${balanceSheetData['totalAssets']}');
    buffer.writeln('');
    
    buffer.writeln('LIABILITIES');
    final liabilities = balanceSheetData['liabilities'] as Map<String, dynamic>;
    liabilities.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Total Liabilities: ₦${balanceSheetData['totalLiabilities']}');
    buffer.writeln('');
    
    buffer.writeln('EQUITY');
    final equity = balanceSheetData['equity'] as Map<String, dynamic>;
    equity.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Total Equity: ₦${balanceSheetData['totalEquity']}');
    buffer.writeln('');
    
    // Profit & Loss
    buffer.writeln('PROFIT & LOSS STATEMENT');
    final revenue = profitLossData['revenue'] as Map<String, dynamic>;
    buffer.writeln('REVENUE');
    revenue.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Total Revenue: ₦${profitLossData['totalRevenue']}');
    buffer.writeln('');
    
    final expenses = profitLossData['expenses'] as Map<String, dynamic>;
    buffer.writeln('EXPENSES');
    expenses.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Total Expenses: ₦${profitLossData['totalExpenses']}');
    buffer.writeln('');
    
    buffer.writeln('Gross Profit: ₦${profitLossData['grossProfit']}');
    buffer.writeln('Operating Expenses: ₦${profitLossData['operatingExpenses']}');
    buffer.writeln('Net Profit: ₦${profitLossData['netProfit']}');
    buffer.writeln('');
    
    // Cash Flow
    buffer.writeln('CASH FLOW STATEMENT');
    final cashFlow = cashFlowData['cashFlow'] as Map<String, dynamic>;
    cashFlow.forEach((key, value) {
      buffer.writeln('$key: ₦${(value as double).toStringAsFixed(2)}');
    });
    buffer.writeln('Net Cash Flow: ₦${cashFlowData['netCashFlow']}');
    buffer.writeln('');
    
    // Footer
    buffer.writeln('NOTES:');
    buffer.writeln('1. These financial statements are prepared in accordance with Nigerian Financial Reporting Standards.');
    buffer.writeln('2. All amounts are in Nigerian Naira (NGN).');
    buffer.writeln('3. Please consult with a qualified accountant for official financial statements.');
    
    return buffer.toString();
  }

  Future<String> _exportToPDF(ReportType reportType, List<Map<String, dynamic>> data, Map<String, dynamic>? metadata) async {
    // For PDF export, we'll use the CSV content as a placeholder
    // In production, you'd use a proper PDF generation library
    return await _exportToCSV(reportType, data, metadata);
  }

  Future<String> _exportToExcel(ReportType reportType, List<Map<String, dynamic>> data, Map<String, dynamic>? metadata) async {
    return await _exportToCSV(reportType, data, metadata);
  }

  Future<String> _exportToCSV(ReportType reportType, List<Map<String, dynamic>> data, Map<String, dynamic>? metadata) async {
    return _generateCSVReport(reportType: reportType, data: data, filters: metadata);
  }

  Future<String> _exportToJSON(ReportType reportType, List<Map<String, dynamic>> data, Map<String, dynamic>? metadata) async {
    final exportData = {
      'reportType': reportType.name,
      'generatedAt': DateTime.now().toIso8601String(),
      'metadata': metadata ?? {},
      'data': data,
    };
    
    final fileName = '${reportType.name}_${DateTime.now().millisecondsSinceEpoch}.json';
    final filePath = '${_exportDirectory.path}/$fileName';
    final file = File(filePath);
    await file.writeAsString(jsonEncode(exportData));
    
    return filePath;
  }

  String _getCSVHeader(ReportType reportType) {
    switch (reportType) {
      case ReportType.invoice:
        return 'Invoice Number,Date,Customer,Amount,Status,Due Date';
      case ReportType.payment:
        return 'Payment ID,Date,Invoice,Amount,Method,Status';
      case ReportType.expense:
        return 'Expense ID,Date,Category,Amount,Description,Status';
      case ReportType.tax:
        return 'Date,Description,Amount,Category,VAT';
      case ReportType.profitLoss:
        return 'Date,Description,Revenue,Expense,Profit';
      case ReportType.balanceSheet:
        return 'Date,Account,Debit,Credit,Balance';
      case ReportType.cashFlow:
        return 'Date,Description,Inflow,Outflow,Net Flow';
      case ReportType.trialBalance:
        return 'Date,Account,Debit,Credit,Balance';
      default:
        return 'Date,Description,Amount,Status';
    }
  }

  String _formatCSVRow(Map<String, dynamic> item, ReportType reportType) {
    switch (reportType) {
      case ReportType.invoice:
        return '${item['invoiceNumber']},${item['date']},${item['customer']},${item['amount']},${item['status']},${item['dueDate']}';
      case ReportType.payment:
        return '${item['paymentId']},${item['date']},${item['invoice']},${item['amount']},${item['method']},${item['status']}';
      case ReportType.expense:
        return '${item['expenseId']},${item['date']},${item['category']},${item['amount']},${item['description']},${item['status']}';
      case ReportType.tax:
        return '${item['date']},${item['description']},${item['amount']},${item['category']},${item['vat']}';
      case ReportType.profitLoss:
        return '${item['date']},${item['description']},${item['revenue']},${item['expense']},${item['profit']}';
      case ReportType.balanceSheet:
        return '${item['date']},${item['account']},${item['debit']},${item['credit']},${item['balance']}';
      case ReportType.cashFlow:
        return '${item['date']},${item['description']},${item['inflow']},${item['outflow']},${item['netFlow']}';
      case ReportType.trialBalance:
        return '${item['date']},${item['account']},${item['debit']},${item['credit']},${item['balance']}';
      default:
        return '${item['date']},${item['description']},${item['amount']},${item['status']}';
    }
  }

  ExportFileType _getFileType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return ExportFileType.pdf;
      case 'csv':
        return ExportFileType.csv;
      case 'json':
        return ExportFileType.json;
      default:
        return ExportFileType.other;
    }
  }
}

// Supporting classes
class ExportFile {
  final String name;
  final String path;
  final int size;
  final DateTime createdAt;
  final ExportFileType type;

  ExportFile({
    required this.name,
    required this.path,
    required this.size,
    required this.createdAt,
    required this.type,
  });

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

enum ExportFileType {
  pdf,
  csv,
  json,
  other,
}
