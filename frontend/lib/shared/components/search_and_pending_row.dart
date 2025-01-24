import 'package:flutter/material.dart';

/// A reusable search bar + checkbox row for "Show Only Pending".
class SearchAndPendingRow extends StatelessWidget {
  final String searchLabel;
  final Function(String) onSearchChanged;

  /// Whether we're currently showing only pending
  final bool showOnlyPending;

  /// Called when the checkbox changes
  final Function(bool?) onTogglePending;

  const SearchAndPendingRow({
    super.key,
    required this.searchLabel,
    required this.onSearchChanged,
    required this.showOnlyPending,
    required this.onTogglePending,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // The search field
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: searchLabel,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 10),

        // The "Show Only Pending" checkbox
        Row(
          children: [
            Checkbox(
              value: showOnlyPending,
              onChanged: onTogglePending,
              activeColor: Theme.of(context).primaryColor,
            ),
            const Text('Show Only Pending'),
          ],
        ),
      ],
    );
  }
}
