# AllenRattler Analytics Portfolio

**Elementary educator transitioning into data analytics, with experience using student performance data to guide instructional decisions and six years of healthcare billing, collections, and claims-resolution experience. Building analytics solutions across education, healthcare, and finance.**

This portfolio documents my transition into data analytics through progressively more advanced portfolio projects across multiple industries. Each project follows a structured workflow:

**Claude-assisted synthetic data generation using Python → Excel/Power Query cleaning → PostgreSQL analysis → Power BI visualization**

Claude was used to generate the Python code responsible for creating the synthetic datasets and to support technical problem solving throughout project development. Python is not presented as an independently developed programming skill.

---

## Portfolio Methodology

The projects in this portfolio were developed as hands-on analytics exercises using synthetic datasets.

My work focuses on:

- Defining business and analytical questions
- Reviewing and validating synthetic datasets
- Cleaning and transforming data with Excel and Power Query
- Analyzing data with PostgreSQL
- Developing dashboards and visualizations in Power BI
- Identifying trends, patterns, risks, and performance gaps
- Interpreting analytical results
- Translating findings into business or operational recommendations
- Documenting methodology and findings through GitHub

*Claude was used to generate Python-based synthetic datasets and provide technical assistance during development. The degree of AI assistance for SQL, DAX, Power Query, and other technical implementation is documented where appropriate.*

---

## Portfolio at a Glance

