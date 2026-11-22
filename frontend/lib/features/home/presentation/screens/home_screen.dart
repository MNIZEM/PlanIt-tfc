import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:planit_app/core/storage/token_storage.dart';
import 'package:planit_app/features/subject/data/subject_service.dart';
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

Widget _construirTileTarea({
  required BuildContext context,
  required TaskItem tarea,
  required String subtitulo,
  required Future<void> Function(TaskItem) onToggleCompletada,
  required Future<void> Function(TaskItem) onEliminarTarea,
}) {
  return Card(
    child: ListTile(
      leading: Checkbox(
        value: tarea.completed,
        onChanged: (_) => onToggleCompletada(tarea),
      ),
      title: Text(
        tarea.title,
        style: TextStyle(
          decoration: tarea.completed ? TextDecoration.lineThrough : null,
          color: tarea.completed
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      subtitle: Text(subtitulo),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Eliminar',
        onPressed: () => onEliminarTarea(tarea),
      ),
    ),
  );
}

Future<void> mostrarDialogoNuevaTarea({
  required BuildContext context,
  required TaskService taskService,
  required List<SubjectItem> asignaturas,
  required ValueChanged<TaskItem> onTareaCreada,
  DateTime? fechaInicial,
}) async {
  final tituloController = TextEditingController();
  final descripcionController = TextEditingController();
  int? asignaturaSeleccionadaId =
  asignaturas.isNotEmpty ? asignaturas.first.id : null;
  String tipoSeleccionado = 'tarea';
  DateTime fechaSeleccionada =
      fechaInicial ?? DateTime.now().add(const Duration(hours: 2));
  bool guardando = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
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
                    initialValue: tipoSeleccionado,
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
                  if (asignaturas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Crea primero una asignatura en Ajustes para poder asociar el evento.',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: asignaturaSeleccionadaId,
                      decoration: const InputDecoration(labelText: 'Asignatura'),
                      items: asignaturas
                          .where((s) => s.id != null)
                          .map(
                            (s) => DropdownMenuItem<int>(
                          value: s.id!,
                          child: Text(s.name),
                        ),
                      )
                          .toList(),
                      onChanged: (valor) {
                        setDialogState(() => asignaturaSeleccionadaId = valor);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule),
                    title: Text(_formatearFechaCorta(fechaSeleccionada)),
                    onTap: () async {
                      final fecha = await showDatePicker(
                        context: dialogCtx,
                        initialDate: fechaSeleccionada,
                        firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                        DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (fecha == null || !dialogCtx.mounted) return;
                      final hora = await showTimePicker(
                        context: dialogCtx,
                        initialTime: TimeOfDay.fromDateTime(fechaSeleccionada),
                      );
                      if (hora == null || !dialogCtx.mounted) return;
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
                onPressed: guardando ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: guardando
                    ? null
                    : () async {
                  final titulo = tituloController.text.trim();
                  final subjectId = asignaturaSeleccionadaId;
                  if (titulo.isEmpty || subjectId == null) {
                    return;
                  }

                  setDialogState(() => guardando = true);
                  try {
                    final nueva = TaskItem(
                      title: titulo,
                      description: descripcionController.text.trim().isEmpty
                          ? null
                          : descripcionController.text.trim(),
                      taskType: tipoSeleccionado,
                      startDate: fechaSeleccionada,
                      dueDate:
                      fechaSeleccionada.add(const Duration(hours: 1)),
                      subjectId: subjectId,
                    );
                    final creada = await taskService.createTask(nueva);
                    onTareaCreada(creada);
                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  } on DioException catch (e) {
                    if (!dialogCtx.mounted) return;
                    setDialogState(() => guardando = false);
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al guardar (${e.response?.statusCode ?? 'red'})',
                        ),
                      ),
                    );
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

class PantallaGestionAsignaturas extends StatefulWidget {
  final List<SubjectItem> asignaturasIniciales;
  final SubjectService subjectService;

  const PantallaGestionAsignaturas({
    super.key,
    required this.asignaturasIniciales,
    required this.subjectService,
  });

  @override
  State<PantallaGestionAsignaturas> createState() =>
      _PantallaGestionAsignaturasState();
}

class _PantallaGestionAsignaturasState
    extends State<PantallaGestionAsignaturas> {
  late List<SubjectItem> _asignaturas;

  @override
  void initState() {
    super.initState();
    _asignaturas = List<SubjectItem>.from(widget.asignaturasIniciales);
  }

  Future<void> _abrirDialogoNuevaAsignatura() async {
    final controller = TextEditingController();
    bool guardando = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva asignatura'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Cálculo, Bases de datos...',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: guardando ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: guardando
                      ? null
                      : () async {
                    final nombre = controller.text.trim();
                    if (nombre.isEmpty) return;
                    setDialogState(() => guardando = true);
                    try {
                      final creada = await widget.subjectService
                          .createSubject(name: nombre);
                      if (!mounted) return;
                      setState(() => _asignaturas.add(creada));
                      if (dialogCtx.mounted) {
                        Navigator.pop(dialogCtx);
                      }
                    } on DioException catch (e) {
                      if (!dialogCtx.mounted) return;
                      setDialogState(() => guardando = false);
                      ScaffoldMessenger.of(dialogCtx).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al guardar (${e.response?.statusCode ?? 'red'})',
                          ),
                        ),
                      );
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && context.mounted) {
          Navigator.pop(context, _asignaturas);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestionar asignaturas'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _asignaturas),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirDialogoNuevaAsignatura,
          icon: const Icon(Icons.add),
          label: const Text('Nueva asignatura'),
        ),
        body: _asignaturas.isEmpty
            ? const Center(
          child: Text('Aún no has creado ninguna asignatura.'),
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _asignaturas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final asignatura = _asignaturas[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.book_outlined),
                title: Text(asignatura.name),
              ),
            );
          },
        ),
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
  final TaskService _taskService = TaskService();
  final SubjectService _subjectService = SubjectService();
  List<TaskItem> _tareas = [];
  List<SubjectItem> _asignaturas = [];
  bool _cargando = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _errorMsg = null;
    });
    try {
      final resultados = await Future.wait([
        _taskService.getTasks(),
        _subjectService.getSubjects(),
      ]);
      final listaTareas = resultados[0] as List<TaskItem>;
      final listaAsignaturas = resultados[1] as List<SubjectItem>;
      listaTareas.sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (!mounted) return;
      setState(() {
        _tareas = listaTareas;
        _asignaturas = listaAsignaturas;
        _cargando = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg =
        'No se pudieron cargar los datos (${e.response?.statusCode ?? 'error de conexión'})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorMsg = 'Error inesperado al cargar los datos';
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
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _reemplazarTarea(TaskItem actualizada) {
    setState(() {
      final idx = _tareas.indexWhere((t) => t.id == actualizada.id);
      if (idx != -1) {
        _tareas[idx] = actualizada;
      }
      _tareas.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    });
  }

  Future<void> _alternarCompletada(TaskItem tarea) async {
    if (tarea.id == null) return;
    final candidata = tarea.copyWith(completed: !tarea.completed);
    try {
      final guardada = await _taskService.updateTask(candidata);
      if (!mounted) return;
      _reemplazarTarea(guardada);
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo actualizar (${e.response?.statusCode ?? 'red'})',
          ),
        ),
      );
    }
  }

  Future<void> _eliminarTarea(TaskItem tarea) async {
    if (tarea.id == null) return;
    try {
      await _taskService.deleteTask(tarea.id!);
      if (!mounted) return;
      setState(() {
        _tareas.removeWhere((t) => t.id == tarea.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evento eliminado')),
      );
    } on DioException catch (e) {
      debugPrint(
        'Error al eliminar tarea: ${e.response?.statusCode} - ${e.response?.data}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo eliminar (${e.response?.statusCode ?? 'red'})',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pestanas = [
      _InicioTab(
        tareas: _tareas,
        asignaturas: _asignaturas,
        cargando: _cargando,
        errorMsg: _errorMsg,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
        onToggleCompletada: _alternarCompletada,
        onEliminarTarea: _eliminarTarea,
        onReintentar: _cargarDatos,
        onIrACalendario: () => setState(() => _selectedIndex = 1),
      ),
      _CalendarioTab(
        tareas: _tareas,
        asignaturas: _asignaturas,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
        onToggleCompletada: _alternarCompletada,
        onEliminarTarea: _eliminarTarea,
      ),
      _TodosEventosTab(
        tareas: _tareas,
        taskService: _taskService,
        onTareaCreada: _agregarTarea,
        onToggleCompletada: _alternarCompletada,
        onEliminarTarea: _eliminarTarea,
      ),
      _AjustesTab(
        asignaturas: _asignaturas,
        subjectService: _subjectService,
        onAsignaturasActualizadas: (actualizadas) {
          setState(() => _asignaturas = actualizadas);
        },
        onCerrarSesion: _cerrarSesion,
      ),
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
  final List<SubjectItem> asignaturas;
  final bool cargando;
  final String? errorMsg;
  final TaskService taskService;
  final ValueChanged<TaskItem> onTareaCreada;
  final Future<void> Function(TaskItem) onToggleCompletada;
  final Future<void> Function(TaskItem) onEliminarTarea;
  final VoidCallback onReintentar;
  final VoidCallback onIrACalendario;

  const _InicioTab({
    required this.tareas,
    required this.asignaturas,
    required this.cargando,
    required this.errorMsg,
    required this.taskService,
    required this.onTareaCreada,
    required this.onToggleCompletada,
    required this.onEliminarTarea,
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
    return '$capitalizado, ${fecha.day} de${meses[fecha.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final proximosTres = tareas
        .where(
          (t) => !t.dueDate.isBefore(ahora.subtract(const Duration(minutes: 15))),
    )
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
                    final subtitulo =
                    tarea.description != null && tarea.description!.isNotEmpty
                        ? '${_formatearFechaCorta(tarea.dueDate)} ·${tarea.description}'
                        : _formatearFechaCorta(tarea.dueDate);
                    return _construirTileTarea(
                      context: context,
                      tarea: tarea,
                      subtitulo: subtitulo,
                      onToggleCompletada: onToggleCompletada,
                      onEliminarTarea: onEliminarTarea,
                    );
                  },
                ),
              ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => mostrarDialogoNuevaTarea(
              context: context,
              taskService: taskService,
              asignaturas: asignaturas,
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
  final List<SubjectItem> asignaturas;
  final TaskService taskService;
  final ValueChanged<TaskItem> onTareaCreada;
  final Future<void> Function(TaskItem) onToggleCompletada;
  final Future<void> Function(TaskItem) onEliminarTarea;

  const _CalendarioTab({
    required this.tareas,
    required this.asignaturas,
    required this.taskService,
    required this.onTareaCreada,
    required this.onToggleCompletada,
    required this.onEliminarTarea,
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
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (innerCtx, setSheetState) {
            final tareasDelDia =
            widget.tareas.where((t) => _esMismoDia(t.dueDate, dia)).toList();

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
                          final subtitulo = tarea.description != null &&
                              tarea.description!.isNotEmpty
                              ? '${_formatearHora(tarea.dueDate)} · ${tarea.description}'
                              : _formatearHora(tarea.dueDate);
                          return _construirTileTarea(
                            context: context,
                            tarea: tarea,
                            subtitulo: subtitulo,
                            onToggleCompletada: (t) async {
                              await widget.onToggleCompletada(t);
                              if (innerCtx.mounted) setSheetState(() {});
                            },
                            onEliminarTarea: (t) async {
                              await widget.onEliminarTarea(t);
                              if (innerCtx.mounted) setSheetState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetCtx);
                      if (!mounted) return;
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
                        asignaturas: widget.asignaturas,
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
  final Future<void> Function(TaskItem) onToggleCompletada;
  final Future<void> Function(TaskItem) onEliminarTarea;

  const _TodosEventosTab({
    required this.tareas,
    required this.taskService,
    required this.onTareaCreada,
    required this.onToggleCompletada,
    required this.onEliminarTarea,
  });

  @override
  Widget build(BuildContext context) {
    return tareas.isEmpty
        ? const Center(child: Text('No tienes ningún evento programado'))
        : ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tareas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = tareas[index];
        final subtitulo = t.description != null && t.description!.isNotEmpty
            ? '${_formatearFechaCorta(t.dueDate)} · ${t.description}'
            : _formatearFechaCorta(t.dueDate);
        return _construirTileTarea(
          context: context,
          tarea: t,
          subtitulo: subtitulo,
          onToggleCompletada: onToggleCompletada,
          onEliminarTarea: onEliminarTarea,
        );
      },
    );
  }
}

class _AjustesTab extends StatelessWidget {
  final List<SubjectItem> asignaturas;
  final SubjectService subjectService;
  final ValueChanged<List<SubjectItem>> onAsignaturasActualizadas;
  final VoidCallback onCerrarSesion;

  const _AjustesTab({
    required this.asignaturas,
    required this.subjectService,
    required this.onAsignaturasActualizadas,
    required this.onCerrarSesion,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.book_outlined),
          title: const Text('Gestionar asignaturas'),
          subtitle: Text(
            asignaturas.isEmpty
                ? 'Sin asignaturas creadas'
                : '${asignaturas.length} asignatura(s)',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final actualizadas = await Navigator.push<List<SubjectItem>>(
              context,
              MaterialPageRoute(
                builder: (_) => PantallaGestionAsignaturas(
                  asignaturasIniciales: asignaturas,
                  subjectService: subjectService,
                ),
              ),
            );
            if (actualizadas != null) {
              onAsignaturasActualizadas(actualizadas);
            }
          },
        ),
        const Divider(height: 32),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Cerrar sesión'),
          onTap: onCerrarSesion,
        ),
      ],
    );
  }
}