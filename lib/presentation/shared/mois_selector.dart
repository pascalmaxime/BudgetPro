import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../features/budget/budget_provider.dart';

class MoisSelector extends ConsumerWidget {
  const MoisSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mois = ref.watch(moisSelectionneProvider);
    final date = DateFormat('yyyy-MM').parse(mois);
    final label = DateFormat('MMMM yyyy', 'fr_FR').format(date);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prev = DateTime(date.year, date.month - 1);
            ref.read(moisSelectionneProvider.notifier).state =
                DateFormat('yyyy-MM').format(prev);
          },
        ),
        Text(
          label[0].toUpperCase() + label.substring(1),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final next = DateTime(date.year, date.month + 1);
            ref.read(moisSelectionneProvider.notifier).state =
                DateFormat('yyyy-MM').format(next);
          },
        ),
      ],
    );
  }
}
