import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';
import '../repositories/transactions_repository.dart';

/// Injecte automatiquement les sources de revenus et charges fixes du profil
/// comme transactions du mois courant — une seule fois par mois (style comptable).
class RecurringService {
  static const _prefPrefix = 'rec_boot_';

  /// Injecte les transactions récurrentes pour [mois] si ce n'est pas encore fait.
  /// Doit être appelé à chaque chargement du mois courant.
  static Future<void> maybeBootstrap(
    String mois,
    UserProfile profile,
    TransactionsRepository repo,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefPrefix$mois';

    if (prefs.getBool(key) == true) return; // déjà bootstrappé

    await _inject(mois, profile, repo);
    await prefs.setBool(key, true);
  }

  /// Réinitialise le flag de bootstrap pour [mois] — utile quand le profil
  /// est créé pour la première fois (ex : configuré en cours de mois).
  static Future<void> resetBootstrap(String mois) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefPrefix$mois');
  }

  // ── Injection ──────────────────────────────────────────────────────────────

  static Future<void> _inject(
    String mois,
    UserProfile profile,
    TransactionsRepository repo,
  ) async {
    final year = int.parse(mois.split('-')[0]);
    final month = int.parse(mois.split('-')[1]);

    // ── Sources de revenus ──
    for (final src in profile.sources) {
      if (src.montant <= 0) continue;
      await repo.insertOrIgnore(
        Transaction(
          id: 'rec_rev_${src.id}_$mois',
          mois: mois,
          montant: src.montant,
          description: src.label,
          categorie: _categorieRevenu(src.label),
          date: _dateForDay(year, month, src.jour),
          type: TransactionType.revenu,
        ),
      );
    }

    // ── Loyer (si locataire) ──
    if (profile.situationLogement == LogementType.locataire &&
        (profile.loyerMensuel ?? 0) > 0) {
      await repo.insertOrIgnore(
        Transaction(
          id: 'rec_loyer_$mois',
          mois: mois,
          montant: profile.loyerMensuel!,
          description: 'Loyer mensuel',
          categorie: CategorieTransaction.loyer,
          date: _dateForDay(year, month, 1),
          type: TransactionType.depenseFixe,
        ),
      );
    }

    // ── Charges fixes ──
    for (final chg in profile.chargesFixes) {
      if (chg.montant <= 0) continue;
      await repo.insertOrIgnore(
        Transaction(
          id: 'rec_chg_${chg.id}_$mois',
          mois: mois,
          montant: chg.montant,
          description: chg.label,
          categorie: _categorieCharge(chg.label),
          date: _dateForDay(year, month, chg.jour),
          type: TransactionType.depenseFixe,
        ),
      );
    }
  }

  /// Retourne une DateTime sûre pour le [jour] du mois (clampé au dernier jour
  /// du mois si nécessaire, ex : 31 en février → 28).
  static DateTime _dateForDay(int year, int month, int jour) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, jour.clamp(1, lastDay));
  }

  // ── Helpers catégories ─────────────────────────────────────────────────────

  static CategorieTransaction _categorieRevenu(String label) {
    final l = label.toLowerCase();
    if (l.contains('salaire') || l.contains('paie') || l.contains('net')) {
      return CategorieTransaction.salaire;
    }
    if (l.contains('apl') || l.contains('aide') || l.contains('caf')) {
      return CategorieTransaction.apl;
    }
    return CategorieTransaction.autreRevenu;
  }

  static CategorieTransaction _categorieCharge(String label) {
    final l = label.toLowerCase();
    if (l.contains('loyer') || l.contains('logement') || l.contains('rent')) {
      return CategorieTransaction.loyer;
    }
    return CategorieTransaction.autre;
  }
}
