import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'common.dart';

/// Asks for one number, e.g. a weigh-in. Returns null if cancelled.
Future<double?> askNumber(
  BuildContext context, {
  required String title,
  required String unit,
  double? initial,
  double min = 0,
  double max = 1000,
  int decimals = 1,
}) {
  final ctrl = TextEditingController(
    text: initial == null ? '' : initial.toStringAsFixed(decimals),
  );
  String? error;
  return showDialog<double>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(title, style: T.display(22)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: T.display(28),
          decoration: InputDecoration(suffixText: unit, errorText: error),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: C.muted)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v == null || v < min || v > max) {
                setState(() => error = 'Enter a number from $min to $max');
                return;
              }
              Navigator.pop(ctx, v);
            },
            child: const Text(
              'Save',
              style: TextStyle(color: C.lime, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String yes = 'Yes',
  String no = 'Cancel',
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title, style: T.display(22)),
      content: Text(message, style: T.body(15, color: C.soft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(no, style: const TextStyle(color: C.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(
            yes,
            style: TextStyle(
              color: danger ? C.coral : C.lime,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: T.body(14, color: C.ink, weight: FontWeight.w700),
        ),
        backgroundColor: C.lime,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
}

/// Number field used on forms.
class NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool highlight;
  final Color? highlightColor;
  final ValueChanged<String>? onChanged;
  final bool decimal;

  const NumField({
    super.key,
    required this.controller,
    required this.label,
    this.highlight = false,
    this.highlightColor,
    this.onChanged,
    this.decimal = true,
  });

  @override
  Widget build(BuildContext context) {
    final hc = highlightColor ?? C.lime;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: T.body(
            13,
            color: highlight ? hc : C.muted,
            weight: highlight ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: TextInputType.numberWithOptions(decimal: decimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]'),
            ),
          ],
          style: T.display(22),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: highlight ? hc : C.line,
                width: highlight ? 2 : 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: highlight ? hc : C.line,
                width: highlight ? 2 : 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

double? parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

/// A switch row used on settings pages.
class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? trailing;

  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    radius: 20,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: T.body(16, weight: FontWeight.w700)),
              if (subtitle != null)
                Text(subtitle!, style: T.body(13, color: C.muted)),
            ],
          ),
        ),
        ?trailing,
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: C.ink,
          activeTrackColor: C.lime,
          inactiveThumbColor: C.muted,
          inactiveTrackColor: C.pot2,
        ),
      ],
    ),
  );
}
