# Student Performance Gap Analysis: Place Value vs. Regrouping

## Project Overview
An end-to-end data analytics project analyzing 10,198 student assessment responses to identify students who understand place value concepts but struggle with regrouping in 3-digit addition. This project demonstrates data cleaning, SQL analysis, and interactive dashboard development to provide actionable insights for targeted educational intervention.

**Project Duration:** February - March 2026  
**Role:** Data Analyst (Portfolio Project)  
**Industry:** Education / K-12 Analytics

## Business Problem
Elementary teachers observed students making errors in multi-digit addition despite understanding place value. The key question:

**"Which students have mastered place value concepts but struggle with the procedural skill of regrouping?"**

Traditional approaches reteach place value to all struggling students, wasting instructional time on concepts students already understand. This analysis identifies students who need targeted procedural practice rather than conceptual review, enabling more efficient intervention strategies.

## Data Sources
**Synthetic dataset** created to simulate realistic elementary math assessment data:

- **7 tables** with 10,198+ total records
- **180 students** across grades 2-4
- **7 teachers** across different classrooms
- **4 assessments** covering three skill categories
- **55 assessment questions** with varying difficulty levels
- **9,900 student responses** (after data cleaning)

### Database Schema:
- `students` - Student demographics (180 records)
- `teachers` - Teacher information (7 records)
- `student_assignments` - Student-teacher relationships (180 records)
- `assessments` - Assessment metadata (4 records)
- `assessment_questions` - Question details with skill tags (55 records)
- `student_responses` - Individual question responses (9,900 records after cleaning)
- `skill_standards` - Mastery thresholds (3 records)
  
## Methodology
### Phase 1: Data Cleaning (PostgreSQL)
**Issues identified and resolved:**
- **298 duplicate responses** (2.92%) - Removed using ROW_NUMBER() window function
- **13 missing grade levels** (7.22%) - Assigned default grade based on distribution
- **19 missing teacher assignments** (10.56%) - Matched by grade level
- **4 missing skill tags** (~7%) - Generated from assessment categories

**Result:** Clean dataset of 9,900 unique student responses

### Phase 2: SQL Analysis (PostgreSQL)
Developed 6 analytical queries using:
- Common Table Expressions (CTEs) for multi-step calculations
- Window functions (ROW_NUMBER, RANK) for deduplication and ranking
- Self-joins to track student improvement over time
- Complex aggregations to identify performance patterns

### Phase 3: Dashboard Development (Power BI)
- Connected Power BI to PostgreSQL database
- Created data model with 7 table relationships
- Built 6+ custom DAX measures for calculations
- Designed 4-page interactive dashboard
- Implemented conditional formatting to highlight priorities
  
## Key Findings
### 1. **57.78% of students (104 out of 180) are in the target group**
   - Place Value mastery ≥ 80%
   - Regrouping mastery < 75%
   - **Insight:** More than half the class understands the concept but can't execute the procedure

### 2. **"Regrouping ones to tens" is the critical skill gap**
   - Overall success rate: 57.8%
   - Hard difficulty questions: **45.0%** (more than half of students fail)
   - **Insight:** This specific procedural step needs focused intervention

### 3. **50 students need immediate intervention**
   - High Priority tier: Regrouping mastery < 50%
   - Largest individual gap: **83.33 percentage points** (100% place value, 16.67% regrouping)
   - **Insight:** These students are significantly behind and need daily support

### 4. **Grade 2 shows the most struggle**
   - Average regrouping mastery: 50.76%
   - Only 13.73% of grade 2 students reach mastery threshold
   - Performance gap from place value: 31.44 points
   - **Insight:** May indicate developmental readiness issues or need for additional scaffolding

### 5. **Mrs. Williams's classroom (4A) shows 0% mastery**
   - Critical finding requiring immediate classroom observation
   - Indicates potential instructional approach issue or challenging student population
   - **Insight:** Needs targeted professional development or support

### 6. **Limited improvement over time**
   - 51 students showed strong improvement (>10 points)
   - 57 students declined
   - Majority showed minimal change (stagnation)
   - **Insight:** Current instructional approach is not effective for most students
     
## Technical Implementation

## Dashboard Features

## Recommendations

## Files in This Repository

## Tools & Technologies

## How to Use This Project

## About the Author

## Screenshots
