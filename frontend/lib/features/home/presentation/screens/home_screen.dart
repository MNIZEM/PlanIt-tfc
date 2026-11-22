import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:planit_app/core/storage/token_storage.dart';
import 'package:planit_app/features/task/data/task_service.dart';

String _formatearFechaCorta(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  final hora = fecha.hour.toString().padLeft(2, '0');
  final min = fecha.minute.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year} · $hora:$min';
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

Future<void> mostrarDialogoNuevaTarea({
  required BuildContext context,
  required TaskService taskService,
  required ValueChanged<TaskItem> onTareaCreada,
  DateTime? fechaInicial,
}) async {
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  final subjectIdController = TextEditingController(text: '1');
  String tipoSeleccionado = 'tarea';
  DateTime fechaSeleccionada =
      fechaInicial ?? DateTime.now().add(const Duration(hours: 2));
  bool guardando = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Nuevo evento / tarea'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: tituloController,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ej. Entrega TFC, Examen...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción / Lugar (opcional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tipoSeleccionado,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: const [
                      DropdownMenuItem(value: 'tarea', child: Text('Tarea')),
                      DropdownMenuItem(value: 'examen', child: Text('Examen')),
                      DropdownMenuItem(value: 'evento', child: Text('Evento')),
                    ],
                    onChanged: (valor) {
                      if (valor != null) {
                        setDialogState(() => tipoSeleccionado = valor);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectIdController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'ID Asignatura (subjectId)',
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
                        firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
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
            ),
            actions: [
              TextButton(
                onPressed: guardando ? null : () => Navigator.pop(ctx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                  final titulo = tituloController.text.trim();
                  final subjectId =
                  int.tryParse(subjectIdController.text.trim());
                  if (titulo.isEmpty || subjectId == null) return;

                  setDialogState(() => guardando = true);
                  try {
                    final nueva = TaskItem(
                      title: titulo,
                      description: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      taskType: tipoSeleccionado,
                      startDate: fechaSeleccionada,
                      dueDate: fechaSeleccionada.add(const Duration(hours: 1)),
                      subjectId: subjectId,
                    );
                    final creada = await taskService.createTask(nueva);
                    onTareaCreada(creada);
                    if (ctx.mounted) Navigator.pop(ctx);
                  } on DioException catch (e) {
                    setDialogState(() => guardando = false);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al guardar (${e.response?.statusCode ?? 'red'})',
                          ),
                        ),
                      );
                    }
                  }
                },
                child: Text(guardando ? 'Guardando...' : 'Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final TaskService _taskService = TaskService();
  List<TaskItem> _tareas = [];
  bool _cargando = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarTareas();
  }

  Future<void> _cargarTareas() async {
    setState(() {
      _cargando = true;
      _errorMsg = null;
    });
    try {
      final lista = await _taskService.getTasks();
      lista.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (!mounted) return;
      setState(() {
        _tareas = lista;
        _cargando = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg =
        'No se pudieron cargar las tareas (${e.response?.statusCode ?? 'error de conexión'})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg = 'Error inesperado al cargar las tareas';
      });
    }
  }

  void _agregarTarea(TaskItem nuevaTarea) {
    setState(() {
      _tareas.add(nuevaTarea);
      _tareas.sort((a, b) => a.dueDate.compareTo(b.dueDate));
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
        tareas: _tareas,
        cargando: _cargando,
        errorMsg: _errorMsg,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
        onReintentar: _cargarTareas,
        onIrACalendario: () => setState(() => _selectedIndex = 1),
      ),
      _CalendarioTab(
        tareas: _tareas,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
      ),
      _TodosEventosTab(
        tareas: _tareas,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
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
  final List<TaskItem> tareas;
  final bool cargando;
  final String? errorMsg;
  final TaskService taskService;
  final ValueChanged<TaskItem> onTareaCreada;
  final VoidCallback onReintentar;
  final VoidCallback onIrACalendario;

  const _InicioTab({
    required this.tareas,
    required this.cargando,
    required this.errorMsg,
    required this.taskService,
    required this.onTareaCreada,
    required this.onReintentar,
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
    final proximosTres = tareas
        .where(
            (t) => !t.dueDate.isBefore(ahora.subtract(const Duration(minutes: 15))))
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
          if (cargando)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (errorMsg != null)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(errorMsg!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: onReintentar,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (proximosTres.isEmpty)
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
                    final tarea = proximosTres[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.event_available),
                        title: Text(tarea.title),
                        subtitle: Text(
                          tarea.description != null && tarea.description!.isNotEmpty
                              ? '${_formatearFechaCorta(tarea.dueDate)} · ${tarea.description}'
                              : _formatearFechaCorta(tarea.dueDate),
                        ),
                      ),
                    );
                  },
                ),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => mostrarDialogoNuevaTarea(
              context: context,
              taskService: taskService,
              onTareaCreada: onTareaCreada,
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
  final List<TaskItem> tareas;
  final TaskService taskService;
  final ValueChanged<TaskItem> onTareaCreada;

  const _CalendarioTab({
    required this.tareas,
    required this.taskService,
    required this.onTareaCreada,
  });

  @override
  State<_CalendarioTab> createState() => _CalendarioTabState();
}

class _CalendarioTabState extends State<_CalendarioTab> {
  DateTime _diaSeleccionado = DateTime.now();

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _abrirVentanaDia(DateTime dia) async {
    final tareasDelDia =
    widget.tareas.where((t) => _esMismoDia(t.dueDate, dia)).toList();

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
              if (tareasDelDia.isEmpty)
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
                    itemCount: tareasDelDia.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final tarea = tareasDelDia[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.event_available),
                          title: Text(tarea.title),
                          subtitle: Text(
                            tarea.description != null &&
                                tarea.description!.isNotEmpty
                                ? '${_formatearHora(tarea.dueDate)} · ${tarea.description}'
                                : _formatearHora(tarea.dueDate),
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
                  await mostrarDialogoNuevaTarea(
                    context: context,
                    taskService: widget.taskService,
                    onTareaCreada: widget.onTareaCreada,
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

class _TodosEventosTab extends StatelessWidget {
  final List<TaskItem> tareas;
  final TaskService taskService;
  final ValueChanged<TaskItem> onTareaCreada;

  const _TodosEventosTab({
    required this.tareas,
    required this.taskService,
    required this.onTareaCreada,
  });

  @override
  Widget build(BuildContext context) {
    return tareas.isEmpty
        ? const Center(child: Text('No tienes ningún evento programado'))
        : ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tareas.length,
      itemBuilder: (context, index) {
        final t = tareas[index];
        return ListTile(
          leading: const Icon(Icons.event),
          title: Text(t.title),
          subtitle: Text(_formatearFechaCorta(t.dueDate)),
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