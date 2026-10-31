-- Фізична схема БД ПП FineMotor AR Trainer (СКБД PostgreSQL)

DROP TABLE IF EXISTS results;
DROP TABLE IF EXISTS recommendations;
DROP TABLE IF EXISTS movement_errors;
DROP TABLE IF EXISTS assessments;
DROP TABLE IF EXISTS current_movements;
DROP TABLE IF EXISTS movements;
DROP TABLE IF EXISTS markers;
DROP TABLE IF EXISTS fingers;
DROP TABLE IF EXISTS selections;
DROP TABLE IF EXISTS instructions;
DROP TABLE IF EXISTS exercises;
DROP TABLE IF EXISTS users;

-- Користувач
create table users (
    user_id   INTEGER NOT NULL,
    CONSTRAINT users_pk PRIMARY KEY(user_id)
)
;

-- Вправа
CREATE TABLE exercises (
    exercise_id INTEGER NOT NULL,
    exercise_name VARCHAR(100)  NOT NULL ,
    difficulty_level VARCHAR(20) NOT NULL,
    CONSTRAINT exercises_pk PRIMARY KEY (exercise_id),
    CONSTRAINT exercises_name_uq UNIQUE (exercise_name),
    -- регулярний вираз: 3-100 українських літер, пробіл або дефіс
    CONSTRAINT exercises_name_ck CHECK (
        exercise_name ~ '^[А-ЯІЇЄҐа-яіїєґ -]{3,100}$'
    ),
    CONSTRAINT exercises_level_ck CHECK (
        difficulty_level IN ('легкий', 'середній', 'складний')
    )
);

-- Інструкція виконання вправи
CREATE TABLE instructions (
    instruction_id INTEGER NOT NULL,
    exercise_id INTEGER NOT NULL,
    movement_sequence VARCHAR(1000) NOT NULL,
    repetition_num SMALLINT NOT NULL,
    allowed_amplitude REAL NOT NULL,
    CONSTRAINT instructions_pk PRIMARY KEY (instruction_id),
    CONSTRAINT instructions_exercise_uq UNIQUE (exercise_id),
    CONSTRAINT instructions_exercise_fk FOREIGN KEY (exercise_id)
    REFERENCES exercises (exercise_id),
    CONSTRAINT instructions_repetition_ck CHECK (
        repetition_num BETWEEN 1 AND 50
    ),
    CONSTRAINT instructions_amplitude_ck CHECK (
        allowed_amplitude BETWEEN 0 AND 180
    )
);

-- Асоціація «Користувач обирає Вправу»
CREATE TABLE selections (
    user_id INTEGER NOT NULL,
    exercise_id INTEGER NOT NULL,
    CONSTRAINT selections_pk PRIMARY KEY (user_id, exercise_id),
    CONSTRAINT selections_user_fk FOREIGN KEY (user_id)
    REFERENCES users (user_id),
    CONSTRAINT selections_exercise_fk FOREIGN KEY (exercise_id)
    REFERENCES exercises (exercise_id)
);

-- Палець
CREATE TABLE fingers (
    finger_id INTEGER NOT NULL,
    CONSTRAINT fingers_pk PRIMARY KEY (finger_id)
);

-- Паперовий маркер
CREATE TABLE markers (
    marker_id INTEGER NOT NULL,
    finger_id INTEGER NOT NULL,
    graphic_template VARCHAR(50) NOT NULL,
    CONSTRAINT markers_pk PRIMARY KEY (marker_id),
    CONSTRAINT markers_finger_uq UNIQUE (finger_id),
    CONSTRAINT markers_template_uq UNIQUE (graphic_template),
    CONSTRAINT markers_finger_fk FOREIGN KEY (finger_id)
    REFERENCES fingers (finger_id)
);

