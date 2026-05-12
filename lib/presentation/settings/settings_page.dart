import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/database/database_helper.dart';
import '../../data/services/excel_export_service.dart';
import '../../data/services/excel_import_service.dart';
import '../../data/services/excel_template_service.dart';
import '../../features/abonnements/abonnements_provider.dart';
import '../../features/budget/budget_provider.dart';
import '../../features/comptes/comptes_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../features/profile/profile_provider.dart';
import '../../features/theme/theme_provider.dart';
import 'profile_setup_sheet.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(title: Text('Paramètres')),
          SliverList(
            delegate: SliverChildListDelegate([
              const _SectionTitle(title: 'Profil financier'),
              profileAsync.when(
                loading: () => const ListTile(title: Text('Chargement...')),
                error: (e, _) => ListTile(title: Text('Erreur : $e')),
                data: (profile) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: profile != null
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      profile != null ? Icons.person : Icons.person_outline,
                      color: profile != null
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  title: Text(profile != null
                      ? profile.typeContrat.label
                      : 'Profil non configuré'),
                  subtitle: profile != null
                      ? Text(_profileSubtitle(profile))
                      : const Text('Configurez votre profil pour une analyse personnalisée'),
                  trailing: const Icon(Icons.edit_outlined),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => const ProfileSetupSheet(),
                  ),
                ),
              ),
              const Divider(),
              const _SectionTitle(title: 'Apparence'),
              RadioGroup<ThemeMode>(
                groupValue: themeMode,
                onChanged: (v) => ref.read(themeProvider.notifier).set(v!),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(title: const Text('Thème système'), value: ThemeMode.system),
                    RadioListTile<ThemeMode>(title: const Text('Clair'), value: ThemeMode.light),
                    RadioListTile<ThemeMode>(title: const Text('Sombre'), value: ThemeMode.dark),
                  ],
                ),
              ),
              const Divider(),
              const _SectionTitle(title: 'Sauvegarde & Transfert'),
              _ExportDataTile(),
              _ImportDataTile(),
              _ExportTemplateTile(),
              const Divider(),
              const _SectionTitle(title: 'Zone dangereuse'),
              _ResetDataTile(),
              const Divider(),
              const _SectionTitle(title: 'À propos'),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('BudgetPro'),
                subtitle: Text('Version 1.0.0 · Données 100% locales'),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  String _profileSubtitle(UserProfile profile) {
    final parts = <String>[profile.situationLogement.label];
    if (profile.sources.isNotEmpty) {
      final total = profile.revenuMensuelTotal;
      if (total > 0) parts.add('${total.toStringAsFixed(0)} €/mois');
    }
    final obj = profile.objectifEpargneEffectif;
    if (obj > 0) {
      parts.add('Obj. épargne : ${obj.toStringAsFixed(0)} €');
    }
    return parts.join(' · ');
  }
}

// ── Export données réelles ────────────────────────────────────────────────────

class _ExportDataTile extends StatefulWidget {
  @override
  State<_ExportDataTile> createState() => _ExportDataTileState();
}

class _ExportDataTileState extends State<_ExportDataTile> {
  bool _loading = false;

  Future<void> _export() async {
    setState(() => _loading = true);
    try {
      final path = await ExcelExportService.exportData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sauvegarde créée :\n$path'),
            duration: const Duration(seconds: 8),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(Icons.cloud_upload_outlined, color: cs.primary, size: 20),
      ),
      title: const Text('Exporter mes données'),
      subtitle: const Text('Crée un fichier Excel avec toutes vos données\n(transactions, abonnements, comptes) dans les Téléchargements.'),
      isThreeLine: true,
      trailing: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.save_alt_outlined, color: cs.primary),
      onTap: _loading ? null : _export,
    );
  }
}

// ── Import données ─────────────────────────────────────────────────────────────

class _ImportDataTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ImportDataTile> createState() => _ImportDataTileState();
}

class _ImportDataTileState extends ConsumerState<_ImportDataTile> {
  bool _loading = false;

