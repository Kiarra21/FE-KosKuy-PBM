import 'package:flutter/material.dart';

import '../core/app_colors.dart';

class OwnerSelectionOption<T> {
  const OwnerSelectionOption({
    required this.value,
    required this.label,
    this.icon,
    this.destructive = false,
  });

  final T value;
  final String label;
  final IconData? icon;
  final bool destructive;
}

class OwnerSelectionResult<T> {
  const OwnerSelectionResult(this.value);

  final T? value;
}

class OwnerActionMenuItem {
  const OwnerActionMenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool destructive;
}

Future<OwnerSelectionResult<T>?> showOwnerSelectionSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<OwnerSelectionOption<T>> options,
  T? selectedValue,
}) {
  return showModalBottomSheet<OwnerSelectionResult<T>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _OwnerChoiceSheet<T>(
        title: title,
        subtitle: subtitle,
        options: options,
        selectedValue: selectedValue,
      );
    },
  );
}

Future<OwnerActionMenuItem?> showOwnerActionSheet(
  BuildContext context, {
  required String title,
  String? subtitle,
  required List<OwnerActionMenuItem> actions,
}) {
  return showModalBottomSheet<OwnerActionMenuItem>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _OwnerActionSheet(
        title: title,
        subtitle: subtitle,
        actions: actions,
      );
    },
  );
}

class OwnerActionMenuButton extends StatelessWidget {
  const OwnerActionMenuButton({
    super.key,
    required this.title,
    required this.actions,
    this.icon = Icons.more_vert_rounded,
    this.iconColor = AppColors.white,
    this.size = 18,
  });

  final String title;
  final List<OwnerActionMenuItem> actions;
  final IconData icon;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () async {
          final selected = await showOwnerActionSheet(
            context,
            title: title,
            actions: actions,
          );
          selected?.onTap();
        },
        icon: Icon(icon, color: iconColor, size: size),
      ),
    );
  }
}

class OwnerSelectField<T> extends StatelessWidget {
  const OwnerSelectField({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.label,
    this.hint,
    this.prefixIcon,
    this.enabled = true,
    this.backgroundColor = const Color(0xFFF0F1F4),
    this.textColor = AppColors.navy,
    this.borderRadius = 8,
  });

  final String title;
  final List<OwnerSelectionOption<T>> options;
  final T? selectedValue;
  final ValueChanged<T?>? onChanged;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final bool enabled;
  final Color backgroundColor;
  final Color textColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    OwnerSelectionOption<T>? selectedOption;
    for (final option in options) {
      if (option.value == selectedValue) {
        selectedOption = option;
        break;
      }
    }
    final displayText = selectedOption?.label ?? hint ?? 'Pilih';

    return InkWell(
      onTap: enabled
          ? () async {
              final result = await showOwnerSelectionSheet<T>(
                context,
                title: title,
                options: options,
                selectedValue: selectedValue,
              );
              if (result != null) {
                onChanged?.call(result.value);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: InputDecorator(
        isEmpty: selectedOption == null,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            borderSide: BorderSide.none,
          ),
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? textColor : textColor.withValues(alpha: 0.45),
          ),
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: selectedOption == null
                ? textColor.withValues(alpha: 0.55)
                : textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OwnerChoiceSheet<T> extends StatelessWidget {
  const _OwnerChoiceSheet({
    required this.title,
    required this.options,
    required this.selectedValue,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<OwnerSelectionOption<T>> options;
  final T? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.52,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final option = options[index];
                  final selected = option.value == selectedValue;
                  final foreground = option.destructive
                      ? Colors.red
                      : selected
                      ? AppColors.navy
                      : AppColors.white;
                  final background = selected
                      ? AppColors.gold
                      : const Color(0xFF1E2A45);
                  return Material(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(
                        OwnerSelectionResult<T>(option.value),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            if (option.icon != null) ...[
                              Icon(option.icon, color: foreground, size: 20),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                option.label,
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (selected)
                              const Icon(
                                Icons.check_rounded,
                                color: AppColors.navy,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OwnerActionSheet extends StatelessWidget {
  const _OwnerActionSheet({
    required this.title,
    required this.actions,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final List<OwnerActionMenuItem> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: actions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  final foreground = action.destructive
                      ? Colors.red
                      : AppColors.white;
                  return Material(
                    color: const Color(0xFF1E2A45),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop(action);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            if (action.icon != null) ...[
                              Icon(action.icon, color: foreground, size: 20),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Text(
                                action.label,
                                style: TextStyle(
                                  color: foreground,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.white,
                  side: const BorderSide(color: AppColors.white),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}