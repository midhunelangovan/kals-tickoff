package io.kals.tickoff.repository;

import io.kals.tickoff.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CategoryRepository extends JpaRepository<Category, String> {

    List<Category> findAllByOrderByCreatedAtAsc();

    boolean existsByNameIgnoreCase(String name);

    boolean existsByNameIgnoreCaseAndIdNot(String name, String id);

    Optional<Category> findByNameIgnoreCase(String name);
}
