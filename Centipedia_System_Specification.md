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

Requirements:
- Persistent identity per user
- Signed authentication
- Prevent trivial multi-account abuse
- **Abstracted Identity Model:** Identity must not be hardwired to a single platform. The model should reflect `did`, `provider` (e.g., atproto, nostr), and `public_key`.
- Extensible to decentralized identity systems

The identity layer must support:
- Unique user identifier
- Reputation tracking
- Vote history
- Citation submission history

------------------------------------------------------------------------

## 5. Citation System

The system cleanly separates the canonical resource from the act of sharing it to future-proof against noisy social ingestion.

### 5.1 Source (The Canonical Resource)
Represents the URL-level entity independent of how it entered the system.
- `canonical_url`, `domain`, `title`
- `first_seen_at`, `last_checked_at`
- `content_hash`
- `status` (live, dead, redirected)

### 5.2 CitationEvent (The Act of Introduction)
Represents how a Source was linked to a Topic.
- `source_id`
- `event_type` (e.g., explicitly submitted, socially observed, admin imported)
- `identity_id` (who submitted/shared it)
- `weight_modifier` (e.g., an explicit submission carries more weight than a passive social share)
- `created_at`

### 5.3 Validation

Each citation must be: - Reachable (HTTP 200) - Content-extracted -
Stored as a snapshot hash - Re-checked periodically

Dead or altered sources reduce weight automatically.

------------------------------------------------------------------------

## 6. Public Rubric System

**The Rubric is the core product.** It is what separates Centipedia from a black-box AI content farm. Centipedia does not claim ideological neutrality; it claims mathematical, structural transparency. 

Each citation is scored across dimensions to compute a "Trust Weight".

Example rubric dimensions:

1.  Primary Source Status (e.g., court documents, data sets, original research)
2.  Relevance to topic (semantic similarity score)
3.  Depth of coverage (extent of topic focus)
4.  Source reliability (domain credibility classification)
5.  Cross-Source Corroboration (does the claim appear independently across diverse domains?)
6.  Community confidence (upvotes/downvotes weighted by reputation)
7.  Freshness & Liveness (active and unchanged source)

Each dimension has: - Defined scoring method - Numeric range - Weight
coefficient

The total weight is computed as:

Total Weight = (Relevance × A) + (Corroboration × B) + (Reliability × C) + ...

**Transparency Mandates:**
- Rubric logic is published and strictly versioned.
- Each article stores the rubric version used during generation.
- Users must be able to inspect *why* a source was weighted high or low.

------------------------------------------------------------------------

## 7. Weighted Evidence Graph

The article is generated from a weighted citation set.

Properties: - Citations ranked by weight - Minority views preserved
above threshold - Trivial mentions suppressed below threshold -
Conflicting evidence surfaced explicitly

The graph is inspectable by users.

------------------------------------------------------------------------

## 8. AI Synthesis Engine

AI orchestration must be treated as a deterministic pipeline isolated in service objects (e.g., `app/services/ai/`), not coupled to controllers. 

AI constraints:

-   May ONLY use provided citation text.
-   Must attribute claims directly to highly-weighted sources.
-   Must explicitly surface minority views and conflicting evidence if source weight meets the threshold.
-   Must omit unsupported facts entirely.
-   Must avoid normative or persuasive language.
-   Must proportionally reflect citation weights without imposing independent LLM training bias.

AI pipeline steps include: 
- Topic classification → Claim extraction → Stance detection → Rubric evaluation → Article drafting.

Output format must be strictly structured (e.g., JSON schema) to allow UI rendering to trace prose back to specific `CitationEvent` records.

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
