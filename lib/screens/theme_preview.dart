import 'package:flutter/material.dart';
import 'package:bytestreak/theme/app_colors.dart';

class ThemePreview extends StatelessWidget {
  const ThemePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ByteStreak colours',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                Swatch(name: 'green', color: AppColors.green),
                Swatch(name: 'greenSoft', color: AppColors.greenSoft),
                Swatch(name: 'amber', color: AppColors.amber),
                Swatch(name: 'amberSoft', color: AppColors.amberSoft),
                Swatch(name: 'red', color: AppColors.red),
                Swatch(name: 'redSoft', color: AppColors.redSoft),
                Swatch(name: 'blue', color: AppColors.blue),
                Swatch(name: 'blueSoft', color: AppColors.blueSoft),
                Swatch(name: 'purple', color: AppColors.purple),
                Swatch(name: 'purpleSoft', color: AppColors.purpleSoft),
                Swatch(name: 'background', color: AppColors.background),
                Swatch(name: 'surface', color: AppColors.surface),
                Swatch(name: 'sunken', color: AppColors.sunken),
                Swatch(name: 'line', color: AppColors.line),
                Swatch(name: 'ink', color: AppColors.ink),
                Swatch(name: 'muted', color: AppColors.muted),
                Swatch(name: 'faint', color: AppColors.faint),
              ],
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {},
              child: const Text('Continue'),
            ),
            OutlinedButton(
              onPressed: () {},
              child: const Text('Cancel'),
            ),
            Switch(value: true, onChanged: (_) {}),
          ],
        ),
      ),
    );
  }
}

/// One coloured square with its name underneath.
class Swatch extends StatelessWidget {
  const Swatch({super.key, required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line),
          ),
        ),
        const SizedBox(height: 6),
        Text(name, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}