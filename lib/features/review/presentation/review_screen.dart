import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_constants.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../expense/models/expense_category.dart';
import '../../expense/models/expense_item.dart';
import '../../expense/providers/expense_provider.dart';
import 'widgets/receipt_preview_dialog.dart';

/// Interactive Review & Editing Screen for scanned receipt data.
class ReviewScreen extends StatefulWidget {
  final ReviewScreenArguments arguments;

  const ReviewScreen({
    super.key,
    required this.arguments,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late ExpenseCategory _selectedCategory;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.arguments.extractedData;

    _merchantController = TextEditingController(text: data.merchantName);
    // Format amount initially
    _amountController = TextEditingController(
      text: data.amount > 0 ? data.amount.toInt().toString() : '',
    );
    _notesController = TextEditingController();
    _selectedDate = data.date;
    _selectedCategory = data.category;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showFullReceipt() {
    showDialog(
      context: context,
      builder: (_) => ReceiptPreviewDialog(
        imagePath: widget.arguments.imagePath,
        rawText: widget.arguments.extractedData.rawText,
      ),
    );
  }

  Future<void> _commitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedAmount = CurrencyFormatter.parseAmount(_amountController.text.trim());
    if (parsedAmount == null || parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid expense amount')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final expenseItem = ExpenseItem(
      merchantName: _merchantController.text.trim(),
      amount: parsedAmount,
      date: _selectedDate,
      category: _selectedCategory,
      receiptImagePath: widget.arguments.imagePath,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final success = await context.read<ExpenseProvider>().addExpense(expenseItem);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${expenseItem.merchantName}" (${CurrencyFormatter.format(expenseItem.amount)})'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.dashboard, (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save expense. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final data = widget.arguments.extractedData;
    final confidencePct = (data.confidenceScore * 100).toInt();

    final hasFile = widget.arguments.imagePath.isNotEmpty &&
        File(widget.arguments.imagePath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _commitExpense,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AI Confidence Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: confidencePct >= 75
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: confidencePct >= 75
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      confidencePct >= 75
                          ? Icons.verified_rounded
                          : Icons.info_outline_rounded,
                      size: 20,
                      color: confidencePct >= 75 ? AppColors.primaryLight : AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Heuristics Confidence: $confidencePct%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: confidencePct >= 75
                                  ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Review the pre-filled fields below before saving.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Scanned Receipt Thumbnail Card
              Card(
                child: InkWell(
                  onTap: _showFullReceipt,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 60,
                            height: 60,
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            child: hasFile
                                ? Image.file(File(widget.arguments.imagePath), fit: BoxFit.cover)
                                : const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.arguments.isSample ? 'Sample Receipt Scanned' : 'Receipt Image Captured',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to inspect & zoom full image',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.zoom_in_rounded, color: AppColors.primaryLight),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Form Section Title
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 12),

              // Merchant Name Field
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Merchant / Store Name',
                  hintText: 'e.g. WinMart+, Highlands Coffee',
                  prefixIcon: Icon(Icons.storefront_rounded),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Merchant name is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Total Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Amount',
                  hintText: 'e.g. 150000',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                  suffixText: AppConstants.defaultCurrencySymbol,
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                textInputAction: TextInputAction.next,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the total amount';
                  }
                  final parsed = CurrencyFormatter.parseAmount(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Enter a positive number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // Date Picker Field
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Transaction Date',
                    prefixIcon: Icon(Icons.calendar_today_rounded),
                    suffixIcon: Icon(Icons.arrow_drop_down_rounded),
                  ),
                  child: Text(
                    DateFormatter.formatWithDay(_selectedDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Category Dropdown Selection
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Expense Category',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ExpenseCategory>(
                    value: _selectedCategory,
                    isDense: true,
                    isExpanded: true,
                    onChanged: (cat) {
                      if (cat != null) setState(() => _selectedCategory = cat);
                    },
                    items: ExpenseCategory.values.map((cat) {
                      return DropdownMenuItem<ExpenseCategory>(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(cat.icon, size: 18, color: cat.color),
                            const SizedBox(width: 8),
                            Text(cat.displayName),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Notes / Memo Field (Optional)
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes / Items (Optional)',
                  hintText: 'e.g. Grocery trip, Study group',
                  prefixIcon: Icon(Icons.note_alt_rounded),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              // Collapsible Raw OCR text for audit / inspection
              Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    'View Raw OCR Output',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  leading: const Icon(Icons.code_rounded, size: 20),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        data.rawText.isNotEmpty ? data.rawText : 'No OCR text available.',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Commit Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _commitExpense,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded),
                  label: Text(_isSaving ? 'Saving to Database...' : 'Commit to Database'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Discard / Retake Button
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Rescan / Discard'),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
