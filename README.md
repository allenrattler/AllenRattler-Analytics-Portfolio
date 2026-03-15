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
### SQL Query Highlights

**Query 1: Overall Mastery Rates**
```sql
-- Calculate mastery rates for each skill category
WITH skill_mastery AS (
    SELECT 
        a.skill_category,
        COUNT(DISTINCT sr.student_id) AS total_students,
        ROUND(AVG(CASE WHEN sr.is_correct = 1 THEN 100.0 ELSE 0 END), 2) AS avg_mastery,
        COUNT(DISTINCT CASE 
            WHEN student_mastery >= 75 THEN sr.student_id 
        END) AS students_at_mastery
    FROM student_responses sr
    JOIN assessments a ON sr.assessment_id = a.assessment_id
    GROUP BY a.skill_category
)
SELECT * FROM skill_mastery ORDER BY avg_mastery DESC;
```

**Query 2: Target Group Identification**
- Used CTEs to calculate individual student mastery for each skill
- Self-joins to compare Place Value vs. Regrouping performance
- CASE statements to categorize students into performance tiers

**Query 3: Student Progression Analysis**
- Self-join comparing first attempt vs. latest attempt
- ROW_NUMBER() to identify attempt sequence
- Revealed stagnation: majority of students showing minimal improvement

### Power BI DAX Measures

**Key Measures Created:**
```DAX
-- Target Group Percentage
Target Group % = 
DIVIDE([Target Group Count Simple], [Total Students], 0)

-- Success Rate (Overall)
Success Rate = 
VAR TotalAttempts = COUNTROWS(student_responses)
VAR CorrectAttempts = CALCULATE(
    COUNTROWS(student_responses), 
    student_responses[is_correct] = 1
)
RETURN DIVIDE(CorrectAttempts, TotalAttempts, 0)

-- Place Value Mastery
Place Value Mastery = 
VAR PlaceValueResponses = 
    CALCULATE(
        COUNTROWS(student_responses),
        RELATED(assessments[skill_category]) = "Place Value"
    )
VAR CorrectResponses = 
    CALCULATE(
        COUNTROWS(student_responses),
        RELATED(assessments[skill_category]) = "Place Value",
        student_responses[is_correct] = 1
    )
RETURN DIVIDE(CorrectResponses, PlaceValueResponses, 0)
```

### Data Model
- **Star schema** design with student_responses as fact table
- **7 table relationships** using one-to-many and one-to-one cardinality
- **Bidirectional cross-filtering** for interactive drill-down
- **CSV import** for student-level summary data (workaround for view visibility issue)
  
## Dashboard Features
### Page 1: Executive Overview
**Purpose:** High-level snapshot for leadership

**Visuals:**
- **3 KPI Cards:**
  - Total Students: 180
  - Students in Target Group: 57.8%
  - Overall Success Rate: 70.8%
- **Bar Chart:** Mastery by skill category (reveals 28-point gap between Place Value and Regrouping)
- **Donut Chart:** Student distribution by performance category

**Key Insight:** Quick view shows majority of students in target group needing intervention

---

### Page 2: Student Analysis
**Purpose:** Identify WHO needs help

**Visuals:**
- **Scatter Plot:** Place Value vs. Regrouping mastery with reference lines at 80% (PV threshold) and 75% (RG threshold)
  - Purple cluster (lower-left) = 104 target students
  - Visual quadrants clearly show performance patterns
- **Student Detail Table:** Full roster with conditional formatting
  - Green = high mastery, Red = low mastery
  - Sorted by skill gap (largest gaps at top)
  - Shows Matthew Gonzalez with 83.33-point gap
- **Stacked Bar Chart:** Student distribution by teacher and category
  - Reveals Mrs. Williams has 0% mastery rate

**Key Insight:** Visual proof of the performance gap; individual students identified for intervention

---

### Page 3: Skill Deep Dive
**Purpose:** Understand WHAT skills are most difficult

