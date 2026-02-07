import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class TransactionExportService {
  static Future<File?> generateTransactionsPDF({
    required List<Map<String, dynamic>> transactions,
    required String userName,
    required String currencySymbol,
  }) async {
    try {
      final pdf = pw.Document();
      
      final dateFormat = DateFormat('MMM dd, yyyy HH:mm');
      final now = DateTime.now();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GIGA',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.red800,
                    ),
                  ),
                  pw.Text(
                    'Transaction History',
                    style: pw.TextStyle(
                      fontSize: 16,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Account: $userName', style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Generated: ${DateFormat('MMM dd, yyyy').format(now)}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          build: (context) => [
            // Table Header
            pw.Container(
              color: PdfColors.grey200,
              padding: const pw.EdgeInsets.all(10),
              child: pw.Row(
                children: [
                  pw.Expanded(flex: 2, child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  pw.Expanded(flex: 3, child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  pw.Expanded(flex: 1, child: pw.Text('Type', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                  pw.Expanded(flex: 2, child: pw.Text('Amount', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
                ],
              ),
            ),
            
            // Transaction Rows
            ...transactions.asMap().entries.map((entry) {
              final tx = entry.value;
              final index = entry.key;
              final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
              final isCredit = tx['type'] == 'credit' || amount > 0;
              
              String dateStr = 'N/A';
              if (tx['created_at'] is String) {
                try {
                  dateStr = dateFormat.format(DateTime.parse(tx['created_at']));
                } catch (_) {}
              }
              
              return pw.Container(
                color: index % 2 == 0 ? PdfColors.white : PdfColors.grey50,
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: pw.Row(
                  children: [
                    pw.Expanded(flex: 2, child: pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(flex: 3, child: pw.Text(tx['description'] ?? 'Transaction', style: const pw.TextStyle(fontSize: 10))),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: pw.BoxDecoration(
                          color: isCredit ? PdfColors.green100 : PdfColors.red100,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          isCredit ? 'CR' : 'DR',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: isCredit ? PdfColors.green800 : PdfColors.red800,
                          ),
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        '${isCredit ? '+' : ''}$currencySymbol${amount.abs().toStringAsFixed(2)}',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: isCredit ? PdfColors.green700 : PdfColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            // Summary
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Transactions: ${transactions.length}', style: const pw.TextStyle(fontSize: 11)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Total Credits: $currencySymbol${_calculateTotal(transactions, true).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.green700),
                    ),
                    pw.Text(
                      'Total Debits: $currencySymbol${_calculateTotal(transactions, false).toStringAsFixed(2)}',
                      style: pw.TextStyle(fontSize: 11, color: PdfColors.red700),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/giga_transactions_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf');
      await file.writeAsBytes(await pdf.save());
      
      return file;
    } catch (e) {
      debugPrint('PDF Generation Error: $e');
      return null;
    }
  }
  
  static double _calculateTotal(List<Map<String, dynamic>> transactions, bool credits) {
    double total = 0;
    for (var tx in transactions) {
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final isCredit = tx['type'] == 'credit' || amount > 0;
      if (credits && isCredit) {
        total += amount.abs();
      } else if (!credits && !isCredit) {
        total += amount.abs();
      }
    }
    return total;
  }
  
  static Future<void> shareTransactions({
    required List<Map<String, dynamic>> transactions,
    required String userName,
    required String currencySymbol,
  }) async {
    final file = await generateTransactionsPDF(
      transactions: transactions,
      userName: userName,
      currencySymbol: currencySymbol,
    );
    
    if (file != null) {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Giga Transaction History',
        text: 'My Giga wallet transaction history',
      );
    }
  }
  
  static String generateTextSummary({
    required List<Map<String, dynamic>> transactions,
    required String currencySymbol,
  }) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final buffer = StringBuffer();
    
    buffer.writeln('GIGA - Transaction History');
    buffer.writeln('Generated: ${dateFormat.format(DateTime.now())}');
    buffer.writeln('=' * 40);
    buffer.writeln();
    
    for (var tx in transactions) {
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final isCredit = tx['type'] == 'credit' || amount > 0;
      
      String dateStr = 'N/A';
      if (tx['created_at'] is String) {
        try {
          dateStr = DateFormat('MMM dd').format(DateTime.parse(tx['created_at']));
        } catch (_) {}
      }
      
      buffer.writeln('$dateStr | ${tx['description'] ?? 'Transaction'}');
      buffer.writeln('${isCredit ? '+' : ''}$currencySymbol${amount.abs().toStringAsFixed(2)}');
      buffer.writeln('-' * 40);
    }
    
    return buffer.toString();
  }
}
