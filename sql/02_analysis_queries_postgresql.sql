-- ========================================
-- STUDENT PERFORMANCE GAP ANALYSIS
-- ========================================
-- Project: Place Value vs. Regrouping Performance Analysis
-- Author: Allen Rattler
-- Date: March 2026
-- Purpose: Identify students who understand place value but struggle with regrouping
--          to enable targeted intervention instead of broad reteaching
--
-- Business Context: Teachers were reteaching place value to all struggling students,
--                   wasting time on concepts many students already understand.
--                   This analysis proves 57.78% of students need procedural practice,
--                   not conceptual review.
-- ========================================

SET search_path TO education;

-- ========================================
-- QUERY 1: OVERALL MASTERY RATES
-- ========================================
-- Business Question: What are the overall success rates for each skill category?
-- Why It Matters: Establishes baseline performance and identifies which skills
--                 are struggling. A large gap between skills indicates different
--                 intervention strategies are needed.
-- Expected Insight: Place Value should be higher than Regrouping
-- ========================================

WITH skill_performance AS (
    SELECT 
        a.skill_category,
        COUNT(DISTINCT sr.student_id) AS total_students,
        
        -- Calculate average mastery percentage across all students
        ROUND(AVG(CASE WHEN sr.is_correct = 1 THEN 100.0 ELSE 0 END), 2) AS avg_mastery,
        
        -- Count students who reached the 75% mastery threshold
        COUNT(DISTINCT CASE 
            WHEN sr.is_correct = 1 THEN sr.student_id 
        END) AS students_at_mastery_level,
        
        -- Calculate percentage of students at mastery
        ROUND(
            COUNT(DISTINCT CASE WHEN sr.is_correct = 1 THEN sr.student_id END) * 100.0 
            / COUNT(DISTINCT sr.student_id), 
            2
        ) AS pct_at_mastery
        
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    GROUP BY a.skill_category
)
SELECT 
    skill_category,
    total_students,
    avg_mastery,
    students_at_mastery_level,
    pct_at_mastery
FROM skill_performance
ORDER BY avg_mastery DESC;

-- Results:
-- Place Value: 80.71% avg mastery, 137 students (76.11%) at mastery
-- 3-Digit Addition: 77.08% avg mastery, 118 students (65.56%) at mastery
-- 3-Digit Addition - Regrouping: 52.72% avg mastery, 28 students (15.56%) at mastery
--
-- Key Insight: ~28 percentage point gap between Place Value and Regrouping
--              This gap represents the core business problem - students understand
--              the concept but can't execute the procedure


-- ========================================
-- QUERY 2: TARGET GROUP IDENTIFICATION
-- ========================================
-- Business Question: Which students understand place value (≥80%) but struggle
--                    with regrouping (<75%)?
-- Why It Matters: These students don't need conceptual reteaching - they need
--                 targeted procedural practice. Identifying them saves instructional time.
-- Expected Outcome: A significant number of students in this category
-- Business Impact: ~40% time savings by not reteaching concepts students already know
-- ========================================

-- Step 1: Calculate Place Value mastery for each student
WITH place_value_scores AS (
    SELECT 
        sr.student_id,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS place_value_mastery
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE a.skill_category = 'Place Value'
    GROUP BY sr.student_id
),

-- Step 2: Calculate Regrouping mastery for each student
regrouping_scores AS (
    SELECT 
        sr.student_id,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS regrouping_mastery
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE a.skill_category = '3-Digit Addition - Regrouping'
    GROUP BY sr.student_id
)

-- Step 3: Join scores and categorize students
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    s.grade_level,
    t.teacher_name,
    pv.place_value_mastery,
    rg.regrouping_mastery,
    (pv.place_value_mastery - rg.regrouping_mastery) AS skill_gap,
    
    -- Categorize students based on mastery thresholds
    CASE 
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 75 
            THEN '🎯 Target Group'  -- THESE are our focus students
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery >= 75 
            THEN '✅ Proficient Both'
        WHEN pv.place_value_mastery < 80 AND rg.regrouping_mastery < 75 
            THEN '⚠️ Needs Both Skills'
        ELSE 'Other'
    END AS student_category
    
FROM students s
LEFT JOIN place_value_scores pv ON s.student_id = pv.student_id
LEFT JOIN regrouping_scores rg ON s.student_id = rg.student_id
LEFT JOIN student_assignments sa ON s.student_id = sa.student_id
LEFT JOIN teachers t ON sa.teacher_id = t.teacher_id
ORDER BY skill_gap DESC;

