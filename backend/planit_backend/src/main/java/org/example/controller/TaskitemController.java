package org.example.controller;

import org.example.model.Taskitem;
import org.example.model.User;
import org.example.repository.TaskitemRepository;
import org.example.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tasks")
public class TaskitemController {

    @Autowired
    private TaskitemRepository taskitemRepository;

    @Autowired
    private UserRepository userRepository;

    // Método auxiliar para obtener el usuario autenticado actual desde el token JWT
    private User getAuthenticatedUser(Authentication authentication) {
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado: " + username));
    }

    // 1. Obtener solo las tareas del usuario autenticado
    @GetMapping
    public List<Taskitem> getAllTasks(Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        return taskitemRepository.findByUser(user);
    }

    // 2. Crear una nueva tarea vinculada al usuario autenticado
    @PostMapping
    public Taskitem createTask(@RequestBody Taskitem taskItem, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        taskItem.setUser(user); // Asignamos el usuario del token
        return taskitemRepository.save(taskItem);
    }

    // 3. Obtener tareas por el ID de la asignatura, pero filtradas por el usuario logueado
    @GetMapping("/subject/{subjectId}")
    public List<Taskitem> getTasksBySubject(@PathVariable Integer subjectId, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        return taskitemRepository.findByUserAndSubjectId(user, subjectId);
    }

    // 4. Actualizar una tarea existente (verificando que sea del usuario)
    @PutMapping("/{id}")
    public Taskitem updateTask(@PathVariable Integer id, @RequestBody Taskitem taskDetails, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);

        Taskitem task = taskitemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada con ID: " + id));

        // Validar que la tarea pertenezca al usuario autenticado
        if (!task.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("No tienes permiso para modificar esta tarea.");
        }

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

    // 5. Eliminar una tarea por su ID (verificando que sea del usuario)
    @DeleteMapping("/{id}")
    public String deleteTask(@PathVariable Integer id, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);

        Taskitem task = taskitemRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Tarea no encontrada con ID: " + id));

        // Validar que la tarea pertenezca al usuario autenticado
        if (!task.getUser().getId().equals(user.getId())) {
            throw new RuntimeException("No tienes permiso para eliminar esta tarea.");
        }

        taskitemRepository.delete(task);
        return "Tarea con ID " + id + " eliminada correctamente.";
    }
}