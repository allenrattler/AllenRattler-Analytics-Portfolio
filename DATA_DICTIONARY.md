# DATA DICTIONARY
## Education Analytics Database

**Project:** Student Performance Gap Analysis - Place Value vs. Regrouping  
**Database:** PostgreSQL 17  
**Schema:** education  
**Last Updated:** March 14, 2026

---

## **TABLE: students**
Student demographic and enrollment information

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| student_id | VARCHAR(10) | Unique identifier for each student | STU001, STU002 | PRIMARY KEY, NOT NULL |
| first_name | VARCHAR(50) | Student's first name | Emma, Liam | NOT NULL |
| last_name | VARCHAR(50) | Student's last name | Smith, Johnson | NOT NULL |
| grade_level | INTEGER | Current grade level (2, 3, or 4) | 2, 3, 4 | NULL values: 13 records (7.22%) before cleaning |
| date_of_birth | DATE | Student's date of birth | 2016-05-15 | |

**Row Count:** 180 students

**Grade Distribution (after cleaning):**
- Grade 2: 51 students (28.33%)
- Grade 3: 80 students (44.44%)
- Grade 4: 49 students (27.22%)

---

## **TABLE: teachers**
Teacher and classroom assignment information

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| teacher_id | VARCHAR(10) | Unique identifier for each teacher | TCH001, TCH002 | PRIMARY KEY, NOT NULL |
| teacher_name | VARCHAR(100) | Teacher's full name with title | Ms. Rodriguez, Mr. Chen | NOT NULL |
| grade_level | INTEGER | Grade level taught | 2, 3, 4 | NOT NULL |
| classroom | VARCHAR(10) | Classroom identifier | 2A, 3B, 4A | NOT NULL |

**Row Count:** 7 teachers

**Teacher Distribution:**
- Grade 2: Mrs. Smith (2A), Ms. Rodriguez (2B)
- Grade 3: Mrs. Johnson (3A), Mr. Thompson (3C), Ms. Patel (3B)
- Grade 4: Mr. Davis (4B), Mrs. Williams (4A)

---

## **TABLE: student_assignments**
Links students to their assigned teachers/classrooms

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| assignment_id | VARCHAR(10) | Unique assignment identifier | ASG001, ASG002 | PRIMARY KEY, NOT NULL |
| student_id | VARCHAR(10) | Student identifier | STU001 | FOREIGN KEY → students.student_id, NOT NULL |
| teacher_id | VARCHAR(10) | Assigned teacher identifier | TCH001 | FOREIGN KEY → teachers.teacher_id, NULL values: 19 records (10.56%) before cleaning |
| school_year | VARCHAR(10) | Academic year | 2024-2025 | NOT NULL |

**Row Count:** 180 assignments (one per student)

**Data Quality Note:** 19 students (10.56%) initially had NULL teacher_id. Fixed by matching students to teachers based on matching grade_level.

---

## **TABLE: assessments**
Assessment metadata and administration dates

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| assessment_id | VARCHAR(10) | Unique assessment identifier | ASS001, ASS002 | PRIMARY KEY, NOT NULL |
| assessment_name | VARCHAR(100) | Descriptive name of the assessment | Place Value Assessment 1 | NOT NULL |
| skill_category | VARCHAR(100) | Skill area being assessed | Place Value, 3-Digit Addition, 3-Digit Addition - Regrouping | NOT NULL |
| date_administered | DATE | Date assessment was given | 2024-09-01 | NOT NULL |
| total_questions | INTEGER | Number of questions on assessment | 15, 18, 22 | NOT NULL |

**Row Count:** 4 assessments

**Skill Categories:**
1. **Place Value** - Understanding digit positions and values in 3-digit numbers
2. **3-Digit Addition** - Basic addition without regrouping
3. **3-Digit Addition - Regrouping** - Multi-digit addition requiring carrying/regrouping

---

## **TABLE: assessment_questions**
Individual questions for each assessment with skill tags and difficulty levels

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| question_id | VARCHAR(10) | Unique question identifier | QUE001, QUE002 | PRIMARY KEY, NOT NULL |
| assessment_id | VARCHAR(10) | Assessment this question belongs to | ASS001, ASS003 | FOREIGN KEY → assessments.assessment_id, NOT NULL |
| question_number | INTEGER | Question sequence number within assessment | 1, 2, 3... | NOT NULL |
| skill_tag | VARCHAR(100) | Specific skill tested by this question | Regroup ones to tens, Identify hundreds place | NULL values: 4 records (~7%) before cleaning |
| difficulty | VARCHAR(20) | Difficulty level | easy, medium, hard | |
| points_possible | INTEGER | Maximum points for this question | 1, 2 | NOT NULL |

