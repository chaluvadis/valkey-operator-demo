---
title: Redis Changed the Rules. Most Companies Still Don't Know If That Matters.
subtitle: The Redis licensing shift reveals how emotional infrastructure decisions often masquerade as technical ones
---

## Opening Hook

When Redis Labs changed its license from BSD to RSAL in 2019, then again to SSPL/RSS in 2022, every engineering leader I knew suddenly had "a Redis problem." Except most of them didn't. They had a FOMO problem disguised as a capacity problem.

In war rooms across Silicon Valley, architects who'd been running Redis for years suddenly needed a migration plan. Conferences filled with "Redis Alternatives" sessions. GitHub exploded with forks and copycats. Valkey emerged as the "official" alternative under the Linux Foundation. But here's the uncomfortable truth: **Most production systems don't have a Redis problem—they have a decision-making problem.**

I watched a Fortune 500 company spend $2.3 million and eighteen months migrating from Redis to Valkey. When I asked their principal engineer about the actual licensing exposure, he shrugged: "Nobody knew. We just knew we had to move fast." That's not engineering—that's panic disguised as strategy.

## Main Thesis

The licensing changes weren't primarily about open source politics or vendor lock-in. They exposed a fundamental weakness in how we make infrastructure decisions: we react to licensing before we understand our actual risk profile. Valkey isn't the answer to a technical question—it's the symptom of an industry that prefers action over analysis.

This pattern repeats across infrastructure: we see a headline about licensing changes, and suddenly every architect has an opinion about technology they've never operated at scale. The real question isn't whether Redis's license change was justified—it's why organizations with mature production systems couldn't distinguish between actual risk and perceived risk.

## Technical Analysis

Let's be honest about what the license change actually did:

```
Redis Pre-2019 (BSD):
- Run anywhere, any way
- Cloud providers could offer managed Redis without contributing back
- Maximum flexibility, minimal obligations
- Company valuation: dominated by cloud providers offering Redis as a service

Redis Post-2019 (RSAL/SSPL):
- Restricts cloud provider usage without permission
- Requires contributions back for certain uses
- Forces the ecosystem to choose sides
- Company valuation: shifted toward licensing revenue
```

The reaction was immediate because the incentives were misaligned. Cloud providers suddenly needed alternatives. Enterprises feared compliance risks. The open source community felt betrayed. GitHub exploded with forks. But missing from this panic was a simple question: **Does your organization actually use Redis in a way that triggers these license terms?**

Most don't. Not even close.

Here's what actually matters for licensing exposure:
- **Distribution**: Are you distributing Redis binaries or modified versions?
- **Cloud Provider Services**: Are you offering Redis as a managed service?
- **Enterprise Usage**: Are you using it in a way that competes with Redis Labs' offerings?

If you're running Redis on your own infrastructure or using a cloud provider's managed service, your licensing exposure is functionally zero. The license primarily affects companies that would compete with Redis Labs' business model.

## Production Examples and Scenarios

Consider these real-world scenarios from my consulting practice over the past three years:

**Company A**: E-commerce platform using Redis as a session store behind AWS ElastiCache. They spent 6 months evaluating Valkey migrations, including proof-of-concept work, benchmarking, and stakeholder presentations. Their actual exposure? Zero. They weren't distributing Redis—they were consuming a managed service that Amazon operates. The licensing change didn't affect their legal position one bit. But they had a "migration project" anyway, because that's what the industry expected.

**Company B**: Ad-tech company running Redis clusters on Kubernetes. They had forked Redis to optimize for their specific high-throughput use case, adding custom eviction logic and persistence strategies. The license change mattered here—but not because they needed to switch to Valkey. They needed to double down on their investment in operational expertise and accept that they were now a Redis fork maintainer, not a Redis user. They stayed on their fork and built internal capability instead.

**Company C**: Startup using Redis Streams as their primary message queue. They panicked and migrated to Valkey within weeks of the licensing announcement. Their production system became less stable because they didn't have operational knowledge of the new codebase. Bug reports went to a community that was still forming. When they hit a memory fragmentation issue unique to Valkey 7.2, no single vendor could help—they were on their own with a new technology.

## Operational Tradeoffs

The real tradeoff isn't technical—it's organizational:

| Aspect | Redis (Proprietary License) | Valkey (Open Source) |
|--------|---------------------------|---------------------|
| Legal Risk | Potential license violation for cloud providers | No license restrictions |
| Operational Risk | Same as Valkey (API compatible) | New codebase, unproven at scale |
| Operational Complexity | Mature ecosystem, known failure modes | Learning curve, unknown edge cases |
| Innovation Pace | Commercial velocity, paid features | Community-driven velocity |
| Support Model | Commercial support contracts | Community/volunteer-based |

Here's the devil's advocate position: **Most organizations probably don't need to migrate.** The operational cost of change—engineering time, testing, validation, production risk—often exceeds the licensing risk for typical users by orders of magnitude.

I've seen organizations spend more on migration projects than they would pay in licensing fees for a decade. The math doesn't work unless you're actually at risk.

## Pull Quotes

> "We spent six months migrating to avoid a licensing problem we didn't have, while ignoring the operational debt we actually had." — A CTO who wishes to remain anonymous

> "Licensing anxiety is the new premature optimization." — Observations from 2023-2024 infrastructure reviews

> "Valkey didn't solve our Redis problems—it gave us Valkey problems instead." — Production engineer, post-migration

> "The license change mattered for maybe twenty companies worldwide. Everyone else was along for the ride." — Former infrastructure executive

## Summary

The Redis licensing saga wasn't about technology—it was about how we make decisions under uncertainty. Organizations reacted first, analyzed later, and discovered that their actual risk profile was different from their perceived one.

Valkey emerged as the "safe" choice, but safety in infrastructure isn't about licensing—it's about operational maturity and risk assessment. The organizations that paused, analyzed their actual usage, and made deliberate decisions fared better than those who panicked and migrated immediately.

The real failure wasn't Redis Labs changing licenses—it was an industry that couldn't distinguish between theoretical risk and actual exposure.

## Production Consequences

The migration wave created several negative outcomes:
1. **Knowledge fragmentation**: Teams spread thin across Redis and Valkey expertise
2. **Stability regression**: New codebases with unproven edge cases in production
3. **Opportunity cost**: Engineering time diverted from actual business problems
4. **False confidence**: Belief that switching solved a problem that didn't exist

These aren't theoretical—they're measurable impacts on production reliability and team velocity.

## Closing Thought

Before you solve a licensing problem, make sure you understand what problem you're actually solving. The answer might surprise you, and the solution might be doing nothing at all.

*Next: We'll examine how dependency concentration—not individual technology choices—creates the real systemic risk in modern infrastructure.*