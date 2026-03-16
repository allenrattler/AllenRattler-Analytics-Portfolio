
-- ========================================
-- EDUCATION ANALYTICS DATABASE SCHEMA
-- ========================================
-- Project: Student Performance Gap Analysis
-- Author: Allen
-- Date: March 2026
-- Purpose: Create database schema and import CSV data for analyzing
--          place value vs. regrouping performance gaps
-- ========================================

-- Set up the database and schema
SET search_path TO education;

-- ========================================
-- TABLE CREATION
-- ========================================

-- Students table: Core demographic information
CREATE TABLE students (
    student_id VARCHAR(10) PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    grade_level INTEGER,  -- Grades 2, 3, or 4
    date_of_birth DATE
);

-- Teachers table: Instructor information
CREATE TABLE teachers (
    teacher_id VARCHAR(10) PRIMARY KEY,
    teacher_name VARCHAR(100) NOT NULL,
    grade_level INTEGER NOT NULL,  -- Grade they teach
    classroom VARCHAR(10) NOT NULL  -- Room identifier (e.g., '2A', '3B')
);

-- Student assignments: Links students to their teachers
CREATE TABLE student_assignments (
    assignment_id VARCHAR(10) PRIMARY KEY,
    student_id VARCHAR(10) REFERENCES students(student_id),
    teacher_id VARCHAR(10) REFERENCES teachers(teacher_id),
    school_year VARCHAR(10) NOT NULL  -- e.g., '2024-2025'
);

-- Assessments: High-level assessment metadata
CREATE TABLE assessments (
    assessment_id VARCHAR(10) PRIMARY KEY,
    assessment_name VARCHAR(100) NOT NULL,
    skill_category VARCHAR(100) NOT NULL,  -- 'Place Value', '3-Digit Addition', '3-Digit Addition - Regrouping'
    date_administered DATE NOT NULL,
    total_questions INTEGER NOT NULL
);

-- Assessment questions: Individual question details
CREATE TABLE assessment_questions (
    question_id VARCHAR(10) PRIMARY KEY,
    assessment_id VARCHAR(10) REFERENCES assessments(assessment_id),
    question_number INTEGER NOT NULL,
    skill_tag VARCHAR(100),  -- Specific skill tested (e.g., 'regroup ones to tens')
    difficulty VARCHAR(20),  -- 'easy', 'medium', 'hard'
    points_possible INTEGER NOT NULL
);

-- Student responses: Individual answer records (FACT TABLE)
-- This is the largest table with 10,000+ records
CREATE TABLE student_responses (
    response_id VARCHAR(20) PRIMARY KEY,
    student_id VARCHAR(10) REFERENCES students(student_id),
    assessment_id VARCHAR(10) REFERENCES assessments(assessment_id),
    question_id VARCHAR(10) REFERENCES assessment_questions(question_id),
    is_correct INTEGER NOT NULL,  -- 1 = correct, 0 = incorrect
    response_timestamp TIMESTAMP NOT NULL
);

-- Skill standards: Mastery threshold definitions
CREATE TABLE skill_standards (
    standard_id VARCHAR(10) PRIMARY KEY,
    skill_category VARCHAR(100) NOT NULL,
    mastery_threshold NUMERIC(5,2) NOT NULL  -- Percentage required for mastery (e.g., 75.00)
);

-- ========================================
-- DATA IMPORT COMMANDS
-- ========================================
-- Note: Update file paths to match your local directory
-- Import order matters due to foreign key constraints:
-- 1. Parent tables first (students, teachers, assessments, skill_standards)
-- 2. Junction/child tables second (student_assignments, assessment_questions)
-- 3. Fact table last (student_responses)

\COPY students FROM '/path/to/students.csv' CSV HEADER;
\COPY teachers FROM '/path/to/teachers.csv' CSV HEADER;
\COPY assessments FROM '/path/to/assessments.csv' CSV HEADER;
\COPY skill_standards FROM '/path/to/skill_standards.csv' CSV HEADER;
\COPY student_assignments FROM '/path/to/student_assignments.csv' CSV HEADER;
\COPY assessment_questions FROM '/path/to/assessment_questions.csv' CSV HEADER;
\COPY student_responses FROM '/path/to/student_responses.csv' CSV HEADER;

-- ========================================
-- CREATE INDEXES FOR QUERY PERFORMANCE
-- ========================================
-- These indexes speed up JOIN operations and filtering

CREATE INDEX idx_student_responses_student ON student_responses(student_id);
CREATE INDEX idx_student_responses_assessment ON student_responses(assessment_id);
CREATE INDEX idx_student_responses_question ON student_responses(question_id);
CREATE INDEX idx_assessment_questions_assessment ON assessment_questions(assessment_id);
CREATE INDEX idx_student_assignments_student ON student_assignments(student_id);
CREATE INDEX idx_student_assignments_teacher ON student_assignments(teacher_id);

-- ========================================
-- VERIFY DATA IMPORT
-- ========================================
-- Quick counts to confirm data loaded correctly

SELECT 'students' AS table_name, COUNT(*) AS row_count FROM students
UNION ALL
SELECT 'teachers', COUNT(*) FROM teachers
UNION ALL
SELECT 'student_assignments', COUNT(*) FROM student_assignments
UNION ALL
SELECT 'assessments', COUNT(*) FROM assessments
UNION ALL
SELECT 'assessment_questions', COUNT(*) FROM assessment_questions
UNION ALL
SELECT 'student_responses', COUNT(*) FROM student_responses
UNION ALL
SELECT 'skill_standards', COUNT(*) FROM skill_standards;

-- Expected counts:
-- students: 180
-- teachers: 7
-- student_assignments: 180
-- assessments: 4
-- assessment_questions: 55
-- student_responses: 10,198 (before cleaning)
-- skill_standards: 3