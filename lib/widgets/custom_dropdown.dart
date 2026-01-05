import 'package:flutter/material.dart';
import 'package:konek2move/utils/app_colors.dart';

class CustomDropdownField extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> options;
  final String? value;
  final bool required;
  final ValueChanged<String?> onChanged;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.hint,
    required this.options,
    this.value,
    required this.onChanged,
    this.required = false,
  });

  @override
  State<CustomDropdownField> createState() => _CustomDropdownFieldState();
}

class _CustomDropdownFieldState extends State<CustomDropdownField> {
  bool isFocused = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// ----- LABEL + REQUIRED MARK -----
        RichText(
          text: TextSpan(
            text: widget.label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            children: widget.required
                ? const [
                    TextSpan(
                      text: " *",
                      style: TextStyle(color: Colors.red),
                    ),
                  ]
                : [],
          ),
        ),

        const SizedBox(height: 8),

        /// ----- FIELD -----
        GestureDetector(
          onTap: () => _openBottomSheet(context),
          child: InputDecorator(
            decoration: InputDecoration(
              hintText: widget.hint,

              /// --- SAME COLORS & HEIGHT AS CustomInputField ---
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14.5,
              ), // SAME HEIGHT

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 2,
                ),
              ),
            ),

            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.value ?? widget.hint,
                  style: TextStyle(
                    fontSize: 16,

                    color: widget.value == null
                        ? Colors.grey.shade500
                        : Colors.black87,
                    fontWeight: widget.value == null
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                ),

                Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// ---------- BOTTOM SHEET ----------
  void _openBottomSheet(BuildContext context) async {
    setState(() => isFocused = true);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                widget.hint,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ...widget.options.map(
                (e) => ListTile(
                  title: Text(e, style: const TextStyle(fontSize: 16)),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onChanged(e);
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        );
      },
    );

    setState(() => isFocused = false);
  }
}
