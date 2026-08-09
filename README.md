# ContentPulse

**An end-to-end BI analytics pipeline for a GenAI content-creation app — from synthetic data generation to an interactive 4-page Metabase dashboard.**

ContentPulse simulates the growth, product, monetization, and retention analytics stack of a modern AI content-creation product. It was built to demonstrate a complete BI workflow: research-informed data modeling, relational database design, advanced SQL, and interactive dashboard engineering — the same skill set a growth/product analytics team at an AI product company relies on day to day.

---

## Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Part 1 — Data Generation](#part-1--data-generation)
- [Part 2 — PostgreSQL Setup](#part-2--postgresql-setup)
- [Part 3 — Metabase Setup](#part-3--metabase-setup)
- [Part 4 — The Dashboard: 4 Pages Explained](#part-4--the-dashboard-4-pages-explained)
- [SQL Concepts Used](#sql-concepts-used)
- [Repository Structure](#repository-structure)
- [Key Insight — How the Pages Connect](#key-insight--how-the-pages-connect)
- [Setup Instructions](#setup-instructions)

---

## Project Overview

Most portfolio BI projects start with a Kaggle CSV and end with a single chart. ContentPulse takes a different approach: it starts with **research into how a real GenAI content-creation app actually works** — its feature set, its AI model architecture, and its credit-based monetization system — and uses that research to generate a fully synthetic, relationally consistent dataset. That dataset is then loaded into PostgreSQL and visualized through a 4-page Metabase dashboard designed around one continuous business narrative:

**Acquisition → Product Engagement → Monetization → Retention & Sentiment**

Every page is interactive (filterable by date, channel, feature, plan tier, and more), and — critically — the pages are designed to connect to each other. A spike in failed generations on the Product page shows up again in refund rates on the Monetization page, and again in negative sentiment themes on the Retention page. That cross-page traceability is the actual point of BI: not just building charts, but building a system that lets you trace a business problem from symptom to root cause.

---

## Tech Stack

| Layer | Tool |
|---|---|
| Data generation | via Claude |
| Storage / warehouse | PostgreSQL 16 |
| Database GUI | pgAdmin 4 |
| BI / visualization | Metabase (self-hosted) |
| Query language | SQL (PostgreSQL dialect) |

---

## Architecture

The database uses a **fact constellation (galaxy schema)** — not a traditional single-fact star schema. This design was chosen deliberately: ImagineArt-style products have multiple distinct business processes (content generation, session/funnel behavior, subscriptions, credit transactions, community engagement, reviews) that all need independent measurement, but they share a common reference entity: the user.

```
                         ┌─────────────────────┐
                         │  imagineart_users    │  ← conformed dimension
                         │  (8,000 rows)         │
                         └──────────┬────────────┘
                                    │
        ┌───────────┬──────────────┼──────────────┬───────────────┬─────────────────┐
        │            │              │              │               │                 │
┌───────▼──────┐┌────▼─────────┐┌───▼──────────┐┌──▼────────────┐┌─▼───────────────┐┌─▼──────────────┐
│ generations   ││ sessions_    ││ subscriptions ││ credit_        ││ community_       ││ ratings_        │
│ (47,319 rows) ││ events       ││ (9,630 rows)  ││ transactions   ││ engagement       ││ reviews         │
│               ││ (148,923)    ││               ││ (2,771 rows)   ││ (2,137 rows)     ││ (1,440 rows)    │
└───────────────┘└──────────────┘└───────────────┘└────────────────┘└──────────────────┘└─────────────────┘

                         ┌─────────────────────┐
                         │  ad_campaigns         │  ← channel/week grain,
                         │  (72 rows)            │     no user_id join
                         └───────────────────────┘
```

One dimension table (`imagineart_users`), seven fact tables. Some fact tables carry denormalized columns (`plan_tier`, `country`, `platform`) directly for query simplicity; others (`subscriptions`, `credit_transactions`) rely on a `JOIN` back to `imagineart_users` for those same attributes — a deliberate mix that's realistic of real-world warehouses, which are rarely perfectly normalized end to end.

---

## Part 1 — Data Generation

Since no real ImagineArt/Vyro dataset is public, the dataset was built from the ground up using product research:

- **Real feature set modeled**: text-to-image, image-to-image, video generation, AI headshots, background/object remover, outpaint/expand, 4K/8K upscaler, style transfer, tattoo generator, logo/flyer/poster maker, avatar generator, interior design, product mockup
- **Real AI model architecture modeled**: ImagineArt 1.5 Pro, FLUX.2, Nano Banana 2, Ideogram v3, Recraft V4, Seedream 5.0 Lite
- **Real monetization mechanics modeled**: a credit-based consumption system layered under subscription tiers (free / pro_monthly / pro_annual / enterprise), rather than simple flat subscription gating
- **A real, documented pain point baked in**: failed generations still consume credits — a genuine reported user complaint — deliberately built into the failure-rate and refund logic so it's discoverable through analysis, not just decorative

The generation script (Python + pandas + numpy) builds each table with realistic distributions: engagement scaling by plan tier, paywall friction weighted toward free users, feature popularity weighted toward core tools, and credit costs scaled to compute intensity (video generation costs far more credits than a background removal).

---

## Part 2 — PostgreSQL Setup

**1. Database creation** (via pgAdmin or `psql`):
```sql
CREATE DATABASE imagineart;
```

**2. Schema creation** — all 8 tables created with explicit primary keys and foreign key constraints back to `imagineart_users`, enforcing referential integrity. Full DDL is in [`sql/01_create_tables.sql`](sql/01_create_tables.sql).

**3. Data loading** — each CSV loaded via pgAdmin's Import/Export tool (or `psql \copy` for a scripted/remote setup), loading `imagineart_users` first since every other table has a foreign key dependency on it.

**4. Verification**:
```sql
SELECT COUNT(*) FROM imagineart_generations;   -- 47,319
SELECT COUNT(*) FROM imagineart_sessions_events; -- 148,923
```

---

## Part 3 — Metabase Setup

1. Self-hosted Metabase (Docker: `docker run -d -p 3000:3000 --name metabase metabase/metabase`, or the standalone JAR for a no-Docker setup)
2. Connected to the local PostgreSQL instance: `Admin → Databases → Add a database → PostgreSQL`, using host `localhost`, port `5432`, database `imagineart`
3. Metabase auto-syncs all 8 tables under the `public` schema
4. Each metric was built as a **SQL-based Question** (not the GUI query builder), using Metabase's `{{variable}}` Field Filter syntax with optional-bracket conditionals (`[[AND {{variable}}]]`) — this means a filter left blank on the dashboard simply drops that condition from the query entirely, rather than forcing a default value or erroring out
5. **Important implementation detail**: Metabase Field Filters inject their WHERE condition using the table's *full name*, not a SQL alias — so every filtered query in this project is written alias-free (e.g., `imagineart_users.plan_tier`, not `u.plan_tier`) to avoid `invalid reference to FROM-clause entry` errors

All SQL used to build every card on every page is included in [`/sql`](sql/), organized one file per dashboard page, with each query's Field Filter mapping documented inline as comments.

---

## Part 4 — The Dashboard: 4 Pages Explained

### Page 1 — Acquisition & Growth
**Business question:** How efficiently are we acquiring users, not just how many are we acquiring?

| Element | Type | Insight |
|---|---|---|
| Total Users | KPI | Overall platform scale |
| Total Ad Spend | KPI | Total paid acquisition investment |
| Blended CPA | KPI | Cost efficiency of acquisition — the metric that matters more than raw volume |
| Average CTR | KPI | Top-of-funnel ad creative/targeting quality |
| Weekly New User Signups | Line chart | Growth trend over time |
| Users Signups by Acquisition Channel | Bar chart | Which channels drive volume |
| Cost Per Acquisition by Channel | Bar chart, ranked | Which channels are actually efficient — the real "where should we spend more/less" answer |
| Users by Country | Map | Geographic concentration, useful for localization and regional strategy |

**Filters:** Date, Acquisition Channel, Country

### Page 2 — Product & Feature Engagement
**Business question:** Once users are in the app, what do they actually do, and does the product work reliably?

| Element | Type | Insight |
|---|---|---|
| Total Generations | KPI | Core usage volume |
| Success Rate | KPI | Product reliability — directly tied to the credit-consumption-on-failure pain point |
| Average Generation Time | KPI | Performance/speed, especially for compute-heavy features |
| Export Rate | KPI | A more honest "did they actually want this" signal than raw generation count |
| Generations by Feature | Horizontal bar | Product-market fit at the feature level |
| AI Model Usage Share | Donut chart | User preference across the 6-model architecture |
| Generation Status by Features | Stacked bar | The sharpest diagnostic on this page — exactly which features fail most, and how (technical error vs. content policy) |
| Daily Active Users Overview | Line chart | Core engagement health pulse |
| Average Session Duration by Plan Tier | Bar chart | Do paying users actually engage more deeply? |

**Filters:** Date, Feature, AI Model, Plan Tier

### Page 3 — Monetization & Credit Economy
**Business question:** How well do we convert usage into revenue, and is the credit economy healthy?

| Element | Type | Insight |
|---|---|---|
| Total Revenue | KPI | Combined subscription + credit-purchase revenue |
| Paywall Conversion Rate | KPI | Direct measurement of monetization effectiveness |
| Avg Credits Consumed per Generation | KPI | Real cost of engagement inside the credit economy |
| Refund Rate | KPI | Support cost and trust signal — cross-references directly against Page 2's failure rate |
| Paywall Conversion Funnel | Bar (funnel-style) | Exactly where users drop off before converting: App Open → Paywall View → Converted |
| Revenue by Plan Tier | Bar chart | Which subscription tier actually drives the business |
| Upgrades vs Cancellations Over Time | Line chart | Net subscriber health trend, an early churn warning system |
| Avg Credits Consumed by Feature | Horizontal bar | Which features are most "expensive" — informs premium/add-on pricing strategy |

**Filters:** Date Range, Plan Tier (Monetization), Acquisition Channel (Monetization)

### Page 4 — Retention, Sentiment & Community
**Business question:** Are users satisfied, and is there an organic growth loop beyond paid acquisition?

| Element | Type | Insight |
|---|---|---|
| Average Rating | KPI | Overall satisfaction pulse |
| Negative Review Rate | KPI | Share of actively unhappy users — more actionable than the average alone |
| Total Community Posts | KPI | Volume of shared user-generated content |
| Total Follows Gained | KPI | Strength of the organic, non-paid growth loop |
| Rating Distribution | Bar chart | The full shape of sentiment, not just an average |
| Negative Sentiment Themes | Horizontal bar | **The payoff chart of the whole dashboard** — names exactly why users are unhappy (credit-gating friction, aggressive monetization, app crashes), tying directly back to Pages 2 and 3 |
| Rating by Plan Tier | Bar chart | Are paying users happier, or does monetization pressure make the experience feel worse? |
| Community Posts Over Time | Line chart | Trend of organic content creation |
| Top Features by Likes | Bar chart | Which features are most "show-off-worthy" — informs marketing and onboarding priorities |

**Filters:** Date (Retention), Plan Tier (Retention), Platform

---

## SQL Concepts Used

- **Aggregate functions**: `COUNT`, `SUM`, `AVG`, `ROUND`
- **Conditional aggregation**: `CASE WHEN ... THEN ... ELSE ... END` nested inside `SUM()` — used to compute rates (success rate, conversion rate, refund rate) without needing a separate `GROUP BY`
- **Joins**: `INNER JOIN` to bring dimension attributes (`plan_tier`, `acquisition_channel`) into fact tables that don't carry them natively
- **Subqueries**: nested `SELECT` statements, e.g. combining subscription revenue and credit-purchase revenue from two different tables into one KPI
- **`UNION ALL`**: stacking multiple aggregated result sets into one funnel-shaped output (App Open → Paywall View → Converted)
- **`NULLIF`**: defensive divide-by-zero protection on every rate calculation (`NULLIF(COUNT(*), 0)`)
- **Metabase Field Filter variables**: `{{variable}}` with optional-bracket syntax `[[AND {{variable}}]]`, so a blank dashboard filter cleanly drops its WHERE clause instead of erroring

---

## Repository Structure

```
contentpulse/
├── README.md
├── data/
│   ├── imagineart_users.csv
│   ├── imagineart_generations.csv
│   ├── imagineart_sessions_events.csv
│   ├── imagineart_subscriptions.csv
│   ├── imagineart_credit_transactions.csv
│   ├── imagineart_community_engagement.csv
│   ├── imagineart_ratings_reviews.csv
│   └── imagineart_ad_campaigns.csv
├── sql/
│   ├── 01_create_tables.sql
│   ├── page1_acquisition_and_growth.sql
│   ├── page2_product_and_feature_engagement.sql
│   ├── page3_monetization_and_credit_economy.sql
│   └── page4_retention_sentiment_and_community.sql
└── ContentPulse_Dashboard.pdf
```

---

## Key Insight — How the Pages Connect

The single most important design decision in this project wasn't any one chart — it was making sure the four pages tell **one continuous story** instead of four disconnected ones:

> Failed generations (Page 2) → consume credits anyway → drive refunds (Page 3) → drive negative reviews citing "credit-gating friction" and "aggressive monetization" (Page 4).

That chain is traceable end to end through the dashboard's filters, turning a vague complaint like "users are unhappy" into a specific, quantifiable, actionable finding: reliability issues are a measurable churn risk, not just a technical inconvenience.

---

## Setup Instructions

1. Clone this repository
2. Create a PostgreSQL database named `imagineart`
3. Run `sql/01_create_tables.sql` to create the schema
4. Import each CSV in `/data` into its matching table (load `imagineart_users` first)
5. Run Metabase (Docker or JAR) and connect it to your PostgreSQL instance
6. Recreate each dashboard question using the SQL in `/sql`, following the Field Filter mappings documented in each file's comments
7. Assemble the 4 tabs into one dashboard named **ContentPulse**

---

*Built as an independent portfolio project to demonstrate end-to-end BI capability: data modeling, PostgreSQL, advanced SQL, and interactive dashboard design in Metabase.*
