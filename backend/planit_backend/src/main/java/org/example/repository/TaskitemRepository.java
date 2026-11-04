package org.example.repository;

import org.example.model.Taskitem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TaskitemRepository extends JpaRepository<Taskitem, Integer> {

    //Metodo util para buscar todas las tareas asociadas a una asignatura específica
    List<Taskitem> findBySubjectId(Integer subjectId);
}