import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_keys.dart';
import '../../domain/entities/abonnement.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/user_profile.dart';

class IaService {
  // Groq — API compatible OpenAI, gratuit (console.groq.com)
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  static const _systemPrompt =
      'Tu es un conseiller budgétaire personnel bienveillant et expert. '
      'Tu analyses les données financières de l\'utilisateur et fournis des conseils '
      'personnalisés, concrets et actionnables. '
      'Réponds toujours en français, de manière claire et structurée. '
      'Sois encourageant même quand la situation est difficile.';

  Future<String> analyserBudget({
    required UserProfile profile,
    required List<Transaction> transactions,
    required List<Abonnement> abonnements,
    required String mois,
    String? questionUtilisateur,
  }) async {
    final contexte = _buildContexte(profile, transactions, abonnements, mois);
    final prompt = questionUtilisateur != null
        ? '$contexte\n\nQuestion de l\'utilisateur : $questionUtilisateur'
        : '$contexte\n\nFais une analyse budgétaire complète et donne 3 recommandations concrètes et personnalisées.';

    final response = await http.post(
      Uri.parse(_endpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $groqApiKey',
      },
      body: jsonEncode({
        'model': groqModel,
        'max_tokens': 1024,
        'temperature': 0.7,
        'messages': [
          {'role': 'system', 'content': _systemPrompt},
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode != 200) {
      String message = 'Erreur API Groq : ${response.statusCode}';
      try {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        final errMsg = (err['error']?['message'] as String?) ?? '';
        if (errMsg.contains('invalid_api_key') || errMsg.contains('No API key')) {
          message = 'Clé API Groq invalide. '
              'Génère-en une sur console.groq.com et colle-la dans api_keys.dart.';
        } else if (errMsg.contains('rate_limit')) {
          message = 'Limite de requêtes atteinte. Réessaie dans quelques secondes.';
        } else if (errMsg.isNotEmpty) {
          message = errMsg;
        }
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data['choices'][0]['message']['content'] as String;
  }

  String _buildContexte(
    UserProfile profile,
    List<Transaction> transactions,
    List<Abonnement> abonnements,
    String mois,
  ) {
    double revenus = 0, fixes = 0, variables = 0, epargne = 0;
    final categories = <String, double>{};

    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.revenu:
          revenus += t.montant;
        case TransactionType.depenseFixe:
          fixes += t.montant;
        case TransactionType.depenseVariable:
          variables += t.montant;
          categories[t.categorie.label] =
              (categories[t.categorie.label] ?? 0) + t.montant;
        case TransactionType.epargne:
          epargne += t.montant;
      }
    }

    final abosActifs = abonnements.where((a) => a.actif).toList();
    final coutAbos = abosActifs.fold(0.0, (s, a) => s + a.montantMensuel);

    final sb = StringBuffer();
    sb.writeln('=== PROFIL UTILISATEUR ===');
    sb.writeln('Situation professionnelle : ${profile.typeContrat.label}');
    sb.writeln('Logement : ${profile.situationLogement.label}');
    if (profile.loyerMensuel != null) {
      sb.writeln(
          'Loyer mensuel : ${profile.loyerMensuel!.toStringAsFixed(2)} €');
    }
    sb.writeln(
        'Objectif épargne mensuel : ${profile.objectifEpargne.toStringAsFixed(2)} €');
    if (profile.objectifPatrimoine > 0) {
      sb.writeln(
          'Objectif patrimoine : ${profile.objectifPatrimoine.toStringAsFixed(0)} €');
      if (profile.dateObjectifPatrimoine != null) {
        final d = profile.dateObjectifPatrimoine!;
        sb.writeln(
            'Date objectif : ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}');
      }
    }

    sb.writeln('\n=== DONNÉES FINANCIÈRES ($mois) ===');
    sb.writeln('Revenus totaux : ${revenus.toStringAsFixed(2)} €');
    sb.writeln('Dépenses fixes : ${fixes.toStringAsFixed(2)} €');
    sb.writeln('Dépenses variables : ${variables.toStringAsFixed(2)} €');
    sb.writeln('Épargne réalisée : ${epargne.toStringAsFixed(2)} €');
    sb.writeln(
        'Coût abonnements actifs : ${coutAbos.toStringAsFixed(2)} €/mois');
    sb.writeln(
        'Solde : ${(revenus - fixes - variables - epargne).toStringAsFixed(2)} €');

    if (categories.isNotEmpty) {
      sb.writeln('\n=== RÉPARTITION DÉPENSES VARIABLES ===');
      for (final entry in categories.entries) {
        sb.writeln('${entry.key} : ${entry.value.toStringAsFixed(2)} €');
      }
    }

    if (abosActifs.isNotEmpty) {
      sb.writeln('\n=== ABONNEMENTS ACTIFS (${abosActifs.length}) ===');
      for (final a in abosActifs) {
        sb.writeln(
            '${a.nom} : ${a.montantMensuel.toStringAsFixed(2)} €/mois (${a.frequence.label})');
      }
    }

    return sb.toString();
  }
}