| # | Project | Industry | Business Problem | Status |
|---|---|---|---|---|
| 1 | [Student Performance Gap Analysis](#project-1--student-performance-gap-analysis) | Education | Which students are falling behind — and where does the gap start? | ✅ Complete |
| 2 | [Hospital Claim Denial & Revenue Recovery](#project-2--hospital-claim-denial--revenue-recovery) | Healthcare | Which payers and departments are generating the most denials — and how much revenue is lost? | ✅ Complete |
| 3 | [Finance Credit Risk Analysis](#project-3--finance-credit-risk-analysis) | Finance | Which borrowers are most likely to default — and are high-risk loans priced to justify the exposure? | ✅ Complete |

---

## How to Navigate This Repository

Each project lives on its own branch. Use the branch switcher at the top of the repository to navigate:

| Branch | Project |
|---|---|
| `Education-Analytics-Dashboard` | Project 1 — Student Performance Gap Analysis |
| `Hospital-Claim-Denial-Revenue-Recovery` | Project 2 — Hospital Claim Denial & Revenue Recovery |
| `Finance-Credit-Risk-Analysis` | Project 3 — Finance Credit Risk Analysis |

Each branch contains a full README, all raw and processed data files, SQL query files, Python data generation notebook, and Power BI dashboard screenshots.

---

## Portfolio Progression

A deliberate technical evolution was built into each project to demonstrate growth across the series:

| Project | Key Technical Addition |
|---|---|
| Project 1 | Foundational SQL (CTEs, aggregations), Power BI (4 pages, basic DAX) |
| Project 2 | Window functions (`RANK`, `LAG`, `PERCENT_RANK`), drill-through page, DAX time intelligence |
| Project 3 | Star schema data model, `NTILE` risk scoring, DAX What-If parameter, Decomposition Tree |

---

## Project 1 — Student Performance Gap Analysis

**Branch:** `Education-Analytics-Dashboard`

### Business Problem
Which students are falling behind in place value and regrouping — and does the gap differ by learning style, intervention group, or time of year?

### Industry
Education — 2nd Grade Elementary School

### Tools Used
Claude-assisted synthetic data generation using Python → Excel/Power Query cleaning → PostgreSQL analysis → Power BI visualization

### Dashboard
4-page interactive Power BI dashboard covering:
- Executive Summary with class-level KPI cards
- Performance gap analysis by concept (place value vs. regrouping)
- Student-level drill-down
- Intervention tracking over time

### Key Finding
Students receiving Tier 2 intervention showed the widest performance gap on regrouping concepts, suggesting the intervention curriculum may need realignment with the specific sub-skill rather than the broader concept.

### Navigate to Project 1
Switch to the `Education-Analytics-Dashboard` branch or click here:
[`Education-Analytics-Dashboard` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Education-Analytics-Dashboard)

---

## Project 2 — Hospital Claim Denial & Revenue Recovery

**Branch:** `Hospital-Claim-Denial-Revenue-Recovery`

### Business Problem
Which insurance payers, hospital departments, and procedure codes are generating the most claim denials — and how much net revenue is being lost before anyone notices?

### Industry
Healthcare — Hospital Revenue Cycle Management

### Tools Used
Claude-assisted synthetic data generation using Python → Excel/Power Query cleaning → PostgreSQL analysis → Power BI visualization

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

### Key Findings
- UnitedHealth: highest denial rate (23.85%) and highest denied revenue ($1.51M)
- Medicaid: highest revenue denied percentage at 26.55%
- Total denied revenue across all payers: $5,304,753
- Total recovered: $988,201 — net leakage YTD: $2.2M
- 49.54% of UnitedHealth denials were never appealed

### SQL Techniques
Dual `RANK()` window functions, `LAG()` for month-over-month trends, `LEFT JOIN` for unappealed denial detection, `PERCENT_RANK()` for CPT code risk scoring, YTD running totals

### Navigate to Project 2
Switch to the `Hospital-Claim-Denial-Revenue-Recovery` branch or click here:
[`Hospital-Claim-Denial-Revenue-Recovery` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Hospital-Claim-Denial-Revenue-Recovery)

---

## Project 3 — Finance Credit Risk Analysis

**Branch:** `Finance-Credit-Risk-Analysis`

### Business Problem
Which borrowers are most likely to default — and are the loans being issued to high-risk segments priced and structured in a way that justifies the risk exposure?

### Industry
Finance — Personal Lending & Credit Risk

### Tools Used
Claude-assisted synthetic data generation using Python → Excel/Power Query cleaning → PostgreSQL analysis → Power BI visualization

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

### Key Findings
- **Grade A is underwater:** net yield of -1.58% — interest collected ($1.71M) was less than charge-off losses ($1.81M)
- **Grade G is the most profitable:** net yield of +33.97% — high rates more than offset losses
- **Medical loans:** highest charge-off rate at 27.55%
- **Educational loans at Very High DTI:** 57.14% default rate — highest in the portfolio
- **Month 6** is the peak first-miss window for 36-month loans — optimal servicer intervention point

### SQL Techniques
`NTILE(5)` for credit quintile scoring, dual `RANK()`, `CASE` DTI banding, `AVG() OVER (PARTITION BY)`, `PERCENT_RANK()` with `CAST(... AS NUMERIC)`, `LAG()` for first missed payment detection, 4-CTE composite net yield pipeline

### Navigate to Project 3
Switch to the `Finance-Credit-Risk-Analysis` branch or click here:
[`Finance-Credit-Risk-Analysis` branch →](https://github.com/allenrattler/AllenRattler-Analytics-Portfolio/tree/Finance-Credit-Risk-Analysis)

---

## Skills Matrix

### Tools

| Tool | Application |
|---|---|
| AI-Assisted Data Generation | Claude-generated Python in Google Colab/Faker for synthetic dataset creation |
| Excel / Power Query | Multi-step cleaning pipelines; flag-don't-delete methodology; named Applied Steps |
| PostgreSQL (pgAdmin) | Complex analytical queries; CTE architecture; window functions |
| Power BI Desktop | Multi-page dashboards; DAX measures; star schema data modeling |
| GitHub | Branch-based project organization; recruiter-ready documentation |

### Technical Skills

| Skill | Projects |
|---|---|
| Window Functions (`RANK`, `NTILE`, `LAG`, `PERCENT_RANK`) | Projects 2, 3 |
| CTE-Based Query Architecture | Projects 1, 2, 3 |
| Star Schema Data Modeling | Project 3 |
| DAX Time Intelligence | Projects 2, 3 |
| DAX What-If Parameter | Project 3 |
| Power BI Drill-Through | Projects 2, 3 |
| Decomposition Tree Visual | Project 3 |
| Composite Metric Design | Projects 2, 3 |
| Data Quality Documentation | Projects 1, 2, 3 |
| Synthetic Data Transparency | Projects 1, 2, 3 |

---

## About This Portfolio

Three industries. Three business problems. One consistent workflow.

Each project was developed as an end-to-end portfolio case study, from business problem definition and AI-assisted synthetic dataset creation through data cleaning, analysis, visualization, interpretation, and documentation. The industries were chosen deliberately: Education (personal experience), Healthcare (approximately six years of professional billing, collections, and claims-resolution experience), and Finance (least familiar domain — chosen to prove adaptability).

The job search is active. If you're a hiring manager or recruiter looking for a data analyst who documents everything, builds in public, and isn't afraid to tackle unfamiliar problems — let's connect.

**LinkedIn:** [linkedin.com/in/allenrattler](https://www.linkedin.com/in/allenrattler/)

---
## AI Transparency / Project Methodology

### AI-Assisted Development
Claude was used to support synthetic dataset generation through Python and to assist with technical problem solving during project development. Python is not presented as an independently developed programming skill. The portfolio focuses on my application of Excel/Power Query, SQL/PostgreSQL, Power BI, analytical reasoning, business problem definition, data interpretation, validation, documentation, and communication of findings.

---
*Built with Excel · PostgreSQL · Power BI · Claude-assisted Python data generation*