**Row Count:** 55 questions total across all assessments

**Skill Tags by Category:**

**Place Value Skills:**
- Identify hundreds place
- Identify tens place  
- Identify ones place
- Expanded form
- Standard form
- Compare 3-digit numbers

**3-Digit Addition Skills:**
- Add without regrouping
- Align digits
- Column addition

**Regrouping Skills (Critical for analysis):**
- Regroup ones to tens ← **Lowest success rate: 45.0% on hard difficulty**
- Regroup tens to hundreds
- Double regrouping
- Regroup with zeros
- Multi-step regrouping

**Difficulty Distribution:**
- Easy: ~30% of questions
- Medium: ~40% of questions
- Hard: ~30% of questions (all show <50% success rate for regrouping)

**Data Quality Note:** 4 questions initially had NULL skill_tag. Fixed by generating tags from assessment category + "General".

---

## **TABLE: student_responses**
Student answers to individual assessment questions (FACT TABLE)

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| response_id | VARCHAR(20) | Unique response identifier | RESP00001, RESP00002 | PRIMARY KEY, NOT NULL |
| student_id | VARCHAR(10) | Student who answered | STU001 | FOREIGN KEY → students.student_id, NOT NULL |
| assessment_id | VARCHAR(10) | Assessment containing this question | ASS001 | FOREIGN KEY → assessments.assessment_id, NOT NULL |
| question_id | VARCHAR(10) | Question that was answered | QUE001 | FOREIGN KEY → assessment_questions.question_id, NOT NULL |
| is_correct | INTEGER | Whether answer was correct (1) or incorrect (0) | 1, 0 | NOT NULL, CHECK (is_correct IN (0,1)) |
| response_timestamp | TIMESTAMP | Date and time response was recorded | 2024-09-01 08:30:00 | NOT NULL |

**Row Count:** 
- **Before cleaning:** 10,198 responses
- **After cleaning:** 9,900 responses (removed 298 duplicates)

**Data Quality Note:** 298 duplicate responses (2.92%) were identified and removed. Duplicates defined as same student_id + question_id + assessment_id combination. Kept earliest response_id for each duplicate set.

**Key Metrics (after cleaning):**
- Total students: 180
- Average responses per student: 55
- Total questions across all assessments: 55
- Expected total responses: 180 × 55 = 9,900 ✓

---

## **TABLE: skill_standards**
Mastery thresholds for each skill category

| Column Name | Data Type | Description | Example | Constraints |
|------------|-----------|-------------|---------|-------------|
| standard_id | VARCHAR(10) | Unique standard identifier | STD001, STD002 | PRIMARY KEY, NOT NULL |
| skill_category | VARCHAR(100) | Name of the skill category (matches assessments.skill_category) | Place Value, 3-Digit Addition - Regrouping | NOT NULL |
| mastery_threshold | NUMERIC(5,2) | Percentage needed for mastery (expressed as decimal: 75.00 = 75%) | 75.00, 80.00 | NOT NULL |

**Row Count:** 3 standards

**Mastery Thresholds:**
- **Place Value:** 80.00% - Higher threshold due to foundational importance
- **3-Digit Addition:** 75.00% - Standard mastery level
- **3-Digit Addition - Regrouping:** 75.00% - Standard mastery level

**Business Rule:** Students are categorized as "Target Group" if they achieve ≥80% mastery in Place Value BUT <75% mastery in Regrouping.

---

