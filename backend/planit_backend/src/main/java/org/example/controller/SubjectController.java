package org.example.controller;

import org.example.model.Subject;
import org.example.model.User;
import org.example.repository.SubjectRepository;
import org.example.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/subjects")
public class SubjectController {

    @Autowired
    private SubjectRepository subjectRepository;

    @Autowired
    private UserRepository userRepository; // Inyectamos UserRepository para buscar al usuario por su token

    // Método auxiliar para obtener el usuario autenticado actual desde el token JWT
    private User getAuthenticatedUser(Authentication authentication) {
        String username = authentication.getName();
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado: " + username));
    }

    // Obtener solo las asignaturas del usuario autenticado
    @GetMapping
    public List<Subject> getAllSubjects(Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        return subjectRepository.findByUserId(user.getId());
    }

    // Crear una nueva asignatura vinculada automáticamente al usuario autenticado
    @PostMapping
    public Subject createSubject(@RequestBody Subject subject, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);
        subject.setUserId(user.getId()); // Asignamos el ID del usuario logueado
        return subjectRepository.save(subject);
    }

    // (Opcional pero recomendado) Eliminar una asignatura propia
    @DeleteMapping("/{id}")
    public String deleteSubject(@PathVariable Integer id, Authentication authentication) {
        User user = getAuthenticatedUser(authentication);

        Subject subject = subjectRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Asignatura no encontrada con ID: " + id));

        // Validar que la asignatura pertenezca al usuario autenticado
        if (!subject.getUserId().equals(user.getId())) {
            throw new RuntimeException("No tienes permiso para eliminar esta asignatura.");
        }

        subjectRepository.delete(subject);
        return "Asignatura con ID " + id + " eliminada correctamente.";
    }
}