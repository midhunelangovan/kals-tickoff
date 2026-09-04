CREATE TABLE categories (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL
);

ALTER TABLE habits ADD COLUMN category_id VARCHAR(36) NULL REFERENCES categories(id) ON DELETE SET NULL;
ALTER TABLE habits ADD COLUMN description VARCHAR(255) NULL;
ALTER TABLE habits ADD COLUMN color VARCHAR(50) NULL;

CREATE INDEX idx_categories_name ON categories (name);
CREATE INDEX idx_habits_category_id ON habits (category_id);