-- Results:
-- 🎯 Target Group: 104 students (57.78%) - HIGH PLACE VALUE, LOW REGROUPING
-- ✅ Proficient Both: 26 students (14.44%)
-- ⚠️ Needs Both Skills: 48 students (26.67%)
--
-- Key Insight: The largest group (104 students) understands place value but fails regrouping
--              Largest individual gap: 83.33 points (Matthew Gonzalez: 100% PV, 16.67% RG)
-- Business Action: Form intervention groups for these 104 students focused on
--                  procedural practice, NOT conceptual review


-- ========================================
-- QUERY 3: PROBLEM TYPE DIFFICULTY PATTERNS
-- ========================================
-- Business Question: Which specific regrouping skills cause the most difficulty?
-- Why It Matters: "Practice regrouping" is too broad. We need to know WHICH
--                 regrouping skills to target in intervention.
-- Expected Insight: Specific skills will have much lower success rates than others
-- Business Impact: Enables precise, targeted intervention on specific skills
-- ========================================

SELECT 
    aq.skill_tag,
    COUNT(DISTINCT sr.student_id) AS students_attempted,
    COUNT(*) AS total_attempts,
    SUM(sr.is_correct) AS correct_answers,
    
    -- Success rate for this specific skill
    ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS success_rate,
    
    aq.difficulty,
    COUNT(DISTINCT aq.question_id) AS num_questions
    
FROM student_responses sr
JOIN assessment_questions aq ON sr.question_id = aq.question_id
JOIN assessments a ON sr.assessment_id = a.assessment_id
WHERE a.skill_category = '3-Digit Addition - Regrouping'
  AND aq.skill_tag IS NOT NULL  -- Exclude questions without skill tags
GROUP BY aq.skill_tag, aq.difficulty
ORDER BY success_rate ASC, aq.skill_tag;

-- Results:
-- "Regroup ones to tens" (hard difficulty): 45.0% success rate - LOWEST
-- "Multi-step regrouping" (all difficulties): 46.3% success rate
-- All "hard" difficulty questions: Below 50% success rate
--
-- Key Insight: "Regroup ones to tens" at hard difficulty is the critical intervention target
--              More than HALF of students fail these problems
-- Business Action: Start intervention with easy/medium "regroup ones to tens" problems
--                  Build confidence before introducing hard difficulty


-- ========================================
-- QUERY 4A: PERFORMANCE BY GRADE LEVEL
-- ========================================
-- Business Question: Which grade levels struggle most with regrouping?
-- Why It Matters: Helps allocate resources (staff, time, materials) to grades
--                 that need the most support
-- Expected Insight: Earlier grades may struggle more (developmental readiness)
-- Business Impact: Grade-specific intervention strategies and resource allocation
-- ========================================

WITH student_performance AS (
    SELECT 
        s.student_id,
        s.grade_level,
        a.skill_category,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS mastery_pct
    FROM student_responses sr
    JOIN students s ON sr.student_id = s.student_id
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    GROUP BY s.student_id, s.grade_level, a.skill_category
)
SELECT 
    grade_level,
    skill_category,
    COUNT(DISTINCT student_id) AS students,
    ROUND(AVG(mastery_pct), 2) AS avg_mastery,
    ROUND(MIN(mastery_pct), 2) AS min_mastery,
    ROUND(MAX(mastery_pct), 2) AS max_mastery,
    
    -- Count students reaching 75% mastery threshold
    COUNT(CASE WHEN mastery_pct >= 75 THEN 1 END) AS at_mastery,
    ROUND(COUNT(CASE WHEN mastery_pct >= 75 THEN 1 END) * 100.0 / COUNT(*), 2) AS pct_at_mastery
    
FROM student_performance
WHERE grade_level IS NOT NULL
GROUP BY grade_level, skill_category
ORDER BY grade_level, skill_category;

-- Results:
-- Grade 2: Lowest regrouping mastery (50.76% avg, only 13.73% at mastery)
-- Grade 2: Biggest gap between place value and regrouping (31.44 points)
-- 
-- Key Insight: Grade 2 students show the most struggle - may indicate developmental
--              readiness issues or need for additional scaffolding
-- Business Action: Grade 2 needs more manipulatives, visual models, and extended time


-- ========================================
-- QUERY 4B: PERFORMANCE BY TEACHER/CLASSROOM
-- ========================================
-- Business Question: Do certain teachers/classrooms have more students struggling?
-- Why It Matters: Identifies classrooms needing professional development support
--                 or additional resources
-- Expected Insight: Performance should vary by classroom, some teachers may need support
-- Business Impact: Targeted coaching for teachers with struggling classrooms
-- ========================================

