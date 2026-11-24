import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:planit_app/features/task/data/task_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static const int _maxNotificacionesPorTarea = 40;

  static const AndroidNotificationDetails _androidDetails =
  AndroidNotificationDetails(
    'planit_tareas_periodicas',
    'Recordatorios periódicos de tareas',
    channelDescription:
    'Avisos periódicos desde la fecha de inicio hasta el vencimiento de la tarea',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    tz.initializeTimeZones();
    // Si quieres fijar zona horaria local de España por defecto:
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    const androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(initSettings);

    final androidPlugin =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }

  Duration _intervaloDesdeFrecuencia(String frecuencia) {
    switch (frecuencia) {
      case 'cada_30_min':
        return const Duration(minutes: 30);
      case 'cada_hora':
        return const Duration(hours: 1);
      case 'cada_6_horas':
        return const Duration(hours: 6);
      case 'diario':
        return const Duration(days: 1);
      case 'progresivo':
      default:
        return const Duration(hours: 2);
    }
  }

  int _idNotificacion(int taskId, int index) => taskId * 100 + index;

  Future<void> cancelarNotificacionesTarea(int taskId) async {
    for (int i = 0; i < _maxNotificacionesPorTarea; i++) {
      await _plugin.cancel(_idNotificacion(taskId, i));
    }
  }

  Future<void> programarNotificacionesTarea({
    required TaskItem tarea,
    DateTime? fechaInicioPersonalizada,
  }) async {
    if (tarea.id == null) return;

    // Primero limpiamos programaciones anteriores de esta tarea
    await cancelarNotificacionesTarea(tarea.id!);

    if (!tarea.reminderActive || tarea.completed) return;

    final ahora = DateTime.now();
    DateTime cursor = fechaInicioPersonalizada ?? tarea.startDate;
    if (cursor.isBefore(ahora)) {
      cursor = ahora.add(const Duration(seconds: 10));
    }

    final fin = tarea.dueDate;
    if (!cursor.isBefore(fin)) return;

    final intervalo = _intervaloDesdeFrecuencia(tarea.reminderFrequency);
    const details = NotificationDetails(android: _androidDetails);

    int slot = 0;
    while (!cursor.isAfter(fin) && slot < _maxNotificacionesPorTarea) {
      final scheduledDate = tz.TZDateTime.from(cursor, tz.local);

      try {
        await _plugin.zonedSchedule(
          _idNotificacion(tarea.id!, slot),
          'PlanIt · ${tarea.title}',
          'Recordatorio (${tarea.taskType}) — vence el ${fin.day.toString().padLeft(2, '0')}/${fin.month.toString().padLeft(2, '0')} a las ${fin.hour.toString().padLeft(2, '0')}:${fin.minute.toString().padLeft(2, '0')}',
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e) {
        debugPrint('No se pudo programar notificación slot $slot: $e');
        break;
      }

      slot++;
      cursor = cursor.add(intervalo);
    }
  }
}