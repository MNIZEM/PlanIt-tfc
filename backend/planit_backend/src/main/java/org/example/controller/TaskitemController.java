package org.example.controller;

import org.example.model.Taskitem;
import org.example.repository.TaskitemRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
public class TaskitemController {

    @Autowired
    private TaskitemRepository taskitemRepository;

    //Obtener todas las tareas
    @GetMapping
    public List<Taskitem> getAllTasks() {
        return taskitemRepository.findAll();
    }

    //Crear una nueva tarea
    @PostMapping
    public Taskitem createTask(@RequestBody Taskitem taskItem) {
        return taskitemRepository.save(taskItem);
    }

    //Obtener tareas por el ID de la asignatura
    @GetMapping("/subject/{subjectId}")
    public List<Taskitem> getTasksBySubject(@PathVariable Integer subjectId) {
        return taskitemRepository.findBySubjectId(subjectId);
    }

    // Actualizar una tarea existente
    @PutMapping("/{id}")
    public Taskitem updateTask(@PathVariable Integer id, @RequestBody Taskitem taskDetails) {
        Taskitem task = taskitemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada con ID: " + id));

        task.setTitle(taskDetails.getTitle());
        task.setDescription(taskDetails.getDescription());
        task.setTaskType(taskDetails.getTaskType());
        task.setStartDate(taskDetails.getStartDate());
        task.setDueDate(taskDetails.getDueDate());
        task.setReminderFrequency(taskDetails.getReminderFrequency());
        task.setReminderActive(taskDetails.getReminderActive());
        task.setCompleted(taskDetails.getCompleted());
        task.setSubjectId(taskDetails.getSubjectId());

        return taskitemRepository.save(task);
    }

    // Eliminar una tarea por su ID
    @DeleteMapping("/{id}")
    public String deleteTask(@PathVariable Integer id) {
        Taskitem task = taskitemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada con ID: " + id));

        taskitemRepository.delete(task);
        return "Tarea con ID " + id + " eliminada correctamente.";
    }
}