**Visuals:**
- **Bar Chart:** Success rate by specific regrouping skill tag
  - "Multi-step regrouping" lowest at 46.3%
  - "Regroup ones to tens" at 57.8% overall
- **Matrix:** Performance breakdown by skill tag AND difficulty level
  - Red conditional formatting shows all "hard" questions below 50%
  - "Regroup ones to tens" (hard): 45.0% - validates SQL finding
- **Card:** 45% - Lowest skill success rate (highlighted in red)

**Key Insight:** Specific skills and difficulty levels identified for targeted practice

---

### Page 4: Intervention Planning
**Purpose:** Actionable plan for Monday morning

**Visuals:**
- **3 Priority Cards:**
  - 🔴 High Priority: 50 students (Regrouping <50%)
  - 🟡 Medium Priority: 17 students (Regrouping 50-59%)
  - 🟢 Monitor: 37 students (Regrouping 60-74%)
- **Intervention Priority Table:**
  - All 104 target students sorted by skill gap
  - Conditional formatting highlights urgent cases
  - Filterable by teacher using slicer
- **Recommendation Text Box:**
  - Specific grouping strategies (8-10 groups of 5-6 students)
  - Frequency guidelines (daily vs. 3x/week vs. independent)
  - Focus areas by priority tier

**Key Insight:** Teachers can immediately identify their students and begin forming intervention groups

## Recommendations
### Immediate Actions (Week 1)

1. **Form High-Priority Intervention Groups**
   - Create 8-10 small groups of 5-6 students
   - Focus on foundational regrouping with manipulatives
   - Schedule daily 15-minute sessions
   - Target: "Regroup ones to tens" mastery

2. **Classroom Observation for Mrs. Williams (4A)**
   - Immediate instructional coaching support
   - Observe current teaching methods
   - Provide targeted professional development
   - Monitor weekly progress

3. **Grade 2 Scaffolding Strategy**
   - Increase use of visual models and manipulatives
   - Consider developmental readiness assessment
   - Extended time for regrouping concept development

### Medium-Term Actions (Weeks 2-4)

4. **Differentiated Practice by Skill Level**
   - Easy/Medium difficulty focus for high-priority students
   - Build confidence before introducing hard problems
   - Progress monitoring weekly

5. **Peer Tutoring for Monitor Tier**
   - Pair students just below mastery (60-74%) with proficient peers
   - Reduces teacher workload while supporting students

### Long-Term Strategy

6. **Systematic Skill Progression Tracking**
   - Weekly assessments to monitor improvement
   - Adjust groupings based on progress
   - Expect 8-12 weeks to see significant gains

7. **Instructional Approach Review**
   - Current methods showing limited improvement over time
   - Consider alternative teaching strategies for regrouping
   - Professional development on procedural vs. conceptual teaching

### Expected Impact

- **~40% reduction in instructional time waste** (stop reteaching place value to students who already know it)
- **Targeted intervention** increases likelihood of student improvement
- **Data-driven grouping** ensures appropriate challenge level for all students
  
## Files in This Repository

### SQL Files
- `schema_postgresql.sql` - Database schema and table creation statements
- `01_data_cleaning_postgresql.sql` - Data quality checks and cleaning queries
- `02_analysis_queries_postgresql.sql` - All 6 analytical queries with comments

### CSV Data Files
- `students.csv` - Student demographic data (180 records)
- `teachers.csv` - Teacher information (7 records)
- `student_assignments.csv` - Student-teacher relationships (180 records)
- `assessments.csv` - Assessment metadata (4 records)
- `assessment_questions.csv` - Question details with skill tags (55 records)
- `student_responses.csv` - Individual responses (9,900 records after cleaning)
- `skill_standards.csv` - Mastery threshold definitions (3 records)
- `student_summary.csv` - Student-level performance summary (180 records)

### Power BI
- `Education_Analytics_Dashboard.pbix` - Complete interactive dashboard (4 pages)

### Documentation
- `README.md` - This file
- `DATA_DICTIONARY.md` - Detailed field descriptions for all tables
- `DATA_QUALITY_ISSUES.md` - Documentation of cleaning process
- `POWER_BI_GUIDE.md` - Setup instructions for dashboard
- `POSTGRESQL_SETUP.md` - Database setup guide