## **ENTITY RELATIONSHIP DIAGRAM**
```
┌─────────────┐        ┌──────────────────┐        ┌─────────────┐
│  students   │◄───1:1─│student_assignments│─1:1───►│  teachers   │
│             │        │                  │        │             │
│ student_id  │        │ student_id (FK)  │        │ teacher_id  │
│ first_name  │        │ teacher_id (FK)  │        │ teacher_name│
│ last_name   │        │ school_year      │        │ grade_level │
│ grade_level │        └──────────────────┘        │ classroom   │
│ date_of_birth│                                    └─────────────┘
└──────┬──────┘
       │
       │ 1:Many
       │
       ▼
┌─────────────────┐
│student_responses│ (FACT TABLE - 9,900 records)
│                 │
│ response_id     │
│ student_id (FK) │────────┐
│ assessment_id(FK)│        │
│ question_id (FK)│        │ Many:1
│ is_correct      │        │
│ response_timestamp│       ▼
└─────────────────┘  ┌──────────────────────┐        ┌─────────────┐
                     │ assessment_questions │◄──1:Many│ assessments │
                     │                      │        │             │
                     │ question_id          │        │ assessment_id│
                     │ assessment_id (FK)   │        │ skill_category│
                     │ skill_tag            │        │ date_admin  │
                     │ difficulty           │        └──────┬──────┘
                     │ points_possible      │               │
                     └──────────────────────┘               │
                                                            │
                                                            ▼
                                                   ┌────────────────┐
                                                   │skill_standards │
                                                   │                │
                                                   │ skill_category │
                                                   │ mastery_thresh │
                                                   └────────────────┘
```

---

## **KEY BUSINESS RULES & CALCULATIONS**

### **1. Student Mastery Calculation**
```sql
mastery_percentage = (SUM(is_correct) / COUNT(*)) × 100
WHERE skill_category = [specific skill]
GROUP BY student_id
```

### **2. Target Group Definition**
Students are classified as "Target Group" when:
- Place Value mastery ≥ 80.00%  
- AND Regrouping mastery < 75.00%

**Result:** 104 students (57.78% of total) meet this criteria

### **3. Intervention Priority Tiers**
- **🔴 High Priority:** Regrouping mastery < 50% (50 students)
- **🟡 Medium Priority:** Regrouping mastery 50-59% (17 students)  
- **🟢 Monitor:** Regrouping mastery 60-74% (37 students)

### **4. Assessment Progression**
Students take assessments in chronological order. Latest attempt used for final mastery calculation.

---

## **DATA QUALITY SUMMARY**

**Issues Identified and Resolved:**

| Issue | Count | Percentage | Resolution |
|-------|-------|------------|------------|
| Duplicate responses | 298 | 2.92% | Removed using ROW_NUMBER(), kept earliest response_id |
| Missing grade levels | 13 | 7.22% | Assigned default grade 3 (most common) |
| Missing teacher assignments | 19 | 10.56% | Matched by grade_level to appropriate teacher |
| Missing skill tags | 4 | ~7% | Generated from skill_category + "General" |

**Final Clean Dataset:**
- ✅ 9,900 unique student responses
- ✅ 180 students (all with grade levels)
- ✅ 180 student-teacher assignments (all complete)
- ✅ 55 questions (all with skill tags)
- ✅ Zero NULL values in critical analysis fields

---

## **COMMON QUERIES & JOINS**

### **Calculate Student Mastery by Skill:**
```sql
SELECT 
    s.student_id,
    a.skill_category,
    ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS mastery_pct
FROM student_responses sr
JOIN students s ON sr.student_id = s.student_id
JOIN assessments a ON sr.assessment_id = a.assessment_id
GROUP BY s.student_id, a.skill_category;
```

### **Identify Target Group Students:**
```sql
WHERE place_value_mastery >= 80 
  AND regrouping_mastery < 75
```

### **Find Lowest-Performing Skills:**
```sql
SELECT 
    aq.skill_tag,
    aq.difficulty,
    ROUND(SUM(sr.is_correct) * 100.0 / COUNT(*), 2) AS success_rate
FROM student_responses sr
JOIN assessment_questions aq ON sr.question_id = aq.question_id
WHERE aq.difficulty = 'hard'
GROUP BY aq.skill_tag, aq.difficulty
ORDER BY success_rate ASC;
```

---

## **PERFORMANCE NOTES**

**Indexes Created:**
- `idx_student_responses_student` on student_responses(student_id)
- `idx_student_responses_assessment` on student_responses(assessment_id)
- `idx_student_responses_question` on student_responses(question_id)
- `idx_assessment_questions_assessment` on assessment_questions(assessment_id)
- `idx_student_assignments_student` on student_assignments(student_id)
- `idx_student_assignments_teacher` on student_assignments(teacher_id)

**Query Performance:**
- Typical analysis queries: <100ms
- Full target group identification: <200ms
- Dashboard data refresh: <500ms

---

*For data cleaning methodology, see: `01_data_cleaning_postgresql.sql`*  
*For analysis queries, see: `02_analysis_queries_postgresql.sql`*  
*For project overview, see: `README.md`*