-- Параметри руху пальців
CREATE TABLE movements (
    movement_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    marker_id INTEGER NOT NULL,
    marker_position VARCHAR(50) NOT NULL,
    fixation_date TIMESTAMP NOT NULL,
    CONSTRAINT movements_pk PRIMARY KEY (movement_id),
    CONSTRAINT movements_user_fk FOREIGN KEY (user_id)
    REFERENCES users (user_id),
    CONSTRAINT movements_marker_fk FOREIGN KEY (marker_id)
    REFERENCES markers (marker_id),
    -- регулярний вираз: три дійсні числа X;Y;Z, наприклад 12.5;-3.0;40.2
    CONSTRAINT movements_position_ck CHECK (
        marker_position ~ '^-?[0-9]+(\.[0-9]+)?(;-?[0-9]+(\.[0-9]+)?){2}$'
    )
);

-- Поточні параметри руху пальців (успадковує movements)
CREATE TABLE current_movements (
    movement_id INTEGER NOT NULL,
    CONSTRAINT current_movements_pk PRIMARY KEY (movement_id),
    CONSTRAINT current_movements_fk FOREIGN KEY (movement_id)
    REFERENCES movements (movement_id)
);

-- Оцінка правильності руху пальця
CREATE TABLE assessments (
    assessment_id INTEGER NOT NULL,
    movement_id INTEGER NOT NULL,
    assessment_value VARCHAR(20) NOT NULL,
    CONSTRAINT assessments_pk PRIMARY KEY (assessment_id),
    CONSTRAINT assessments_movement_uq UNIQUE (movement_id),
    CONSTRAINT assessments_movement_fk FOREIGN KEY (movement_id)
    REFERENCES current_movements (movement_id),
    CONSTRAINT assessments_value_ck CHECK (
        assessment_value IN ('правильно', 'неправильно')
    )
);

-- Помилка руху пальця
CREATE TABLE movement_errors (
    error_id INTEGER NOT NULL,
    assessment_id INTEGER NOT NULL,
    error_type VARCHAR(50) NOT NULL,
    CONSTRAINT movement_errors_pk PRIMARY KEY (error_id),
    CONSTRAINT movement_errors_assessment_uq UNIQUE (assessment_id),
    CONSTRAINT movement_errors_assessment_fk FOREIGN KEY (assessment_id)
    REFERENCES assessments (assessment_id),
    CONSTRAINT movement_errors_type_ck CHECK (
        error_type IN (
            'неправильний палець',
            'неправильний напрямок руху',
            'перенапруження'
        )
    )
);

-- Рекомендація щодо виправлення руху пальця
CREATE TABLE recommendations (
    recommendation_id INTEGER NOT NULL,
    error_id INTEGER NOT NULL,
    finger_id INTEGER NOT NULL,
    recommendation_text VARCHAR(255) NOT NULL,
    CONSTRAINT recommendations_pk PRIMARY KEY (recommendation_id),
    CONSTRAINT recommendations_error_uq UNIQUE (error_id),
    CONSTRAINT recommendations_error_fk FOREIGN KEY (error_id)
    REFERENCES movement_errors (error_id),
    CONSTRAINT recommendations_finger_fk FOREIGN KEY (finger_id)
    REFERENCES fingers (finger_id)
);

-- Результат виконання вправи
CREATE TABLE results (
    result_id INTEGER NOT NULL,
    user_id INTEGER NOT NULL,
    exercise_id INTEGER NOT NULL,
    finger_amplitude REAL NOT NULL,
    accuracy REAL NOT NULL,
    duration_num INTEGER NOT NULL,
    CONSTRAINT results_pk PRIMARY KEY (result_id),
    CONSTRAINT results_user_fk FOREIGN KEY (user_id)
    REFERENCES users (user_id),
    CONSTRAINT results_exercise_fk FOREIGN KEY (exercise_id)
    REFERENCES exercises (exercise_id),
    CONSTRAINT results_amplitude_ck CHECK (
        finger_amplitude BETWEEN 0 AND 180
    ),
    CONSTRAINT results_accuracy_ck CHECK (accuracy BETWEEN 0 AND 100),
    CONSTRAINT results_duration_ck CHECK (duration_num>0)
)
