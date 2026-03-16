-- ========================================
-- DATA CLEANING AND QUALITY ASSURANCE
-- ========================================
-- Project: Student Performance Gap Analysis
-- Author: Allen Rattler
-- Date: March 2026
-- Purpose: Identify and resolve data quality issues before analysis
--          Issues found: duplicates, missing values, inconsistent data
-- ========================================

SET search_path TO education;

-- ========================================
-- STEP 1: IDENTIFY DATA QUALITY ISSUES
-- ========================================

-- Issue 1: Check for duplicate student responses
-- Business Impact: Duplicate responses inflate success rates and skew analysis
SELECT 
    student_id,
    question_id,
    assessment_id,
    COUNT(*) AS duplicate_count
FROM student_responses
GROUP BY student_id, question_id, assessment_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
-- Result: Found 298 duplicate responses (2.92% of total)

-- Issue 2: Check for missing grade levels
-- Business Impact: Can't analyze performance by grade without this data
SELECT 
    COUNT(*) AS missing_grade_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM students), 2) AS pct_missing
FROM students
WHERE grade_level IS NULL;
-- Result: 13 students (7.22%) missing grade level

-- Issue 3: Check for missing teacher assignments
-- Business Impact: Can't identify which teachers need support
SELECT 
    COUNT(*) AS missing_teacher_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM students), 2) AS pct_missing
FROM students s
LEFT JOIN student_assignments sa ON s.student_id = sa.student_id
WHERE sa.teacher_id IS NULL;
-- Result: 19 students (10.56%) missing teacher assignments

-- Issue 4: Check for missing skill tags on questions
-- Business Impact: Can't identify specific skill gaps without tags
SELECT 
    a.assessment_id,
    a.skill_category,
    COUNT(*) AS total_questions,
    COUNT(aq.skill_tag) AS questions_with_tags,
    COUNT(*) - COUNT(aq.skill_tag) AS missing_tags
FROM assessments a
LEFT JOIN assessment_questions aq ON a.assessment_id = aq.assessment_id
GROUP BY a.assessment_id, a.skill_category
HAVING COUNT(*) - COUNT(aq.skill_tag) > 0;
-- Result: 4 questions missing skill tags (~7% of questions)

-- ========================================
-- STEP 2: REMOVE DUPLICATE RESPONSES
-- ========================================
-- Strategy: Keep the first response for each student-question-assessment combination
-- Using ROW_NUMBER() to identify duplicates, then delete all but the first

WITH duplicates_to_remove AS (
    SELECT 
        response_id,
        ROW_NUMBER() OVER (
            PARTITION BY student_id, question_id, assessment_id 
            ORDER BY response_id
        ) AS row_num
    FROM student_responses
)
DELETE FROM student_responses
WHERE response_id IN (
    SELECT response_id 
    FROM duplicates_to_remove 
    WHERE row_num > 1
);
-- Result: Deleted 298 duplicate records

-- Verify: Check that all responses are now unique
SELECT 
    COUNT(*) AS total_responses,
    COUNT(DISTINCT CONCAT(student_id, question_id, assessment_id)) AS unique_combinations
FROM student_responses;
-- Result: Both should be 9,900 (equal = no duplicates remain)

-- ========================================
-- STEP 3: FIX MISSING GRADE LEVELS
-- ========================================
-- Strategy: Assign default grade based on most common grade (Grade 3)
-- Rationale: Grade 3 has 80 students vs 51 in Grade 2, 49 in Grade 4

UPDATE students
SET grade_level = 3  -- Most common grade level
WHERE grade_level IS NULL;
-- Result: Updated 13 students

-- Verify: No missing grades remain
SELECT COUNT(*) AS missing_grades
FROM students
WHERE grade_level IS NULL;
-- Result: 0 (all grades now populated)

-- ========================================
-- STEP 4: FIX MISSING TEACHER ASSIGNMENTS
-- ========================================
-- Strategy: Match students to teachers by grade level
-- Assumption: Students should be assigned to a teacher teaching their grade

UPDATE student_assignments sa
SET teacher_id = (
    SELECT t.teacher_id
    FROM teachers t
    JOIN students s ON s.student_id = sa.student_id
    WHERE t.grade_level = s.grade_level
    LIMIT 1  -- If multiple teachers for same grade, take first one
)
WHERE sa.teacher_id IS NULL;
-- Result: Updated 19 student assignments

-- Verify: All students now have teacher assignments
SELECT COUNT(*) AS unassigned_students
FROM students s
LEFT JOIN student_assignments sa ON s.student_id = sa.student_id
WHERE sa.teacher_id IS NULL;
-- Result: 0 (all students now assigned)

-- ========================================
-- STEP 5: FIX MISSING SKILL TAGS
-- ========================================
-- Strategy: Generate skill tag from assessment category + "General"
-- Example: "3-Digit Addition - General" for questions without specific tags

UPDATE assessment_questions aq
SET skill_tag = a.skill_category || ' - General'
FROM assessments a
WHERE aq.assessment_id = a.assessment_id
  AND aq.skill_tag IS NULL;
-- Result: Updated 4 questions

-- Verify: All questions now have skill tags
SELECT 
    a.assessment_id,
    a.skill_category,
    COUNT(*) AS total_questions,
    COUNT(aq.skill_tag) AS questions_with_tags,
    COUNT(*) - COUNT(aq.skill_tag) AS missing_tags
FROM assessments a
LEFT JOIN assessment_questions aq ON a.assessment_id = aq.assessment_id
GROUP BY a.assessment_id, a.skill_category;
-- Result: missing_tags = 0 for all assessments

-- ========================================
-- FINAL DATA QUALITY SUMMARY
-- ========================================
-- Run this query to confirm all issues are resolved

SELECT 
    'Duplicate Responses' AS issue,
    COUNT(*) - COUNT(DISTINCT CONCAT(student_id, question_id, assessment_id)) AS count
FROM student_responses

UNION ALL

SELECT 
    'Missing Grade Levels',
    COUNT(*)
FROM students
WHERE grade_level IS NULL

UNION ALL

SELECT 
    'Missing Teacher Assignments',
    COUNT(*)
FROM students s
LEFT JOIN student_assignments sa ON s.student_id = sa.student_id
WHERE sa.teacher_id IS NULL

UNION ALL

SELECT 
    'Missing Skill Tags',
    COUNT(*)
FROM assessment_questions
WHERE skill_tag IS NULL;

-- Expected Result: All counts should be 0
-- Final clean dataset: 9,900 unique student responses, ready for analysis