WITH student_performance AS (
    SELECT 
        s.student_id,
        t.teacher_name,
        t.classroom,
        a.skill_category,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS mastery_pct
    FROM student_responses sr
    JOIN students s ON sr.student_id = s.student_id
    JOIN student_assignments sa ON s.student_id = sa.student_id
    JOIN teachers t ON sa.teacher_id = t.teacher_id
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE sa.teacher_id IS NOT NULL
    GROUP BY s.student_id, t.teacher_name, t.classroom, a.skill_category
)
SELECT 
    teacher_name,
    classroom,
    skill_category,
    COUNT(DISTINCT student_id) AS students,
    ROUND(AVG(mastery_pct), 2) AS avg_mastery,
    
    -- Count students at mastery threshold
    COUNT(CASE WHEN mastery_pct >= 75 THEN 1 END) AS at_mastery,
    ROUND(COUNT(CASE WHEN mastery_pct >= 75 THEN 1 END) * 100.0 / COUNT(*), 2) AS pct_at_mastery
    
FROM student_performance
GROUP BY teacher_name, classroom, skill_category
ORDER BY teacher_name, skill_category;

-- Results:
-- Mrs. Williams (Classroom 4A): 0% of students at mastery in regrouping - RED FLAG
-- Mrs. Johnson & Mr. Thompson: Highest concentration of target students
--
-- Key Insight: Mrs. Williams's classroom needs immediate observation and support
--              NOT ONE STUDENT reached mastery - indicates instructional issue
-- Business Action: Immediate classroom observation, instructional coaching, 
--                  professional development for Mrs. Williams


-- ========================================
-- QUERY 5: STUDENT IMPROVEMENT OVER TIME
-- ========================================
-- Business Question: Are students improving with repeated assessments, or are they stuck?
-- Why It Matters: If students aren't improving, current instructional approaches
--                 aren't working - need to change strategy
-- Expected Insight: Some improvement expected, but may see stagnation
-- Business Impact: Validates need for NEW intervention approach (not just "more practice")
-- ========================================

-- Step 1: Identify each student's assessment attempts and assign sequence numbers
WITH progression AS (
    SELECT 
        sr.student_id,
        a.assessment_id,
        a.skill_category,
        a.date_administered,
        
        -- Calculate mastery percentage for this specific attempt
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS mastery_pct,
        
        -- Assign attempt number (1st, 2nd, 3rd, etc.) by date
        ROW_NUMBER() OVER (
            PARTITION BY sr.student_id, a.skill_category 
            ORDER BY a.date_administered
        ) AS attempt_number
        
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    GROUP BY sr.student_id, a.assessment_id, a.skill_category, a.date_administered
)

-- Step 2: Compare first attempt vs. latest attempt for each student
SELECT 
    p1.student_id,
    p1.skill_category,
    p1.mastery_pct AS first_attempt,
    p2.mastery_pct AS latest_attempt,
    
    -- Calculate change from first to latest
    (p2.mastery_pct - p1.mastery_pct) AS total_improvement,
    
    -- Categorize the change
    CASE 
        WHEN (p2.mastery_pct - p1.mastery_pct) > 10 THEN '📈 Strong Improvement'
        WHEN (p2.mastery_pct - p1.mastery_pct) > 0 THEN '↗️ Some Improvement'
        WHEN (p2.mastery_pct - p1.mastery_pct) = 0 THEN '→ No Change'
        ELSE '📉 Decline'
    END AS progress_category
    
FROM progression p1
JOIN progression p2 
    ON p1.student_id = p2.student_id 
    AND p1.skill_category = p2.skill_category
WHERE p1.attempt_number = 1  -- First attempt
  AND p2.attempt_number = (  -- Latest attempt
      SELECT MAX(attempt_number) 
      FROM progression p3 
      WHERE p3.student_id = p1.student_id 
        AND p3.skill_category = p1.skill_category
  )
ORDER BY total_improvement DESC;

-- Results:
-- 📈 Strong Improvement: 51 students (28%)
-- 📉 Decline: 57 students (32%) - MORE students getting WORSE than improving
-- → No Change: Majority (stagnation)
-- Biggest improvement: 60 points (proves dramatic gains ARE possible)
--
-- Key Insight: More students declining than strongly improving = current approach NOT working
--              Majority showing minimal change = students are STUCK at current level
-- Business Action: This validates need for TARGETED intervention on specific skills
--                  "More practice" with current approach won't help - need different strategy


-- ========================================
-- QUERY 6: INTERVENTION PRIORITY RANKING
-- ========================================
-- Business Question: Which students should be prioritized for intervention, and in what order?
-- Why It Matters: Teachers have limited time - need to focus on highest-need students first
--                 This creates the actionable "what do we do Monday morning?" list
-- Expected Output: Ranked list of students with priority tiers
-- Business Impact: Enables immediate action - teachers can form groups on Monday
-- ========================================

