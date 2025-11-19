import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:localtrade/core/widgets/custom_app_bar.dart';
import 'package:localtrade/features/settings/data/models/app_language.dart';
import 'package:localtrade/features/settings/providers/language_provider.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(languageProvider);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Language'),
      body: ListView.builder(
        itemCount: AppLanguage.values.length,
        itemBuilder: (context, index) {
          final language = AppLanguage.values[index];
          final isSelected = language == currentLanguage;

          return RadioListTile<AppLanguage>(
            value: language,
            groupValue: currentLanguage,
            onChanged: (value) {
              if (value != null) {
                ref.read(languageProvider.notifier).setLanguage(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to ${language.displayName}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            title: Row(
              children: [
                Text(
                  language.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    language.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            subtitle: Text(
              language.localeCode.toUpperCase(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            secondary: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : null,
            selected: isSelected,
            activeColor: Theme.of(context).colorScheme.primary,
          );
        },
      ),
    );
  }
}

