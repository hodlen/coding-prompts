---
name: data-engineering
description: "Data semantics and correctness for datasets, pipelines, and analyses that transform data. Use with the language skill."
---

# Data Engineering

Apply these principles where they affect the result. Reuse guarantees from schemas, upstream contracts and library operations; check only what remains unproved. Language-specific behavior belongs in the language skill, such as `python-patterns` for pandas.

- **Row meaning and joins.** Establish what a row represents and any required identity or uniqueness. Preserve the intended population and multiplicity through joins and grain changes: distinguish join cardinality from match completeness, and handle unmatched or null keys according to the result contract. Prevent accidental row loss, fan-out and double counting.
- **Time.** Distinguish instants, local times and dates, and event time from processing time where relevant. Define the timezone and interval boundaries that affect comparisons or grouping, and late-data behavior for incremental results. Verify relevant boundaries to catch omissions, overlap and misassigned periods.
- **Values.** Establish types, precision, nullability and invalid-value handling at data boundaries. Parsing, coercion and representation changes must preserve those meanings or implement an explicit loss policy; prevent silent truncation, precision loss and confusion between missing values and zero.
- **Ordering and aggregation.** Order-dependent results need a guaranteed order and tie semantics when ties affect the answer. Aggregation needs an output grain, population, weighting and missing-value policy. Distinguish overall ratios from averages of individual ratios; choose by the metric's meaning.
- **Reruns and identity.** Retries and interrupted writes must preserve the intended effects without duplication or partial publication. When reproducibility is required, identify the actual input and output versions, code and result-affecting configuration; consumers must resolve the intended artifact rather than accidentally mixing runs.
- **Evidence.** Test relevant decisions with small independently derived results and boundary cases, such as duplicate or unmatched keys, nulls, empty input and window edges. Use conservation and uniqueness checks where the contract requires them and existing guarantees do not suffice; they cannot alone prove that values belong to the correct rows.
