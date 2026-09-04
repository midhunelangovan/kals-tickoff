ALTER TABLE habits ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS habit_notes (
    id VARCHAR(36) PRIMARY KEY,
    habit_id VARCHAR(36) NOT NULL,
    note_date DATE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL,
    CONSTRAINT fk_habit_notes_habit FOREIGN KEY (habit_id) REFERENCES habits (id) ON DELETE CASCADE,
    CONSTRAINT uq_habit_note_date UNIQUE (habit_id, note_date)
);

CREATE INDEX IF NOT EXISTS idx_habits_sort_order ON habits (archived, sort_order, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notes_habit_id ON habit_notes (habit_id);
CREATE INDEX IF NOT EXISTS idx_notes_date ON habit_notes (note_date);
CREATE INDEX IF NOT EXISTS idx_notes_habit_date ON habit_notes (habit_id, note_date);
