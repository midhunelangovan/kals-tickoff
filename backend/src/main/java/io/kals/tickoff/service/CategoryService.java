package io.kals.tickoff.service;

import io.kals.core.exception.Exceptions.ResourceNotFoundException;
import io.kals.tickoff.dto.CategoryResponse;
import io.kals.tickoff.dto.CreateCategoryRequest;
import io.kals.tickoff.dto.UpdateCategoryRequest;
import io.kals.tickoff.entity.Category;
import io.kals.tickoff.entity.Habit;
import io.kals.tickoff.exception.DuplicateResourceException;
import io.kals.tickoff.repository.CategoryRepository;
import io.kals.tickoff.repository.HabitRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class CategoryService {

    private final CategoryRepository categoryRepository;
    private final HabitRepository habitRepository;

    @Transactional
    public CategoryResponse createCategory(CreateCategoryRequest request) {
        String trimmedName = request.getName() != null ? request.getName().trim() : "";
        if (trimmedName.isEmpty()) {
            throw new IllegalArgumentException("Category name cannot be blank");
        }

        if (categoryRepository.existsByNameIgnoreCase(trimmedName)) {
            throw new DuplicateResourceException("Category already exists: " + trimmedName);
        }

        Category category = Category.create(trimmedName);
        Category saved = categoryRepository.save(category);

        return toResponse(saved);
    }

    @Transactional(readOnly = true)
    public List<CategoryResponse> listCategories() {
        return categoryRepository.findAllByOrderByCreatedAtAsc().stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional
    public CategoryResponse updateCategory(String id, UpdateCategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("NOT_FOUND", "Category not found: " + id));

        String trimmedName = request.getName() != null ? request.getName().trim() : "";
        if (trimmedName.isEmpty()) {
            throw new IllegalArgumentException("Category name cannot be blank");
        }

        if (categoryRepository.existsByNameIgnoreCaseAndIdNot(trimmedName, id)) {
            throw new DuplicateResourceException("Category already exists: " + trimmedName);
        }

        category.setName(trimmedName);
        Category saved = categoryRepository.save(category);

        return toResponse(saved);
    }

    @Transactional
    public void deleteCategory(String id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("NOT_FOUND", "Category not found: " + id));

        // Unlink habits without deleting them
        List<Habit> habits = habitRepository.findByCategoryId(id);
        for (Habit habit : habits) {
            habit.setCategoryId(null);
        }
        habitRepository.saveAll(habits);

        categoryRepository.delete(category);
    }

    public CategoryResponse toResponse(Category category) {
        return CategoryResponse.builder()
                .id(category.getId())
                .name(category.getName())
                .createdAt(category.getCreatedAt())
                .build();
    }
}
