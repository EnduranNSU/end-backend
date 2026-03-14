-- Создание таблицы exercises
CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL UNIQUE,
    tags VARCHAR[] NOT NULL,
    hrefs VARCHAR[] NOT NULL
);

-- Создание таблицы trainings
CREATE TABLE trainings (
    id SERIAL PRIMARY KEY,
    title VARCHAR NOT NULL
);

-- Создание таблицы users
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR NOT NULL UNIQUE,
    name VARCHAR NOT NULL,
    hashed_password VARCHAR NOT NULL
);

-- Создание индекса для users
CREATE INDEX ix_users_id ON users (id);

-- Создание таблицы measurements
CREATE TABLE measurements (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    type VARCHAR NOT NULL,
    value INTEGER NOT NULL,
    date VARCHAR NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Создание индекса для measurements
CREATE INDEX ix_measurements_user_id ON measurements (user_id);

-- Создание таблицы perfomable_exercises (обратите внимание на опечатку в имени)
CREATE TABLE perfomable_exercises (
    id SERIAL PRIMARY KEY,
    exercise_id INTEGER NOT NULL,
    training_id INTEGER NOT NULL,
    FOREIGN KEY (exercise_id) REFERENCES exercises (id),
    FOREIGN KEY (training_id) REFERENCES trainings (id)
);

-- Создание таблицы planned_trainings
CREATE TABLE planned_trainings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    training_id INTEGER NOT NULL UNIQUE,
    weekdays VARCHAR[],
    FOREIGN KEY (training_id) REFERENCES trainings (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Создание индексов для planned_trainings
CREATE INDEX ix_planned_trainings_user_id ON planned_trainings (user_id);
CREATE INDEX ix_planned_trainings_training_id ON planned_trainings (training_id);

-- Создание таблицы user_performed_trainings
CREATE TABLE user_performed_trainings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    training_id INTEGER NOT NULL UNIQUE,
    date VARCHAR NOT NULL,
    FOREIGN KEY (training_id) REFERENCES trainings (id),
    FOREIGN KEY (user_id) REFERENCES users (id)
);

-- Создание индексов для user_performed_trainings
CREATE INDEX ix_user_performed_trainings_user_id ON user_performed_trainings (user_id);
CREATE INDEX ix_user_performed_trainings_training_id ON user_performed_trainings (training_id);

-- Создание таблицы sets
CREATE TABLE sets (
    id SERIAL PRIMARY KEY,
    weight INTEGER,
    repetitions INTEGER,  -- Переименовано из repetions в repetitions
    rest_duration INTEGER,
    perfomable_exercise_id INTEGER NOT NULL,
    FOREIGN KEY (perfomable_exercise_id) REFERENCES perfomable_exercises (id)
);

-- Создание индекса для sets
CREATE INDEX ix_sets_perfomable_exercise_id ON sets (perfomable_exercise_id);