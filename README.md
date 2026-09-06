# AllenRattler Analytics Portfolio

**Elementary educator transitioning into data analytics, with experience using student performance data to guide instructional decisions and six years of healthcare billing, collections, and claims-resolution experience. Building analytics solutions across education, healthcare, and finance.**

This portfolio documents my transition into data analytics through progressively more advanced portfolio projects across multiple industries. Each project follows a structured workflow:

**Claude-assisted synthetic data generation using Python → project-specific data cleaning using PostgreSQL or Excel/Power Query → AI-assisted PostgreSQL analysis → AI-guided Power BI development**

Claude was used to generate the Python code responsible for creating the synthetic datasets and to support technical problem solving throughout project development. Python is not presented as an independently developed programming skill.

---

## Portfolio Methodology

This portfolio documents my transition into data analytics through hands-on projects across education, healthcare, and finance.

Each project follows a structured workflow:

Claude-assisted synthetic data generation using Python → project-specific data cleaning using PostgreSQL or Excel/Power Query → AI-assisted PostgreSQL analysis → AI-guided Power BI development

### My Role

I personally:

- Researched and selected the business problems explored in each project.
- Performed hands-on data cleaning and transformation using project-specific tools, including PostgreSQL and Excel/Power Query, with AI assistance disclosed where applicable.
- Executed PostgreSQL queries and reviewed their outputs.
- Developed working knowledge of SQL, including JOINs, GROUP BY, CTEs, CASE expressions, and window functions, and can independently write or modify queries using these techniques.
- Built Power BI dashboards by following AI-assisted implementation guidance.
- Created and managed relationships within Power BI data models.
- Applied appropriate visualization principles for categorical, time-series, and part-to-whole data.
- Formatted and organized dashboard visuals for readability and presentation.
- Evaluated project outputs, refined prompts and requirements, and maintained project documentation through GitHub.
- Used my professional experience in education and healthcare to research and contextualize relevant business problems.

### Claude's Role

Claude was used to:

- Generate Python code used to create the synthetic datasets.
- Generate most of the initial SQL queries used throughout the portfolio projects.
- Generate DAX measures used in the Power BI dashboards.
- Provide step-by-step guidance for dashboard development.
- Suggest analytical questions, KPIs, analytical approaches, and portions of the business-analysis structure.
- Assist with interpretation of analytical outputs and development of project findings.
- Support technical troubleshooting and project development.

Python and DAX are therefore not presented as independently developed technical skills.

SQL is presented as a developing hands-on skill because I can independently write, understand, and modify common SQL queries, although much of the original portfolio SQL implementation was generated with Claude assistance.

Power BI is presented as a hands-on skill because I built the dashboards, created relationships, formatted visualizations, and understand foundational visualization principles, while using Claude for implementation guidance.

---

## Portfolio at a Glance

