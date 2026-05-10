import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/abonnement.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Ouvrir BudgetPro');

    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
        linux: linux,
      ),
    );
    _initialized = true;
  }

  static Future<void> planifierRappelAbonnement(
    Abonnement abonnement,
    int joursAvant,
  ) async {
    await annulerRappel(abonnement.id);
    if (!abonnement.actif) return;

    final dateNotif = abonnement.prochainRenouvellement.subtract(Duration(days: joursAvant));
    final maintenant = DateTime.now();
    if (dateNotif.isBefore(maintenant)) return;

    final id = abonnement.id.hashCode.abs() % 100000;

    await _plugin.zonedSchedule(
      id,
      'Renouvellement à venir',
      '${abonnement.nom} se renouvelle dans $joursAvant jour${joursAvant > 1 ? 's' : ''} (${abonnement.montant.toStringAsFixed(2)} €)',
      tz.TZDateTime.from(dateNotif, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'abonnements_channel',
          'Rappels abonnements',
          channelDescription: 'Rappels de renouvellement d\'abonnements',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> annulerRappel(String abonnementId) async {
    final id = abonnementId.hashCode.abs() % 100000;
    await _plugin.cancel(id);
  }

  static Future<void> planifierTousLesRappels(
    List<Abonnement> abonnements,
    int joursAvant,
  ) async {
    for (final a in abonnements) {
      await planifierRappelAbonnement(a, joursAvant);
    }
  }
}
