import 'package:flutter/material.dart';
import 'package:planit_app/core/storage/token_storage.dart';

class EventoItem {
  final String titulo;
  final DateTime fecha;
  final String? ubicacion;

  EventoItem({
    required this.titulo,
    required this.fecha,
    this.ubicacion,
  });
}

String _formatearFechaCorta(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final hora = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year} · $hora:$min';
}

Future<void> mostrarDialogoNuevoEvento({
  required BuildContext context,
  required ValueChanged<EventoItem> onAgregarEvento,
  DateTime? fechaInicial,
}) async {
  final tituloController = TextEditingController();
  final ubicacionController = TextEditingController();
  DateTime fechaSeleccionada =
      fechaInicial ?? DateTime.now().add(const Duration(hours: 2));

  final creado = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo evento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: tituloController,
                  decoration: const InputDecoration(
                    labelText: 'Título del evento',
                    hintText: 'Ej. Entrega TFC, Examen...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ubicacionController,
                  decoration: const InputDecoration(
                    labelText: 'Lugar / Detalle (opcional)',
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(_formatearFechaCorta(fechaSeleccionada)),
                  onTap: () async {
                    final fecha = await showDatePicker(
                      context: ctx,
                      initialDate: fechaSeleccionada,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (fecha == null || !ctx.mounted) return;
                    final hora = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(fechaSeleccionada),
                    );
                    if (hora == null) return;
                    setDialogState(() {
                      fechaSeleccionada = DateTime(
                        fecha.year,
                        fecha.month,
                        fecha.day,
                        hora.hour,
                        hora.minute,
                      );
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (tituloController.text.trim().isEmpty) return;
                  Navigator.pop(ctx, true);
                },
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );

  if (creado == true && tituloController.text.trim().isNotEmpty) {
    onAgregarEvento(
      EventoItem(
        titulo: tituloController.text.trim(),
        fecha: fechaSeleccionada,
        ubicacion: ubicacionController.text.trim().isEmpty
            ? null
            : ubicacionController.text.trim(),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Lista temporal en memoria para probar el flujo antes de conectar con Spring Boot
  final List<EventoItem> _eventos = [];

  void _agregarEvento(EventoItem nuevoEvento) {
    setState(() {
      _eventos.add(nuevoEvento);
      _eventos.sort((a, b) => a.fecha.compareTo(b.fecha));
    });
  }

  Future<void> _cerrarSesion() async {
    await TokenStorage.clearToken();
    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pestanas = [
      _InicioTab(
        eventos: _eventos,
        onAgregarEvento: _agregarEvento,
        onIrACalendario: () => setState(() => _selectedIndex = 1),
      ),
      _CalendarioTab(
        eventos: _eventos,
        onAgregarEvento: _agregarEvento,
      ),
      _TodosEventosPlaceholderTab(
        eventos: _eventos,
        onAgregarEvento: _agregarEvento,
      ),
      _AjustesTab(onCerrarSesion: _cerrarSesion),
    ];

    const titulos = [
      'PlanIt',
      'Calendario',
      'Eventos',
      'Ajustes',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titulos[_selectedIndex]),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Cerrar sesión',
              onPressed: _cerrarSesion,
            ),
        ],
      ),
      body: pestanas[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Eventos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

class _InicioTab extends StatelessWidget {
  final List<EventoItem> eventos;
  final ValueChanged<EventoItem> onAgregarEvento;
  final VoidCallback onIrACalendario;

  const _InicioTab({
    required this.eventos,
    required this.onAgregarEvento,
    required this.onIrACalendario,
  });

  String _formatearFechaHoy(DateTime fecha) {
    const dias = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const meses = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    final nombreDia = dias[fecha.weekday - 1];
    final capitalizado = nombreDia[0].toUpperCase() + nombreDia.substring(1);
    return '$capitalizado, ${fecha.day} de ${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final proximosTres = eventos
        .where((e) => !e.fecha.isBefore(ahora.subtract(const Duration(minutes: 15))))
        .take(3)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoy',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    _formatearFechaHoy(ahora),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: onIrACalendario,
                icon: const Icon(Icons.calendar_month),
                tooltip: 'Ver calendario',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Próximos eventos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (proximosTres.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No tienes ningún evento programado',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: proximosTres.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final evento = proximosTres[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_available),
                      title: Text(evento.titulo),
                      subtitle: Text(
                        evento.ubicacion != null
                            ? '${_formatearFechaCorta(evento.fecha)} · ${evento.ubicacion}'
                            : _formatearFechaCorta(evento.fecha),
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => mostrarDialogoNuevoEvento(
              context: context,
              onAgregarEvento: onAgregarEvento,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Añadir evento'),
          ),
        ],
      ),
    );
  }
}

class _CalendarioTab extends StatefulWidget {
  final List<EventoItem> eventos;
  final ValueChanged<EventoItem> onAgregarEvento;

  const _CalendarioTab({
    required this.eventos,
    required this.onAgregarEvento,
  });

  @override
  State<_CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<_CalendarioTab> {
  DateTime _diaSeleccionado = DateTime.now();

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatearHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final min = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$min';
  }

  String _formatearFechaCabecera(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    return '$dia/$mes/${fecha.year}';
  }

  Future<void> _abrirVentanaDia(DateTime dia) async {
    final eventosDelDia = widget.eventos
        .where((e) => _esMismoDia(e.fecha, dia))
        .toList();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Eventos del ${_formatearFechaCabecera(dia)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (eventosDelDia.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No tienes ningún evento este día.',
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: eventosDelDia.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final evento = eventosDelDia[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(evento.titulo),
                          subtitle: Text(
                            evento.ubicacion != null
                                ? '${_formatearHora(evento.fecha)} · ${evento.ubicacion}'
                                : _formatearHora(evento.fecha),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetCtx);
                  final ahora = DateTime.now();
                  final fechaPorDefecto = DateTime(
                    dia.year,
                    dia.month,
                    dia.day,
                    ahora.hour,
                    ahora.minute,
                  );
                  await mostrarDialogoNuevoEvento(
                    context: context,
                    onAgregarEvento: widget.onAgregarEvento,
                    fechaInicial: fechaPorDefecto,
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Añadir evento este día'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: CalendarDatePicker(
              initialDate: _diaSeleccionado,
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
              onDateChanged: (nuevaFecha) {
                setState(() => _diaSeleccionado = nuevaFecha);
                _abrirVentanaDia(nuevaFecha);
              },
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Pulsa cualquier día del calendario para ver sus eventos o añadir uno nuevo.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TodosEventosPlaceholderTab extends StatelessWidget {
  final List<EventoItem> eventos;
  final ValueChanged<EventoItem> onAgregarEvento;
  const _TodosEventosPlaceholderTab({
    required this.eventos,
    required this.onAgregarEvento,
  });

  @override
  Widget build(BuildContext context) {
    return eventos.isEmpty
        ? const Center(child: Text('No tienes ningún evento programado'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: eventos.length,
      itemBuilder: (context, index) {
        final e = eventos[index];
        return ListTile(
          leading: const Icon(Icons.event),
          title: Text(e.titulo),
          subtitle: Text(_formatearFechaCorta(e.fecha)),
        );
      },
    );
  }
}

class _AjustesTab extends StatelessWidget {
  final VoidCallback onCerrarSesion;
  const _AjustesTab({required this.onCerrarSesion});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: onCerrarSesion,
        ),
      ],
    );
  }
}