### Screenshots
- `screenshots/page1_executive_overview.png` - Page 1 full view
- `screenshots/page2_student_analysis.png` - Page 2 full view
- `screenshots/page3_skill_deep_dive.png` - Page 3 full view
- `screenshots/page4_intervention_planning.png` - Page 4 full view
- `screenshots/scatter_plot_pv_vs_regrouping.png` - Key visual highlighting target group
  
## Tools & Technologies
### Database & Analysis
- **PostgreSQL 17** - Relational database management
- **pgAdmin 4** - Database administration and query development
- **SQL** - Data cleaning, transformation, and analysis
  - Common Table Expressions (CTEs)
  - Window Functions (ROW_NUMBER, RANK)
  - Self-joins for temporal analysis
  - Complex aggregations and filtering

### Visualization & Dashboard
- **Power BI Desktop** - Interactive dashboard development
- **DAX (Data Analysis Expressions)** - Custom measures and calculations
- **Power Query** - Data import and transformation

### Data Management
- **CSV** - Data storage and transfer format
- **Git/GitHub** - Version control and portfolio hosting

### Skills Demonstrated
- Data cleaning and quality assurance
- Database schema design
- SQL query optimization
- Data modeling (star schema)
- Statistical analysis
- Data visualization best practices
- Business intelligence dashboard design
- Stakeholder communication
  
## How to Use This Project
### Option 1: View Dashboard Screenshots
1. Navigate to the `screenshots/` folder
2. View the 4 dashboard pages and key visuals
3. Review findings in this README

### Option 2: Explore the Database (Requires PostgreSQL)
1. Install PostgreSQL 17 and pgAdmin 4
2. Create database: `CREATE DATABASE education_analytics;`
3. Create schema: `CREATE SCHEMA education;`
4. Run `schema_postgresql.sql` to create tables
5. Import CSV files using `\COPY` commands in schema file
6. Run queries in `01_data_cleaning_postgresql.sql`
7. Run analysis queries in `02_analysis_queries_postgresql.sql`

### Option 3: Open Power BI Dashboard (Requires Power BI Desktop)
1. Download and install Power BI Desktop (free)
2. Open `Education_Analytics_Dashboard.pbix`
3. **Note:** Data connections may need to be refreshed:
   - If prompted, select "Edit" to update data source paths
   - Point to the CSV files in this repository
4. Navigate through all 4 pages
5. Use slicers/filters to explore data interactively

### Option 4: Replicate the Analysis
1. Follow setup instructions in `POSTGRESQL_SETUP.md`
2. Complete data cleaning following `DATA_QUALITY_ISSUES.md`
3. Execute all analysis queries
4. Follow `POWER_BI_GUIDE.md` to rebuild dashboard

## About the Author
**Allen** - Elementary Teacher transitioning to Data Analytics

**Background:**
- Current elementary school teacher with firsthand experience of the educational challenges addressed in this project
- Building a portfolio of SQL and Power BI projects to demonstrate analytical capabilities
- Open to data analyst roles across industries including healthcare, finance, retail, and education technology

**Skills:**
- SQL (PostgreSQL) - Data cleaning, complex queries, window functions
- Power BI - Dashboard development, DAX, data modeling
- Data Analysis - Statistical analysis, pattern recognition, business insights
- Domain Expertise - K-12 education, student assessment, instructional strategies

**Connect:**
- LinkedIn: [Your LinkedIn URL]
- GitHub: [Your GitHub URL]
- Portfolio: [Your Portfolio URL]

**Why This Project?**
This project emerged from a real classroom challenge I've witnessed firsthand: students who understand mathematical concepts but struggle with procedural execution. By combining my teaching expertise with data analytics skills, I'm able to identify specific intervention strategies that save instructional time and target student needs more effectively. This represents the type of data-driven problem-solving I want to bring to my future role as a data analyst.

## Screenshots
