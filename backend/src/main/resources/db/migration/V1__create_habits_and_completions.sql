CREATE TABLE habits (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL,
    archived BOOLEAN NOT NULL DEFAULT 0
);

CREATE TABLE habit_completions (
    id VARCHAR(36) PRIMARY KEY,
    habit_id VARCHAR(36) NOT NULL,
    completion_date DATE NOT NULL,
    created_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_habit_completions_habit FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
    CONSTRAINT uq_habit_completion_date UNIQUE (habit_id, completion_date)
);

CREATE INDEX idx_habits_archived_created ON habits (archived, created_at DESC);
CREATE INDEX idx_completions_habit_id ON habit_completions (habit_id);
CREATE INDEX idx_completions_date ON habit_completions (completion_date);
CREATE INDEX idx_completions_habit_date ON habit_completions (habit_id, completion_date);