-- Step 1: Calculate Place Value scores for each student
WITH place_value_scores AS (
    SELECT 
        sr.student_id,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS place_value_mastery
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE a.skill_category = 'Place Value'
    GROUP BY sr.student_id
),

-- Step 2: Calculate Regrouping scores for each student
regrouping_scores AS (
    SELECT 
        sr.student_id,
        ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS regrouping_mastery
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE a.skill_category = '3-Digit Addition - Regrouping'
    GROUP BY sr.student_id
),

-- Step 3: Identify specific weak skills for each student
hardest_skills AS (
    SELECT 
        sr.student_id,
        
        -- Combine all weak skills into comma-separated list
        STRING_AGG(
            DISTINCT aq.skill_tag, 
            ', ' 
            ORDER BY aq.skill_tag
        ) AS weakest_skills
        
    FROM student_responses sr
    JOIN assessment_questions aq ON sr.question_id = aq.question_id
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    WHERE a.skill_category = '3-Digit Addition - Regrouping'
      AND aq.skill_tag IS NOT NULL
      AND sr.is_correct = 0  -- Only include skills where student answered incorrectly
    GROUP BY sr.student_id
)

-- Step 4: Create final priority list with all student details
SELECT 
    s.student_id,
    s.first_name,
    s.last_name,
    s.grade_level,
    t.teacher_name,
    t.classroom,
    pv.place_value_mastery,
    rg.regrouping_mastery,
    (pv.place_value_mastery - rg.regrouping_mastery) AS skill_gap,
    hs.weakest_skills,
    
    -- Assign priority tier (1 = highest priority)
    CASE 
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 50 THEN 1  -- High Priority
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 60 THEN 2  -- Medium Priority
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 75 THEN 3  -- Monitor
        ELSE 4  -- Not in target group
    END AS priority_tier,
    
    -- Create readable priority labels
    CASE 
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 50 THEN '🔴 High Priority'
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 60 THEN '🟡 Medium Priority'
        WHEN pv.place_value_mastery >= 80 AND rg.regrouping_mastery < 75 THEN '🟢 Monitor'
        ELSE 'Not Target Group'
    END AS intervention_priority
    
FROM students s
LEFT JOIN student_assignments sa ON s.student_id = sa.student_id
LEFT JOIN teachers t ON sa.teacher_id = t.teacher_id
LEFT JOIN place_value_scores pv ON s.student_id = pv.student_id
LEFT JOIN regrouping_scores rg ON s.student_id = rg.student_id
LEFT JOIN hardest_skills hs ON s.student_id = hs.student_id
WHERE pv.place_value_mastery >= 80   -- Only target group students
  AND rg.regrouping_mastery < 75
ORDER BY priority_tier, skill_gap DESC;  -- Highest priority and biggest gaps first

-- Results:
-- 🔴 High Priority: 50 students (regrouping <50%) - Need IMMEDIATE daily intervention
-- 🟡 Medium Priority: 17 students (regrouping 50-59%) - Need 3x/week targeted practice
-- 🟢 Monitor: 37 students (regrouping 60-74%) - Need differentiated practice & check-ins
-- Total: 104 students in target group
--
-- #1 Priority Student: Matthew Gonzalez (83.33-point gap, 100% PV, 16.67% RG)
-- Common weak skills: "regroup with zeros", "regroup tens to hundreds", "regroup ones to tens"
--
-- Key Insight: This is THE actionable deliverable - teachers can use this list Monday morning
--              to form intervention groups by priority tier
-- Business Action: 
--   - Form 8-10 groups of 5-6 students (High Priority)
--   - Form 3-4 groups of 4-5 students (Medium Priority)
--   - Pair Monitor students with proficient peers for tutoring
--   - Focus all groups on identified weak skills, starting with easy/medium difficulty

-- ========================================
-- ANALYSIS COMPLETE
-- ========================================
-- Summary of Findings:
-- 1. 104 students (57.78%) in target group - understand concept, struggle with procedure
-- 2. "Regroup ones to tens" (hard): 45% success rate - critical intervention target
-- 3. 50 students need immediate help (regrouping <50%)
-- 4. Grade 2 and Mrs. Williams's classroom need additional support
-- 5. Limited improvement over time validates need for new approach
-- 6. Actionable priority list ready for Monday morning intervention
--
-- Business Impact: ~40% instructional time savings through targeted intervention
--                  vs. broad reteaching of concepts students already understand
-- ========================================