import 'package:flutter/material.dart';

class SearchAndAddRow extends StatelessWidget {
  final String searchLabel;
  final IconData searchIcon;
  final Function(String) onSearchChanged;

  final String addButtonLabel;
  final IconData addButtonIcon;
  final VoidCallback onAddPressed;

  const SearchAndAddRow({
    Key? key,
    required this.searchLabel,
    required this.searchIcon,
    required this.onSearchChanged,
    required this.addButtonLabel,
    required this.addButtonIcon,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              labelText: searchLabel,
              prefixIcon: Icon(searchIcon),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: onAddPressed,
          icon: Icon(addButtonIcon),
          label: Text(addButtonLabel),
        ),
      ],
    );
  }
}