| # | Project | Industry | Business Problem | Status |
|---|---|---|---|---|
| 1 | [Student Performance Gap Analysis: Place Value vs. Regrouping](#project-1--student-performance-gap-analysis-place-value-vs-regrouping) | Education | Which students have mastered place value concepts but struggle with regrouping, and which specific regrouping skills should be prioritized for intervention? | ✅ Complete |
| 2 | [Hospital Claim Denial & Revenue Recovery Analysis](#project-2--hospital-claim-denial--revenue-recovery-analysis) | Healthcare | Which payers and departments are generating the most denials — and how much revenue is lost? | ✅ Complete |
| 3 | [Consumer Credit Risk & Loan Profitability Analysis](#project-3--consumer-credit-risk--loan-profitability-analysis) | Finance | Which borrowers are most likely to default — and are high-risk loans priced to justify the exposure? | ✅ Complete |

---

## How to Navigate This Repository

Each project lives on its own branch. Use the branch switcher at the top of the repository to navigate:

| Branch | Project |
|---|---|
| `Student-Performance-Gap-Analysis-Place-Value-vs-Regrouping` | Project 1 — Student Performance Gap Analysis: Place Value vs. Regrouping |
| `Hospital-Claim-Denial-Revenue-Recovery-Analysis` | Project 2 — Hospital Claim Denial & Revenue Recovery Analysis |
| `Consumer-Credit-Risk-&-Loan-Profitability-Analysis` | Project 3 — Consumer Credit Risk & Loan Profitability Analysis |

Each branch contains a detailed README, relevant raw and processed data files, SQL query files, Power BI dashboard files and screenshots, and supporting project documentation. Project contents vary based on the tools and workflow used for each analysis.

---

## Portfolio Progression

A deliberate progression in project complexity and technical exposure was built into the portfolio, with each project introducing additional analytical techniques and Power BI features.

| Project | Key Technical Addition |
|---|---|
| Project 1 | Foundational SQL (CTEs, aggregations), Power BI (4 pages, basic DAX) |
| Project 2 | Window functions (`RANK`, `LAG`, `PERCENT_RANK`), drill-through page, DAX time intelligence |
| Project 3 | Star schema data model, `NTILE` risk scoring, DAX What-If parameter, Decomposition Tree |

---

**Synthetic Data Notice:** All datasets, records, entities, financial figures, student records, borrower records, and analytical findings in this portfolio are based on synthetic data created for educational and portfolio purposes unless explicitly stated otherwise.

## Project 1 — Student Performance Gap Analysis: Place Value vs. Regrouping

**Branch:** `Student-Performance-Gap-Analysis-Place-Value-vs-Regrouping`

### Business Problem
Which students have mastered place value concepts but struggle with regrouping, and which specific regrouping skills should be prioritized for intervention?

### Industry
Education — Elementary School, Grades 2–4

### Tools Used
Claude-assisted synthetic data generation using Python → AI-assisted PostgreSQL data cleaning and analysis → AI-guided Power BI development

### Dashboard
4-page interactive Power BI dashboard covering:
- Executive overview
- Student-level performance analysis
- Skill deep dive
- Intervention planning

### AI-Assisted Key Findings
104 of 180 students (57.8%) met the target-group criteria of strong place-value performance but below-threshold regrouping performance, demonstrating a substantial procedural skill gap within the synthetic dataset.

### Navigate to Project 1
Switch to the `Student-Performance-Gap-Analysis-Place-Value-vs-Regrouping` branch or click here:
[`Student-Performance-Gap-Analysis-Place-Value-vs-Regrouping` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Student-Performance-Gap-Analysis-Place-Value-vs-Regrouping)

---

## Project 2 — Hospital Claim Denial & Revenue Recovery Analysis

**Branch:** `Hospital-Claim-Denial-Revenue-Recovery-Analysis`

### Business Problem
Which insurance payers, hospital departments, and procedure codes are generating the most claim denials — and how much net revenue is being lost before anyone notices?

### Industry
Healthcare — Hospital Revenue Cycle Management

### Tools Used
Claude-assisted synthetic data generation using Python → project-specific data cleaning using PostgreSQL or Excel/Power Query → AI-assisted PostgreSQL analysis → AI-guided Power BI development

### Dataset
- `claims_raw`: 5,000 rows after deduplication
- `appeals_raw`: 562 rows
- `payers_lookup`: 8 rows
- `departments_lookup`: 7 rows

### Dashboard
5-page interactive Power BI dashboard covering:
- Executive Summary (6 KPI cards, payer summary table)
- Denial Analysis (denial rate by payer and department)
- Appeals & Recovery (win rate, avg days to resolve)
- Payer Detail — Drill-Through (right-click any payer to drill in)

**Synthetic Data Disclaimer:** *All payer names, claims, financial figures, denial rates, recovery rates, and findings in this portfolio project are based on synthetic data created solely for educational and portfolio purposes. They do not represent actual performance by any insurer, healthcare organization, borrower, or individual.*

### AI-Assisted Key Findings
- UnitedHealth: highest denial rate (23.85%) and highest denied revenue ($1.51M)
- Medicaid: highest revenue denied percentage at 26.55%
- Total denied revenue across all payers: $5,304,753
- Total recovered: $988,201 — net leakage YTD: $2.2M
- 49.54% of UnitedHealth denials were never appealed

### SQL Techniques
Dual `RANK()` window functions, `LAG()` for month-over-month trends, `LEFT JOIN` for unappealed denial detection, `PERCENT_RANK()` for CPT code risk scoring, YTD running totals

### Navigate to Project 2
Switch to the `Hospital-Claim-Denial-Revenue-Recovery` branch or click here:
[`Hospital-Claim-Denial-Revenue-Recovery` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Hospital-Claim-Denial-Revenue-Recovery-Analysis)

---

## Project 3 — Consumer Credit Risk & Loan Profitability Analysis

**Branch:** `Consumer-Credit-Risk-&-Loan-Profitability-Analysis`

### Business Problem
Which borrowers are most likely to default — and are the loans being issued to high-risk segments priced and structured in a way that justifies the risk exposure?

### Industry
Finance — Personal Lending & Credit Risk

### Tools Used
Claude-assisted synthetic data generation using Python → project-specific data cleaning using PostgreSQL or Excel/Power Query → AI-assisted PostgreSQL analysis → AI-guided Power BI development

### Dataset
- `loans_clean`: 3,500 rows after deduplication
- `payment_events_clean`: 23,628 rows
- `loan_grades_lookup`: 35 rows
- `geography_lookup`: 50 rows

### Dashboard
6-page interactive Power BI dashboard covering:
- Executive Summary (8 KPI cards including net yield)
- Credit Risk Analysis (matrix heat map, Decomposition Tree, DTI analysis)
- Loan Purpose & Charge-Off (charge-off rates and dollar losses by purpose)
- Risk-Adjusted Return (composite risk scoring + What-If parameter slider)
- Borrower Drill-Through (right-click any grade to see its full risk profile)

### AI-Assisted Key Findings
- **Grade A is underwater:** net yield of -1.58% — interest collected ($1.71M) was less than charge-off losses ($1.81M)
- **Grade G is the most profitable:** net yield of +33.97% — high rates more than offset losses
- **Medical loans:** highest charge-off rate at 27.55%
- **Educational loans at Very High DTI:** 57.14% default rate — highest in the portfolio
- **Month 6** is the peak first-miss window for 36-month loans — optimal servicer intervention point

### SQL Techniques
`NTILE(5)` for credit quintile scoring, dual `RANK()`, `CASE` DTI banding, `AVG() OVER (PARTITION BY)`, `PERCENT_RANK()` with `CAST(... AS NUMERIC)`, `LAG()` for first missed payment detection, 4-CTE composite net yield pipeline

### Navigate to Project 3
Switch to the `Consumer-Credit-Risk-&-Loan-Profitability-Analysis` branch or click here:
[`Consumer-Credit-Risk-&-Loan-Profitability-Analysis` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Consumer-Credit-Risk-&-Loan-Profitability-Analysis)

---

## Skills Matrix

### Tools

| Tool | Application |
|---|---|
| AI-Assisted Data Generation | Claude-generated Python in Google Colab/Faker for synthetic dataset creation |
| Excel / Power Query | Multi-step cleaning pipelines; flag-don't-delete methodology; named Applied Steps |
| PostgreSQL (pgAdmin) | SQL execution and modification; joins, aggregations, CTEs, CASE expressions, and window functions; AI-assisted original query development |
| Power BI Desktop | Multi-page dashboard construction, relationships, visualization, drill-through, and formatting; AI-guided implementation and Claude-generated DAX |
| GitHub | Branch-based project organization; recruiter-ready documentation |

### Project Techniques & Features

The following techniques and features are represented within the portfolio projects. Their inclusion describes the technical scope of the projects and should not be interpreted to mean that every implementation was independently developed without AI assistance.

| Technique/Feature | Projects |
|---|---|
| SQL JOINs, GROUP BY, CASE Expressions, and CTEs | Project 1, 2, 3 |
| Window Functions (`ROW_NUMBER`, `RANK`, `NTILE`, `LAG`, `PERCENT_RANK`) | Projects 1, 2, 3 |
| Power Query Data Cleaning & Transformation | Projects 2, 3 |
| Star Schema Data Model | Project 3 |
| DAX Time Intelligence | Projects 2, 3 |
| DAX What-If Parameter | Project 3 |
| Power BI Drill-Through | Projects 2, 3 |
| Decomposition Tree | Project 3 |
| Composite Metric Design | Projects 2, 3 |
| Data Quality Documentation | Projects 1, 2, 3 |
| Synthetic Data Transparency | Projects 1, 2, 3 |


**Note:** DAX measures and much of the original advanced SQL implementation were generated with Claude assistance. I independently perform Power Query transformations and can write or modify common SQL queries, including joins, aggregations, CTEs, CASE expressions, and window functions.

---

## About This Portfolio

Three industries. Three business problems. One consistent analytical workflow.

The industries were selected deliberately:

- **Education:** Builds on my professional experience using assessment, progress-monitoring, attendance, behavioral, and performance data to support instructional decisions.
- **Healthcare:** Builds on approximately six years of professional experience in insurance billing, collections, claims investigation, and resolution.
- **Finance:** Represents an unfamiliar industry selected to demonstrate my ability to learn a new business domain and apply analytical methods to a different type of problem.

These projects demonstrate my developing capabilities in data cleaning, SQL execution and modification, Power BI dashboard development, data visualization, technical documentation, and AI-assisted analytical workflows.

---
*Built with Excel · PostgreSQL · Power BI · GitHub · Claude-assisted synthetic data generation*
