import 'package:diohub/common/bottom_sheet/bottom_sheets.dart';
import 'package:diohub/style/app_spacing.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/issue_field.dart';
import 'package:flutter/material.dart';

/// Bottom sheet to pick a value for a single-select issue field.
/// Returns the selected option ID.
class IssueFieldPickerSheet {
  IssueFieldPickerSheet._();

  /// Shows the sheet. On success, returns the selected option ID.
  static Future<String?> show(
    BuildContext context, {
    required IssueRef issueRef,
    required IssueFieldDef fieldDef,
    IssueFieldValue? currentValue,
  }) async {
    return await AppSheet.actions<String>(
      context,
      header: AppSheetHeader.text(
        'Select ${fieldDef.name}',
        subtitle: fieldDef.description != null
            ? Text(
                fieldDef.description!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              )
            : null,
      ),
      actions: (ctx) {
        final options = fieldDef.options ?? [];
        final currentOptionId = currentValue?.selectedOption?.id;

        return [
          // "Clear" action
          if (currentValue != null)
            SheetAction(
              title: const Text('Clear'),
              leading: const Icon(Icons.clear, size: 20),
              onPressed: () => Navigator.of(ctx).pop('__clear__'),
            ),
          // Option actions
          ...options.map((option) {
            final bool isSelected = option.id == currentOptionId;
            return SheetAction(
              title: Text(option.name),
              leading: isSelected
                  ? Icon(
                      Icons.check_circle,
                      size: 20,
                      color: Theme.of(ctx).colorScheme.primary,
                    )
                  : const Icon(Icons.radio_button_unchecked, size: 20),
              trailing: option.color != null && option.color!.isNotEmpty
                  ? Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Color(
                          int.tryParse(
                                '0xFF${option.color!.replaceAll('#', '')}',
                              ) ??
                              0xFF888888,
                        ),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
              onPressed: () => Navigator.of(ctx).pop(option.id),
            );
          }),
        ];
      },
    );
  }
}

class IssueFieldTextSheet {
  IssueFieldTextSheet._();

  /// Shows the sheet. On success, returns the entered text or '__clear__' to clear.
  static Future<String?> show(
    BuildContext context, {
    required IssueRef issueRef,
    required IssueFieldDef fieldDef,
    IssueFieldValue? currentValue,
  }) async {
    final controller = TextEditingController(text: currentValue?.value ?? '');
    return await AppSheet.form<String>(
      context,
      header: AppSheetHeader.text('Edit ${fieldDef.name}'),
      bodyBuilder: (ctx, setState) {
        return Padding(
          padding: ctx.spacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: fieldDef.dataType == IssueFieldDataType.number
                    ? TextInputType.number
                    : TextInputType.text,
                decoration: InputDecoration(
                  hintText: fieldDef.description ?? 'Enter value',
                  border: const OutlineInputBorder(),
                ),
              ),
              ctx.spacing.itemGap,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentValue != null)
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop('__clear__'),
                      child: const Text('Clear'),
                    ),
                  ctx.spacing.compactGap,
                  ElevatedButton(
                    onPressed: () {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        Navigator.of(ctx).pop('__clear__');
                      } else {
                        Navigator.of(ctx).pop(value);
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class IssueFieldDateSheet {
  IssueFieldDateSheet._();

  /// Shows the sheet. On success, returns the date as ISO8601 or '__clear__' to clear.
  static Future<String?> show(
    BuildContext context, {
    required IssueRef issueRef,
    required IssueFieldDef fieldDef,
    IssueFieldValue? currentValue,
  }) async {
    DateTime? selectedDate;
    if (currentValue?.value != null) {
      try {
        selectedDate = DateTime.parse(currentValue!.value!);
      } catch (_) {
        // Invalid date, start with no selection
      }
    }

    return await AppSheet.form<String>(
      context,
      header: AppSheetHeader.text('Select ${fieldDef.name}'),
      bodyBuilder: (ctx, setState) {
        return Padding(
          padding: ctx.spacing.screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(ctx).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      ctx.spacing.compactGap,
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select date',
                      ),
                    ],
                  ),
                ),
              ),
              ctx.spacing.itemGap,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (currentValue != null)
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop('__clear__'),
                      child: const Text('Clear'),
                    ),
                  ctx.spacing.compactGap,
                  ElevatedButton(
                    onPressed: () {
                      if (selectedDate != null) {
                        Navigator.of(ctx).pop(selectedDate!.toIso8601String());
                      } else {
                        Navigator.of(ctx).pop('__clear__');
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
