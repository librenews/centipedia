# Centipedia: Evidence-Weighted Knowledge Synthesis System

## System Specification Document (Technology-Agnostic)

------------------------------------------------------------------------

## 1. Executive Summary

Centipedia is a deterministic, evidence-weighted knowledge synthesis
system.

It is not an AI content generator.

It is a structured pipeline where:

Humans submit evidence → Evidence is scored using a public rubric → AI
compiles a structured article strictly from weighted evidence → The
output is versioned and reproducible.

The AI does not originate knowledge. It compiles weighted evidence
according to transparent rules.

------------------------------------------------------------------------

## 2. Core Principles

1.  Only AI writes articles.
2.  AI may use only submitted and validated citations.
3.  Humans influence inputs (citations, votes), not prose.
4.  Citation weighting follows a public rubric.
5.  Identity is signed and persistent (decentralized-ready).
6.  Outputs are deterministic given the same inputs and rubric version.
7.  All synthesis steps are auditable and versioned.

------------------------------------------------------------------------

## 3. System Overview

### 3.1 High-Level Flow

User Identity\
↓\
Submit Citation\
↓\
Citation Validation\
↓\
Rubric Scoring\
↓\
Weighted Evidence Graph\
↓\
AI Synthesis (Constrained)\
↓\
Versioned Article\
↓\
Periodic Re-evaluation

------------------------------------------------------------------------

## 4. Identity Layer

Requirements: - Persistent identity per user - Signed authentication -
Prevent trivial multi-account abuse - Extensible to decentralized
identity systems

The identity layer must support: - Unique user identifier - Reputation
tracking - Vote history - Citation submission history

------------------------------------------------------------------------

## 5. Citation System

Each citation must include:

-   URL
-   Extracted text content snapshot
-   Source metadata (title, author, publish date)
-   Submission timestamp
-   Submitter identity

### 5.1 Validation

Each citation must be: - Reachable (HTTP 200) - Content-extracted -
Stored as a snapshot hash - Re-checked periodically

Dead or altered sources reduce weight automatically.

------------------------------------------------------------------------

## 6. Public Rubric System

Each citation is scored across dimensions.

Example rubric dimensions:

1.  Relevance to topic (semantic similarity score)
2.  Depth of coverage (extent of topic focus)
3.  Source reliability (domain credibility classification)
4.  Community confidence (upvotes/downvotes weighted by reputation)
5.  Freshness (recency weighting)
6.  Liveness (active and unchanged source)

Each dimension has: - Defined scoring method - Numeric range - Weight
coefficient

The total weight is computed as:

Total Weight = (Relevance × A) + (Depth × B) + (Reliability × C) +
(Community × D) + (Freshness × E) + (Liveness × F)

Rubric versions are published and versioned.

Each article stores the rubric version used.

------------------------------------------------------------------------

## 7. Weighted Evidence Graph

The article is generated from a weighted citation set.

Properties: - Citations ranked by weight - Minority views preserved
above threshold - Trivial mentions suppressed below threshold -
Conflicting evidence surfaced explicitly

The graph is inspectable by users.

------------------------------------------------------------------------

## 8. AI Synthesis Engine

AI constraints:

-   May ONLY use provided citation text.
-   Must attribute claims.
-   Must state conflicts between sources.
-   Must omit unsupported facts.
-   Must avoid normative or persuasive language.
-   Must proportionally reflect citation weights.

AI prompt includes: - Topic - Weighted citation summaries - Explicit
synthesis rules - Required structured output format

Output format must be structured (e.g., JSON schema).

------------------------------------------------------------------------

## 9. Article Structure

Each generated article includes:

-   Title
-   Executive summary
-   Structured sections
-   Attribution language
-   Citation list
-   Weight snapshot
-   Rubric version
-   Generation timestamp

All articles are versioned.

Regeneration occurs when: - New citations added - Citation weights
change - Sources expire - Rubric version updates

------------------------------------------------------------------------

## 10. Determinism and Reproducibility

Given: - Same citation set - Same rubric version - Same AI configuration

The output must be reproducible.

No hidden data sources. No external knowledge allowed.

------------------------------------------------------------------------

## 11. Transparency Features

Each article exposes:

-   Full citation list
-   Individual citation weights
-   Rubric version
-   Historical revisions
-   Regeneration log

Users can inspect: - Why a citation influenced output - Why a claim
appears - Why a claim does not appear

------------------------------------------------------------------------

## 12. Anti-Gaming Mechanisms

-   Signed identity requirement
-   Reputation-weighted voting
-   Detection of coordinated voting clusters
-   Domain diversity encouragement
-   Weight caps to prevent single-source dominance

------------------------------------------------------------------------

## 13. Periodic Maintenance

System periodically:

-   Re-checks citation liveness
-   Re-extracts content if changed
-   Recalculates weights
-   Flags major divergences
-   Triggers regeneration if thresholds crossed

------------------------------------------------------------------------

## 14. Future Expansion

Phase 1: - Centralized application - Signed identity integration -
Public rubric - Deterministic synthesis

Phase 2: - Protocol-native identity support - Portable citation
records - Federated article publishing - Multi-identity adapter support

------------------------------------------------------------------------

## 15. Positioning Statement

Centipedia is not AI-written content.

It is evidence-compiled knowledge.

Humans submit sources.\
A public rubric weights them.\
AI deterministically synthesizes the result.

The article is a function of weighted evidence.

------------------------------------------------------------------------

End of Document
