# IMDb Enterprise Media Metadata System 🎬
**Developed by "The Architects" 

[![Database](https://img.shields.io/badge/Database-Oracle%20SQL-orange.svg)](https://www.oracle.com/database/)
[![Status](https://img.shields.io/badge/Status-Production--Ready-green.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()

## 📌 Project Vision
This project is an enterprise-grade relational database engine designed to be the **"Single Source of Truth" (SSOT)** for the global entertainment industry. Beyond simple storage, this system focuses on **Data Governance**, **Historical Compliance**, and **Financial Intelligence**, modeling the complex ecosystem of IMDb.



## 🚀 Architectural Pillars
* **Scale-First Design**: A normalized schema featuring **28+ tables** managing Titles, Talent (People), Awards, Streaming, and User Interactions.
* **Time-Travel Architecture**: Implementation of **Soft-Delete** and **Versioning** logic across all core tables to maintain a historical audit trail.
* **Automated Integrity**: Advanced PL/SQL triggers and procedures enforce strict business rules (e.g., preventing overlapping streaming availability or invalid award nominations).
* **Business Intelligence**: A custom analytics suite providing deep insights into ROI by Genre, "Blockbuster" efficiency, and Talent metrics.

---

## 📂 Repository Structure
```text
├── 📂 sql_scripts         
│   ├── 01_DDL_Schema.sql          # Table structures, Constraints, and Sequences
│   ├── 02_DML_Seed_Data.sql       # Global metadata for Countries, Languages, and Media
│   ├── 03_Stored_Logic.sql        # Procedures, Triggers, and Views
│   └── 04_Test_Harness.sql        # "Chaos Monkey" testing script for validation
├── 📂 documentation
│   ├── ERD_Diagram.pdf            # Visual database blueprint
│   ├── Technical_Report.pdf       # Full architectural deep-dive
│   ├── Business_Rules.pdf         # Logic & Constraint definitions
│   └── Requirements_Specs.docx    # Functional & Non-Functional requirements
├── 📂 Analytics
|   └── Complex Queries
├── 📂 presentation
│   └── Project_Presentation.pptx  # Stakeholder slide deck
└── README.md