  Future<void> _import() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      dialogTitle: 'Sélectionner un fichier BudgetPro Export',
    );
    if (result == null || result.files.single.path == null) return;

    setState(() => _loading = true);
    try {
      final importResult = await ExcelImportService.importFromFile(
          result.files.single.path!);

      if (!mounted) return;

      // ── Rafraîchir tous les providers pour refléter les données importées ──
      ref.invalidate(comptesProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(abonnementsProvider);
      ref.invalidate(transactionsMoisProvider);
      ref.invalidate(moisDisponiblesProvider);

      final msg = '${importResult.transactions} transactions, '
          '${importResult.abonnements} abonnements, '
          '${importResult.comptes} comptes importés'
          '${importResult.profilImporte ? ', profil' : ''}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(importResult.hasErrors
              ? '$msg\n⚠️ ${importResult.errors.first}'
              : '✅ $msg'),
          duration: const Duration(seconds: 7),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur d\'import : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.cloud_download_outlined, color: Colors.orange, size: 20),
      ),
      title: const Text('Importer des données'),
      subtitle: const Text('Chargez un fichier Excel exporté depuis BudgetPro\npour restaurer ou transférer vos données.'),
      isThreeLine: true,
      trailing: _loading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.folder_open_outlined, color: Colors.orange),
      onTap: _loading ? null : _import,
    );
  }
}

// ── Modèle vierge ─────────────────────────────────────────────────────────────

class _ExportTemplateTile extends StatefulWidget {
  @override
  State<_ExportTemplateTile> createState() => _ExportTemplateTileState();
}

class _ExportTemplateTileState extends State<_ExportTemplateTile> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      final path = await ExcelTemplateService.generateTemplate();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Modèle enregistré :\n$path'),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(label: 'OK', onPressed: () {}),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.table_chart_outlined, color: Colors.green, size: 20),
      ),
      title: const Text('Générer le modèle d\'import'),
      subtitle: const Text(
          'Télécharge un fichier Excel pré-rempli avec des exemples\npour importer vos comptes, transactions et abonnements.'),
      isThreeLine: true,
      trailing: _loading
          ? const SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.download_outlined, color: cs.primary),
      onTap: _loading ? null : _generate,
    );
  }
}

// ── Réinitialisation ──────────────────────────────────────────────────────────

class _ResetDataTile extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ResetDataTile> createState() => _ResetDataTileState();
}

class _ResetDataTileState extends ConsumerState<_ResetDataTile> {
  bool _loading = false;

  Future<void> _confirmReset() async {
    // Un seul dialog avec checkbox de confirmation pour éviter le double-navigator bug
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ResetConfirmDialog(),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _loading = true);
    try {
      await DatabaseHelper.resetAll();

      if (!mounted) return;

      // Naviguer vers le dashboard AVANT d'invalider les providers
      // pour éviter l'assertion navigator "!_debugLocked"
      context.go('/dashboard');

      // Invalider les providers après la frame suivante
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.invalidate(comptesProvider);
        ref.invalidate(profileProvider);
        ref.invalidate(abonnementsProvider);
        ref.invalidate(transactionsMoisProvider);
        ref.invalidate(moisDisponiblesProvider);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_forever_outlined, color: Colors.red, size: 20),
      ),
      title: const Text(
        'Réinitialiser toutes les données',
        style: TextStyle(color: Colors.red),
      ),
      subtitle: const Text(
          'Supprime définitivement toutes les transactions,\nabonnements, comptes et le profil.'),
      isThreeLine: true,
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red))
          : const Icon(Icons.chevron_right, color: Colors.red),
      onTap: _loading ? null : _confirmReset,
    );
  }
}

// ── Dialog de confirmation unique ────────────────────────────────────────────

class _ResetConfirmDialog extends StatefulWidget {
  const _ResetConfirmDialog();

  @override
  State<_ResetConfirmDialog> createState() => _ResetConfirmDialogState();
}

class _ResetConfirmDialogState extends State<_ResetConfirmDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 44),
      title: const Text('Réinitialiser toutes les données ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette action supprimera définitivement :\n\n'
            '  • Toutes les transactions\n'
            '  • Tous les abonnements\n'
            '  • Tous les comptes & épargne\n'
            '  • Votre profil financier\n',
          ),
          const Text(
            '⚠️  Cette action est irréversible.\n'
            'Pensez à exporter vos données avant.',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() => _checked = !_checked),
            child: Row(
              children: [
                Checkbox(
                  value: _checked,
                  activeColor: Colors.red,
                  onChanged: (v) => setState(() => _checked = v ?? false),
                ),
                const Expanded(
                  child: Text(
                    'Je comprends que toutes mes données seront supprimées',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _checked ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Supprimer toutes les données'),
        ),
      ],
    );
  }
}

// ── Titre de section ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title,
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );
  }
}
