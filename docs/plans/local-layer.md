# Telemetry, memory and curation: local, and agnostic of engine and model

**Status: planning, for discussion (2026-11-26).** Not checked, not phased, and nothing is built from it.
It gathers what the owner asked for and a first shape for each part, so that the use cases can be
discussed before a design is fixed. Its open decisions are at the end (LD1 to LD8).

## What the owner asked for

- **Telemetry, memory and curation are all local,** and **none depends on the engine or the model.**
- **Memory is pruned, and weighted by what is relevant over time** ("heat mapping"). Early models latched
  on to odd facts unless someone deleted them by hand, and most households will run lighter models, with
  less sophisticated handling, for at least the first two years.
- **Topics with their own privacy.** For example, one parent planning a business trip (private to that
  person) and the same household planning a family holiday (shared with everyone), kept apart by the
  assistant. Many complications are expected; the use cases are to be discussed first.

## Principles

1. **Nothing leaves the Mac.** Auster collects nothing about a household: no analytics, no crash reports,
   no usage figures sent anywhere. v0.1 already says exactly what is sent and to whom (v0.1 plan, D3.10).
2. **Everything lives in Auster's own layer.** The engine and the model only ever see a request in the
   OpenAI-style API that every engine offers. Memory is plain data on the Mac, put into each request.
   It is never kept in a model's weights (fine-tuning) or in an engine's saved caches, which only one
   model can read. So a model can be replaced, or an engine, and nothing is lost.
3. **Auster decides what a model sees.** A small model treats whatever is in front of it as relevant and
   cannot reliably ignore an odd fact once it is there. The main defence is not asking the model to weigh
   memories but choosing which ones reach it, and how many. All weighting happens before the request.
4. **Privacy is enforced by Auster, never by the model.** A request carries only what its sender may
   see. No model, however good, is trusted to keep two people's private matters apart inside one context.
5. **A person can see, correct and delete everything,** and nothing is removed silently.
6. **Limits are measured, not guessed.** How much memory a build can take without its answers slipping
   is a figure measured for each build, as its speed is.

## The base: Auster in the request path

Today the chat page talks straight to `llama-server` (v0.1 plan, BD1). Per-person usage figures and
memory both need Auster between the household's devices and the engine: a small server of Auster's own
that speaks the OpenAI-style API on both sides. The concept and the v0.1 plan call it the front door and
place it in phase 6.

It would:

- know **who** is asking, by a key per person rather than per device (LD2);
- add the memories that person may see, within the build's budget;
- count requests and tokens by person, never keeping their text;
- carry out tool calls such as "remember this", which the engine itself never runs (v0.1 plan, B4);
- answer the household's devices the same way whatever engine is behind it.

**When it comes is the first decision** (LD1): memory cannot start before it.

### Three places v0.1 leans on llama.cpp

These are small, and best replaced before a second engine (MLX) arrives:

| v0.1 uses | Agnostic replacement |
|---|---|
| The writing speed from `llama-server`'s own `timings` field (A5) | Auster times the answer itself and counts tokens from the API's standard `usage` field |
| `/health` for the sign of a broken engine (B5, BD19) | Optional: used when the engine has it; otherwise the probe's own question decides |
| The GPU limit from `llama-server --list-devices` (C1) | macOS's own figure for the Mac, read without the engine (not yet tried from JavaScript for Automation) |

## T. Telemetry, local

- **Health history.** The check job already probes the server every four hours (v0.1 plan, B5). Its
  results are kept with their dates, so that `auster status` and a later launcher window can show how
  the server has been doing: speed against this Mac's baseline, failures, restarts.
- **Usage by person,** through the front door: requests and tokens per day. Never the text of a question
  or an answer.
- **Heat, for telemetry:** daily figures for a few months, then monthly totals, then the detail is
  dropped. The household can clear it all.
- **What is never kept:** questions, answers, the content of memories, anything sent off the Mac.

## M. Memory

### M1. A memory is a record

Its text; its **topic** and **scope** (M6); who wrote it and how (**source**: said by a person, inferred
by the model, imported from a document); when it was written; when it was last used and how often;
whether a person confirmed or corrected it; and an expiry, if one was given.

### M2. Heat: how relevant a memory is now

Worked out by Auster, never by the model. A first shape, to be tuned by measurement:

- **Source sets the start.** Something a person said ("remember that the bins go out on Tuesday") starts
  warm. Something the model inferred from a conversation starts cold, and is not used until a person
  confirms it. **Unconfirmed inferences are where odd facts come from;** for the lightest builds they may
  not be written at all (M5).
- **Heat fades with age, at a rate set by kind.** A routine fades over months; a passing state ("Tom has a
  cold") over days; a dated plan (a trip) stays warm until its date and then cools quickly.
- **Use and confirmation warm it.** A memory that keeps being relevant stays warm; one never matched
  cools.
- **A newer memory on the same subject replaces the older one,** rather than sitting beside it. The older
  one is archived, not deleted.

### M3. The budget, and what goes into a request

Each build has a **memory budget**, a number of tokens, measured (M10). A request gets, within that
budget:

1. only the memories its sender may see (M6);
2. of those, the ones that match the question, by topic and by plain keywords first (no extra model
   needed); embeddings later, as an option;
3. hottest first, until the budget is full.

A light build might get a few hundred tokens of its best-confirmed facts; a large one a few thousand.

### M4. Pruning, in stages, never silent

hot (put into requests) → cool (left out unless someone asks for it) → archived (kept, listed, can be
deleted) → deleted only by a person, or by an expiry a person set.

A periodic **"what Auster remembers"** review shows each person their own memories and the household's,
coldest, least confirmed and contradicted first, so that oddities are caught by a person rather than left
to linger. "Forget everything about X" removes it from every stage, after one confirmation.

### M5. Lighter models

For the first years most households will run light builds. For them:

- smaller budgets, from measurement;
- no memory written from the model's own inferences; only what a person says, or confirms;
- the "remember this" tool offered only to builds that have passed a memory test (M10);
- never two people's private topics in one request (principle 4, M6).

### M6. Topics and scopes

Each memory belongs to a **topic** (a business trip, the family holiday, a child's homework, the house),
and each topic has an **owner** and a **visibility**:

- **private:** its owner only;
- **household:** everyone;
- **named people:** some of the household;
- **household except someone:** a surprise.

A dated topic (a trip, a holiday) cools after its date and is offered for archiving. Auster chooses what a
request may carry by its sender and the topics' visibility, so the model never has to keep them apart.

**Documents** can belong to a topic too (an itinerary, an appliance manual), found by keyword first.
An embedding model, if one is used later, is a build like any other and is curated the same way (C).

### M7. Use cases to discuss

These are the complications the owner expects. Each needs an answer before memory is designed in detail.

1. **The business trip and the family holiday.** One parent's trip is private; the holiday is the
   household's. The dates may overlap. Should the household's planning know that parent is away, without
   the details? One answer: the owner of a private topic may let it show as busy, with dates only, the way
   a shared calendar shows busy time.
2. **A surprise.** A household topic hidden from one person, the one whose birthday it is.
3. **A shared device.** The family iPad is used by everyone. Keys are per device today (v0.1 plan, B7).
   Until a person can be told apart on it (a profile, a PIN, or a key per person), it should see the
   household's topics only.
4. **Not admitting that something is hidden.** A child asking about a parent's private trip should get
   the answer the assistant would give if there were no such trip, not "I can't tell you about that",
   which reveals that it exists.
5. **A topic changing hands.** "Tell everyone about the trip now": a private topic becomes the
   household's. A record of the change, and nothing copied.
6. **A conflict across scopes.** A private "flight on Tuesday" against the household's "drives the
   children to school on Tuesday". Only the owner of the private fact can be told of the clash.
7. **A guest.** A babysitter's phone: a guest scope with an end date, seeing only what it is given.
8. **Children.** Homework topics per child; what parents may see of a child's topics.
9. **Forgetting on request,** including archived copies and anything built from them.
10. **The model writing memory from a conversation:** what a light build may do, and what only a person
    may do.

### M8. Where memory is kept

In the data root, mode 0700, as plain files or a SQLite database (`sqlite3` ships with macOS). Protected
at rest by FileVault. Exportable and importable as plain text, so a household is never locked in. Whether
it is backed up with the rest of the data root, and how, is open.

## C. Curation, local

### C1. An evaluation anyone can run

A tool that runs phase 1's protocol against any OpenAI-style server, on the Mac it runs on, and writes a
findings file and a registry line:

- speed, timed by Auster;
- memory figures, through a small adapter per engine, since only the engine can report them;
- the household quiz;
- tool calls;
- repeatability;
- the distraction budget (M10).

The project uses it to curate, and a household can use it to check a build on its own Mac. Nothing it
measures is sent anywhere.

### C2. The policy, to write

The mechanics exist in v0.1: the registry's judgements, tiers, withdrawals and the release gate. The
policy does not:

- what a model must measure to enter a recipe;
- how often new models are reviewed;
- when a third party's build is acceptable (`endorsed`);
- what triggers a withdrawal;
- who signs off.

### C3. Heat, for curation

On a Mac, builds that are superseded or unused cool and are the first offered for removal, which fits
the disk rule v0.1 already has (v0.1 plan, C6). The project learns nothing from households' usage,
because nothing is sent; its curation rests on measurement alone.

## M10. Measured: how much irrelevant memory a build takes

Measured on 2026-11-26 (`docs/phase-2.md`, section 9). Phase 1's 56 household questions, with 0, 20,
80 and 300 invented, irrelevant facts ("Uncle Oswin's cat is a tabby named Biscuit") added to the system
prompt as things the household asked it to remember: about 0, 220, 800 and 3,000 tokens. Temperature 0,
one run each.

| Facts added | none | 20 | 80 | 300 |
|---|---|---|---|---|
| Order 2, Magistral Small (24B) | 53 | 52 | 53 | 53 |
| Order 1, Mistral Small 4 (119B, 3-bit) | 50 | 52 | 43 | 47 |

- **No reply in any run named a remembered fact.** Neither model latched on to an unrelated one.
- **The lighter model was unaffected. The larger one lost answers at 80 and 300 facts,** and what it
  lost was the answer's form, not its content: "15 litres." without the requested `Answer:` line, a JSON
  list where an object was asked for, the literal text `<answer>`. Added context weakened how well it
  kept to instructions.
- **Single runs vary:** order 1 scored 53 on the same questions earlier the same day and 50 here with no
  facts added; three questions differ.

So the first measurement does not show the expected weakness of a light model with unrelated facts, and
which model suffers is not predictable from its size: it has to be measured per build. Before any budget
means anything, two more tests are needed:

1. **Repeated runs,** so that a drop can be told from noise of about three questions in 56.
2. **Memories that matter but are wrong,** which is the owner's case: a fact replaced by a newer one (an
   old bin day beside the new one), a fact about the wrong person, and an odd fact close to the question.
   Latching on to the wrong fact, rather than ignoring an unrelated one, is what M2 and M4 must prevent,
   and the measurement should show how much of it each build does.

## Proposed placing (for the owner)

| Part | Proposed phase |
|---|---|
| The three agnostic replacements | Before a second engine: phase 3, or folded into phase 2 if cheap |
| The evaluation tool (C1) and the curation policy (C2) | Phase 3: the second recipe needs both |
| Health history (T) | With the launcher window, phase 4, which shows it |
| The front door, people's keys, usage figures | Earlier than phase 6 if memory is wanted sooner (LD1) |
| Memory v1: what people say, topics with private and household scopes, measured budgets, the review | After the front door |
| Documents, embeddings, model-written memory | Later, after v1 is measured in use |

## Decisions for the owner

| | Question |
|---|---|
| LD1 | When the front door comes: kept in phase 6, with memory after it, or brought forward |
| LD2 | Keys per person rather than per device, and how a shared device tells people apart |
| LD3 | Who may write a memory in v1: people only, or the model too (and for which builds) |
| LD4 | Whether a private topic may show as busy to the household (M7, case 1) |
| LD5 | What parents may see of children's topics (M7, case 8) |
| LD6 | How long usage figures are kept, and whether the household can see each other's |
| LD7 | Memory's form on disk (plain files or SQLite) and its backup |
| LD8 | Whether the three agnostic replacements go into phase 2 now |

## Tests to plan (outcome-based, as in v0.1)

- **Scope isolation, without a model:** a request from one person's key never carries another person's
  private topic. The test asserts on what the front door sends to a stub engine, so it needs no model.
- **Heat and pruning by the clock:** a memory cools, archives and expires on schedule (a stub clock), and
  nothing is deleted without a person or an expiry.
- **Forgetting:** "forget X" leaves nothing of X in any stage or file.
- **Telemetry holds no text:** no question, answer or memory content in any telemetry record.
- **The distraction budget:** the quiz with irrelevant memories added, per build (M10).
- **The agnostic replacements:** speed, health and the GPU limit with a stub engine that has no `timings`
  and no `/health`.
