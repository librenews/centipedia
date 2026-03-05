# Centipedia Rubric V1

This document explains the mathematical formula used by Centipedia to weight citations before AI synthesis.

## Versioning
- **Current Version:** `1.0.0`
- **Status:** Active
- **Applied to:** All new topics and synthetic generation events.

---

## 1. The Core Philosophy

Centipedia does not use editorial boards to determine truth, nor does it rely on raw social popularity (which can fall prey to ideological alignment or gaming). Instead, Centipedia uses a **deterministic mathematical rubric** to score every piece of evidence (a "Citation Event") submitted to the system.

Only citations that score above the *Synthesis Threshold* are included in the final AI-generated article. The AI strictly reflects the proportional weight of the underlying sources.

The Total Trust Weight formula for a single citation is:
`Total Weight = (URL Base Score) × (Domain Multiplier) × (Corroboration Multiplier)`

---

## 2. URL Base Score (0 to 10 points)

The URL Base Score evaluates the *specific web page* submitted, divorced from its domain's reputation. This is assessed via AI feature extraction.

### A. Primary Source Indicator (Max +4)
Is the source firsthand evidence or derivative summary?
- **+4:** Direct Evidence (e.g., government data `.gov`, court filings, academic papers with DOIs, raw dataset releases).
- **+2:** First-Hand Reporting (e.g., on-the-ground journalism, direct interview transcripts).
- **+0:** Secondary / Derivative Content (e.g., op-eds, aggregators, blogs reacting to news).

### B. Logical Density (Max +3)
Does the text contain verifiable claims?
- **+3:** High density of statistics, quotes, or falsifiable claims.
- **+1:** Moderate factual density mixed with narrative.
- **+0:** Mostly rhetorical, opinion, or persuasive language.

### C. Tone Neutrality (Max +2)
Does the text attempt to persuade emotionally?
- **+2:** Neutral, objective, boring language.
- **+0:** Highly emotionally charged or normative language.

### D. Freshness (Max +1)
Is the information current?
- **+1:** For evolving events, published within an active window.
- **+0:** Stale content (unless the topic is strictly historical).

---

## 3. The Domain Multiplier (0.5x to 1.5x)

The Domain Multiplier represents the **Emergent Reputation** of the publishing domain. We do not manually assign these modifiers. They are calculated dynamically across the entire network.

- **Baseline:** Every domain (from the *New York Times* to an unknown blog) starts exactly at **1.0x**.
- **Modifiers (+/- 0.5x):** The system scales the multiplier up to 1.5x or down to 0.5x based on archival stability.
  - *Does the domain frequently silently edit text?* (Link Rot / Silently Altered Penalty)
  - *Does the domain frequently 404?* (Archival Instability)

*Note: In future versions (V2+), the Domain Multiplier will also include an Isolation Penalty (penalizing echo chambers) and a Corroboration Reward (rewarding domains that originate claims later proven by others).*

---

## 4. The Corroboration Multiplier (1.0x to 2.0x)

The Corroboration Multiplier is the epistemic core of the rubric. A single citation is weak. A broad network of citations is strong.

When a URL's claims are extracted, they are cross-referenced with all other citations evaluating the same continuous topic.

- **Baseline:** **1.0x** (A lone claim with no support).
- **Corroborated:** Up to **2.0x**. If a claim in Citation A is independently verified by Citation B and Citation C, its weight is multiplied.
- *Anti-Gaming Rule:* Corroboration only counts heavily if the corroborating sources are from structurally distinct domains (to prevent holding companies from artificially amplifying their own wires).

---

## 5. Synthesis Rules

During article generation:
1. **The Threshold:** Citations with a final weight below `X` (TBD based on topic density) are completely ignored.
2. **Conflicting Claims:** If an event has two mutually exclusive claims, and both exceed the threshold, the AI *must* include both in the article, explicitly stating the opposing sides and their respective aggregate weights.
3. **No Inference:** The AI may not generate prose linking claims logically unless the sources explicitly link them. 
