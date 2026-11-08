package org.example.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "task_items")
public class Taskitem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, length = 150)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "task_type", nullable = false, length = 20)
    private String taskType = "tarea";

    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;

    @Column(name = "due_date", nullable = false)
    private LocalDateTime dueDate;

    @Column(name = "reminder_frequency", length = 30)
    private String reminderFrequency = "progresivo";

    @Column(name = "reminder_active")
    private Boolean reminderActive = true;

    @Column(name = "completed")
    private Boolean completed = false;

    @Column(name = "subject_id", nullable = false)
    private Integer subjectId;

    // Relación con el usuario autenticado
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Taskitem() {}

    // Getters y Setters
    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getTaskType() { return taskType; }
    public void setTaskType(String taskType) { this.taskType = taskType; }

    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }

    public LocalDateTime getDueDate() { return dueDate; }
    public void setDueDate(LocalDateTime dueDate) { this.dueDate = dueDate; }

    public String getReminderFrequency() { return reminderFrequency; }
    public void setReminderFrequency(String reminderFrequency) { this.reminderFrequency = reminderFrequency; }

    public Boolean getReminderActive() { return reminderActive; }
    public void setReminderActive(Boolean reminderActive) { this.reminderActive = reminderActive; }

    public Boolean getCompleted() { return completed; }
    public void setCompleted(Boolean completed) { this.completed = completed; }

    public Integer getSubjectId() { return subjectId; }
    public void setSubjectId(Integer subjectId) { this.subjectId = subjectId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    //Getter y Setters para el Usuario
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

}