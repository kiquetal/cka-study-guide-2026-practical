# <Topic title> — <one-line what-this-is>

<!--
TEMPLATE for formalized domain notes. Copy this file into the right
domains/NN-<domain>/ folder, rename to notes-<topic>.md, fill in the sections,
delete the ones you don't need, and remove these comments.
Goal: every note has the SAME shape so studying is predictable.
Then link it from that domain's README and from the top-level INDEX.md.
-->

🎯 **Domain NN — <domain name> (<weight>%).** <why this topic matters in one line.>

<!-- If there's a diagram, put the image in domains/NN-.../images/ and embed it: -->
![<alt text>](images/<file>.png)

*<caption: source + how it maps to the lab, if relevant.>*

---

## The idea (theory)

<The core concept in plain language. What problem it solves. The mental model.>

## Why is this relevant?

<!-- Two angles. Keep it tight — a few bullets each. This is what justifies the note. -->
- 🎯 **For the exam:** <what task/competency this maps to; why it earns points.>
- 🌍 **Real-world / edge cases:** <the strange behaviour or outage this explains —
  "if you ever see X, it's probably this." The non-obvious failure it unlocks.>

## Key parts

| Thing | Job | Exam-relevant note |
|-------|-----|--------------------|
| ... | ... | ... |

## How it works / flow

<Step-by-step of the mechanism, or a request/lifecycle flow. Numbered steps.>

## Verified on the lab

<!-- Show REAL output from the vagrant-kubeadm or kind cluster. This is the
     "theory + proof" combo that makes notes stick. -->
```text
<command + trimmed output>
```

## Commands to remember

```bash
<the few imperative one-liners for this topic>
```

## Gotchas / failure modes

- <common mistake → symptom → fix>

## 30-second self-test

1. <Q> → **<A>**
2. <Q> → **<A>**

---

<!-- cross-links to related notes/labs, e.g.: -->
See also: [`labs/<lab>.md`](labs/<lab>.md), [`../../environment/<doc>.md`](../../environment/<doc>.md).
