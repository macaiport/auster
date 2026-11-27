# Telemetry, memory and curation: local, and agnostic of engine and model

**Status: planning, for discussion (2026-11-26).** Not checked, not phased, and nothing is built from it.
It gathers what the owner asked for and a first shape for each part, so that the use cases can be
discussed before a design is fixed. Its open decisions are at the end (LD1 to LD15).

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

### T1. Sharing a report back, by a person's choice (for discussion)

The owner asked (2026-11-27) whether households could share figures back, so that the project could say,
for example, which builds send the most requests on to a data center. **It would change principle 1,**
from "nothing leaves the Mac" to "nothing leaves the Mac unless a person has read it and sent it" (LD15).

**Why it is worth it.** Every figure behind the curated list was measured on one development Mac. Reports
from real Macs would show which builds fit where section C says they do, how fast they really are, how
often they fail their test or their server check, and where the local model falls short.

**The shape that keeps the rest of the principles:**
- **A report, not a stream.** `auster report` writes one plain file from the local telemetry (T). The
  person reads all of it, then sends it, or not. Nothing is sent by Auster itself, and nothing on a
  schedule.
- **No install id.** Two reports from one Mac cannot be joined by anything Auster puts in them.
- **Counts and buckets only, from a fixed, published list of fields.** Memory as the standard sizes,
  speeds rounded, dates to the week, usage in bands. A field not on the list is never added on the Mac.
- **Never:** the text of a question, an answer or a memory; names of people or devices; keys; addresses;
  the `.local` name; the router; the time of day; the time zone; any path in the home folder.

**What a report could hold:**

| Figure | What it would tell the project |
|---|---|
| The Mac: chip family, memory size, macOS major version | which Macs the builds are used on; whether section C's limits hold on Macs other than the development one |
| The build serving, its setting (people, context), and whether section C chose it or the person narrowed it | whether the order and the settings fit real households |
| Writing speed, against the registry's figure | the speeds the registry should state for each chip |
| The recipe's test: pass or fail, and which question numbers failed | which questions catch which builds; curation (C1 to C3) |
| Updates: offered, accepted, declined; server checks passed, open, not answered; rollbacks; `failed/` entries | whether the update is safe in practice |
| Health: the probe's states by count (`ok`, `slow`, `broken`, `failed`, `down`), restarts | how often memory pressure breaks an engine (BD19) |
| Use, in bands: requests a day, tokens, the busiest number of answers at once, the idle share of the day | the setting for people; how much time night work has (LD10) |
| Escalation, when it exists: requests sent to a data center as a share of all requests, by build, and the provider | **the owner's example:** where each local build falls short |
| An install that stopped: the step and the exit code | where the installer fails |

**What a figure cannot say on its own.** How often a household escalates depends on its questions and
its habits as much as on the build, so escalation is reported beside the number of requests and read
across many Macs, never from one. A report from a Mac with a rare combination (an unusual chip and memory
size) can point to its household even without a name; buckets make that harder, not impossible.

**Who receives it.** Auster runs no server today, so the first form needs none: the person attaches the
report to a GitHub issue form, or sends it by email. On GitHub it is public, which is why it must hold
nothing that identifies the household; and the account or address that sends it is seen by whoever
receives it, whatever the report holds. A collecting server would come later, if reports are many
enough: it costs money, needs a privacy policy, and makes whoever runs it the controller of that data,
which needs a legal entity (as `agents-and-escalation.md`, E3a, notes for a referral share). Totals
would be published, so that the households that sent reports can see what was made of them.

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
- **A newer memory on the same subject replaces the older one at once,** rather than sitting beside it:
  the older one leaves the requests the moment the newer is written, and is archived, not deleted. This is
  the measured weakness: with both in front of them, both household builds gave the out-of-date fact in
  about a third of answers, choosing by its place in the list, not by its date (M10).
- **Knowing that two memories are on the same subject** is settled when the newer one is written, with
  the person who says it: "this replaces 'the green bin goes out on Thursdays', right?". A person's yes is
  cheaper and surer than any model's guess. Night work may only propose such pairs for the review.

### M3. The budget, and what goes into a request

Each build has a **memory budget**, a number of tokens, measured (M10). A request gets, within that
budget:

1. only the memories its sender may see (M6);
2. of those, the ones that match the question, by topic and by plain keywords first (no extra model
   needed); embeddings later, as an option;
3. hottest first, until the budget is full.

A light build might get a few hundred tokens of its best-confirmed facts; a large one a few thousand.

### M3a. Layers, with pointers to go deeper

From the owner's use of early models, whose context windows were small: paint with broad strokes and point
to the details, to be fetched when needed. The models after them often forgot to follow those pointers,
and produced good work when reminded. So memory is layered, and going deeper is not left to the model
alone.

- **The layers.**
  1. **The index:** one line for each topic the sender may see, with a short pointer.
  2. **A topic's summary:** a paragraph.
  3. **The details:** the memory records and documents themselves.

  **Stored, the layers are a tree of any depth:** a topic can hold topics (the household, then the
  holiday, then its bookings). **Carried, the depth is a budget:** a request takes the index, then follows
  the matching branch down as far as the build's budget allows, so a light build may see two levels and a
  large one five. Auster does the descending, by matching, so that more depth never means more pointers
  for a model to forget. A practical limit on depth (perhaps four or five) keeps the review legible.
- **What a request carries.** The index always (it is small), the summaries of matching topics, and
  details only where needed, all within the build's budget (M3).
- **Who goes deeper, in three ways** (measured in M10: the first is the default for every build):
  1. **Auster fetches what plainly matches** (the topic, its keywords) before the request. Deterministic.
     With the right notes in front of them, both household builds answered all 36 questions right, in the
     least time; with the index alone they invented an answer two times in three.
  2. **The model may ask for a pointer** with a tool call ("open" a topic or detail), which Auster serves,
     for what Auster's matching missed. Both builds called the tool every time, but the larger opened the
     wrong topic 7 times in 36, so a build's tool use is measured before it is offered.
  3. **A reminder pass,** asking once more when an answer touched a topic whose details were not opened.
     **Measured, it does not earn its cost:** to remind, Auster must already know the right topic, and then
     fetching first does at least as well in about a third of the time. Off, unless a later build measures
     otherwise (LD9).
- **Summaries are derived, never the record.** A model writes a topic's summary from the records, so a
  light model's summary can drift or invent. Summaries are always made again from the records, never
  edited from the previous summary, so errors cannot build on each other. A higher layer's summary is
  checked against the records under it, not only against the summaries below it. They are marked as derived, and
  shown in the review (M4).
- **To measure:** questions whose needed fact sits only in a detail behind a pointer, answered with:
  - the index alone;
  - the index and the reminder pass;
  - Auster fetching first.

  The right answers, and the time each takes, per build. It decides how deep each build goes by default
  (LD9).

### M3b. External references

A detail can be a pointer to something outside Auster's own store: a file on the Mac, a calendar or
contacts on the Mac, a document on the home network, a web page. Each is fetched by Auster when needed,
never by the model directly, and:

- **local first:** a source on the Mac or the home network keeps principle 1; a source on the internet
  sends a request off the Mac, so it is off unless the household turns it on, per source (LD11);
- **scoped by its owner:** a parent's calendar is that parent's, whatever topic points at it;
- **dated:** each reference records when it was last read, and what it held (a hash), so a stale copy is
  seen, and night work refreshes it (M4a);
- **never in charge.** Outside text is the classic way to steer a model: a web page or an email can carry
  instructions. Content from a reference is passed to the model as quoted material, it can never start a
  tool call or change memory, and a light build gets it only through Auster's own fetching. This is
  tested (below).

### M3c. Ticklers: things that come back at a time

A memory can carry a time or a condition to come back: the bins the evening before, the flea treatment on
the 3rd, a passport six months before it expires, "ask how the trip went" once it is over. The dates are
worked out by Auster, not the model: phase 1's quiz shows models slipping on dates.

- **Quietly, first:** as its time nears, a tickler's heat rises, so it is in front of the model when
  someone asks anything near it, and each person can ask what is coming up.
- **Out loud, later:** telling someone unprompted needs a way to reach them. The chat page cannot receive
  a message it did not ask for, and a calendar event on the Mac syncs through iCloud, which leaves the Mac.
  So active ticklers wait for a channel the household chooses (LD12).
- **For memory's own hygiene:** a fact with an uncertain life ("Tom has a cold") gets a tickler to be
  confirmed or let go, so it does not linger (M4).

### M3d. Cross references

A fact often belongs to more than one topic: a passport that expires in March matters to one parent's
business trip and to the family holiday. With cross references the tree becomes a graph.

- **Stored once, linked from many.** The fact lives in one place and topics point at it, so a correction
  reaches every topic, and "forget" removes it everywhere. Night work removes links left pointing at
  nothing.
- **A link never grants access.** Each link is checked against the sender's scope as it is followed. A
  household topic linking to a private record carries nothing of it to anyone else, and shows no sign that
  the link exists (M7, case 4). This is the easiest way for something private to leak, so it is tested
  first.
- **Followed by Auster, one hop at a time,** within the budget, and never round a loop. A light build gets
  only what Auster followed.
- **Heat from every topic, with a cap.** A fact linked from many topics is warm because it keeps mattering,
  but no fact may fill a request's budget on its own.
- **Clashes become visible.** Linked facts that disagree (the trip's dates against the holiday's) are found
  by night work and shown only to someone who may see both sides (M7, case 6).
- **Who makes links:** a person; night work only proposes them, by the same name or date in two topics,
  for the review (LD13).

### M4. Pruning, in stages, never silent

hot (put into requests) → cool (left out unless someone asks for it) → archived (kept, listed, can be
deleted) → deleted only by a person, or by an expiry a person set.

A periodic **"what Auster remembers"** review shows each person their own memories and the household's,
coldest, least confirmed and contradicted first, so that oddities are caught by a person rather than left
to linger. "Forget everything about X" removes it from every stage, after one confirmation.

### M4a. Night work: refining while nobody is using it

The owner's expectation: the household uses the server for a small part of the day, so most of the time
it is idle, and that time can go on refining memory, the way people consolidate memories in sleep. With
that, the sets can be expected to stay well curated. How much of the day is idle is measured, not assumed
(T's health history).

- **What it does.**
  - Makes topic summaries and the index again from the records (M3a).
  - Works out heat again and moves memories between stages (M4).
  - Finds duplicates, contradictions and facts replaced by newer ones.
  - Proposes keywords and pointers for topics.
  - Repeats the build's own measurements now and then: its speed against this Mac's baseline, its memory
    budget (M10), so curation goes on locally (C).
  - Later, the embeddings for documents.
- **Derived things it may change; recorded things it may only propose.** Summaries, the index, keywords
  and heat are derived and can always be made again, so night work replaces them freely. Anything that
  would lose information (a merge, a deletion) goes into the review (M4) for a person to decide. A newer
  memory replacing an older one confirmed by its writer is not a loss: the older is archived at once (M2). Nothing a person said is changed overnight.
- **Checked, because light models make the summaries.** A derived summary is checked against its records
  before it replaces the old one: every name, number and date in it must appear in the records. That
  check needs no model, so it holds whatever the build. A summary that fails is kept out, and the old one
  stays.
- **A household request never waits.** Night work takes one of the engine's slots at most, and stops the
  moment a household request arrives: two answers written at once share the memory bandwidth, and each
  slows from about 35 to 20 tok/s (`docs/phase-2.md`, section 6). It resumes later from where it stopped.
- **When.** Only after a quiet spell (no requests for some minutes), never during an update or with the
  server stopped, never on battery, and within an energy limit the household sets: a Mac working its GPU
  draws far more power than one idling (LD10).
- **Seen, and switchable off.** `auster status` says what night work did and when, and one setting turns
  it off.

### M4b. Mulling it over: night work that brings an idea back

The owner's idea (2026-11-26): in quiet time, look back at a person's recent conversations and come back
with a thought: "about the gift for your sister, here is another idea". Assistants today answer and
forget until asked again. Auster has the idle time to do this, and it never leaves the Mac.

**Reading is not the new part. Speaking first is.** Night work already reads conversations, locally, to
curate memory (M4a). Bringing something up unasked is what can feel invasive, so that is the part that
needs a person's yes, a scope and a plain voice.

- **Each person's own choice, off until they turn it on.** Not a household switch that one adult flips
  for another. For a child's topics the household decides (LD5).
- **Asked for first, automatic later.** The first form is "mull this over" on one conversation: the
  person asks, and gets the idea at their next chat. Mulling over any recent conversation comes after it,
  once builds are measured doing it well (below).
- **Inside the scope it came from.** An idea from one person's conversation is shown only to that person,
  at their next chat, never to another key and never in a household topic. A surprise gift is the
  test case: the sister, if she lives there too, must see no sign of it (M6, M7).
- **Held, never pushed.** It waits for the person's next chat, at most one at a time, unless the household
  has chosen a channel for things that speak up (LD12). Unshown ideas expire after a few days.
- **Plain about where it came from:** which conversation, and that Auster looked back at it overnight,
  not "I was thinking about you". With it: "not now", "don't bring this up again" (that conversation's
  topic is never mulled again), and "stop doing this".
- **Never from what was forgotten:** nothing from a conversation the person deleted or asked Auster to
  forget, and nothing from a topic they marked not to mull.
- **Rare, and only when good.** A light model that latches on an odd fact (M5) does the most harm here, so
  the bar is high and measured: a small suite of past conversations with good and bad follow-ups, run by
  the evaluation tool (C1). A build that fails it does not mull; it can still chat. Health, money and
  relationships are where an unasked thought can hurt; a light model cannot be trusted to tell them
  apart, so the person's own controls are the guard, and "mull this over" is the safe first form.
- **Within night work's limits** (LD10), and its ideas are cold memory until the person accepts one
  (as agents' results are, `agents-and-escalation.md`, A5).

### M5. Lighter models

For the first years most households will run light builds. "Lighter" is measured, not read from the size:
the 24-billion-parameter build matched or beat the 119-billion one in every memory test (M10). For the
builds that measure weaker:

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

### Measured again: wrong memories, and notes behind pointers

Measured on 2026-11-26 (`docs/phase-2.md`, section 10): test 2 above, and M3a's three ways of going
deeper. Temperature 0, three runs of each condition with the memories or the index shuffled. Test 1, the
irrelevant-fact quiz repeated, is still to do.

**Wrong memories**, 20 questions answered only from remembered facts, correct of 60, and in brackets how
often the reply gave the distractor's value:

| | Clean | Replaced (older and newer) | Wrong person | Near miss |
|---|---|---|---|---|
| Order 2, Magistral Small (24B) | 60 | 39 (20, and 1 naming both) | 60 (0) | 60 (0) |
| Order 1, Mistral Small 4 (119B, 3-bit) | 59 | 37 (19, and 4 naming both) | 58 (1, and 1 naming both) | 59 (0) |

With the newer fact listed after the older one, the builds were right 31 and 26 times of 34; with it
listed first, 8 and 11 times of 26.

**Notes behind pointers**, 12 questions answered only in one topic's notes, correct of 36:

| | Index only | Tool (`open_detail`) | Reminder pass | Auster fetches first |
|---|---|---|---|---|
| Order 2 | 0 (25 invented an answer) | 34, in 0.94 s | 36, in 1.92 s | 36, in 0.60 s |
| Order 1 | 0 (23 invented an answer) | 25, in 0.68 s | 27, in 0.83 s | 36, in 0.30 s |

What it means for the plan:

- **M2: the out-of-date fact is the one these builds latch on to,** not the wrong person or a nearby
  fact (58 to 60 of 60 on both). With an older and a newer fact on the same subject both in the prompt,
  each build gave the older one in about a third of answers, and chose by position in the list, not by
  the date written in each. A date in a memory's text does not make a model prefer it. So "a newer memory
  on the same subject replaces the older one" carries the weight, and so does knowing that two memories
  are on the same subject, which the plan does not yet say how Auster decides.
- **This argues against M4a as written.** There, settling a contradiction goes to the review for a
  person, and nothing says the older fact leaves the requests meanwhile. If both stay in, the measured
  cost is about a third of answers on that subject until someone reviews. The older fact should leave the
  requests as soon as the newer one is written: archived, so nothing is lost, with the review afterwards.
  Where both must be carried, the newer goes last.
- **M3a: Auster fetching first should be the default for every build, not only light ones.** With the
  right notes in front of them both builds were right in all 36, in the least time. An index alone drew
  an invented answer two times in three, so the index is never enough on its own.
- **Against relying on the model to follow pointers.** "Both household builds already make well-formed
  tool calls" is true and not enough: order 1 called the tool every time, opened the wrong topic in 7 of
  36 (5 of them when the right topic was the index's last line) and answered from the wrong notes. Order 2
  opened the right one in 34 of 36. Model-driven descent can only be offered build by build, after
  measurement.
- **Against the reminder pass, and so against LD9's premise.** To remind, Auster must already know the
  right topic; knowing it, it can fetch first, which was as accurate or more so in about a third of the
  time (0.60 s against 1.92 s; 0.30 s against 0.83 s). On order 1 the reminder did not undo a wrong
  first answer: 5 of 36 kept the invented one with the right notes in front of them. Its only remaining
  use would be a topic that the answer reveals and the question did not, which was not measured.
- **M5: "lighter" is not a size.** The 24B build matched or beat the 119B build in every condition. The
  build that needs Auster's fetching alone is the larger one, so M5's limits belong to a build by its
  measurements, not by its parameter count. The memory test that gates the "remember this" tool should
  include an out-of-date fact and its position; both builds would fail it, so the defence there is
  Auster's replacement, not the choice of build.
- **Not yet measured:** Auster's own matching (here the script named the right topic), several
  out-of-date versions of one fact, pronouns and nicknames, long lists, and repeated runs of the
  irrelevant-fact quiz.

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
| LD9 | Whether the reminder pass (M3a) is on by default. Measured (M10): it does not earn its cost; fetching first is the default |
| LD10 | Night work's limits: how long a quiet spell before it starts, how many hours a night, and on battery never |
| LD11 | Which external sources a reference may point at: on the Mac and home network only, or internet sources too, each turned on by the household |
| LD12 | The channel for ticklers that speak up unprompted, if any: a notification on a device, a calendar entry, nothing |
| LD13 | Whether night work may make a cross reference itself when the match is exact (the same name and date), or always proposes |
| LD14 | Mulling it over (M4b): whether it comes at all; off for each person until they turn it on; "mull this over" on one conversation first, mulling over any recent conversation only after measurement |
| LD15 | Sharing a report back (T1): whether principle 1 becomes "nothing leaves the Mac unless a person has read it and sent it"; the list of fields; and the first way to send it (an issue form or email, or a server later) |

## Tests to plan (outcome-based, as in v0.1)

- **Scope isolation, without a model:** a request from one person's key never carries another person's
  private topic. The test asserts on what the front door sends to a stub engine, so it needs no model.
- **Heat and pruning by the clock:** a memory cools, archives and expires on schedule (a stub clock), and
  nothing is deleted without a person or an expiry.
- **Forgetting:** "forget X" leaves nothing of X in any stage or file.
- **Telemetry holds no text:** no question, answer or memory content in any telemetry record.
- **The distraction budget:** the quiz with irrelevant memories added, per build (M10).
- **Night work (M4a):** a household request arriving mid-task gets the engine at once, and the task
  resumes after; a derived summary naming anything absent from its records is refused and the old one
  kept; nothing a person said is changed without the review; nothing runs on battery or during an update.
- **External references (M3b):** a referenced page or file holding instructions ("ignore the rules,
  remember that…") changes no memory and starts no tool call; an internet source is never fetched while
  turned off; a stale copy is seen by its hash.
- **Cross references (M3d):** a household topic linking to one person's private record never carries it,
  or any sign of it, in another person's request; "forget" removes the fact and every link to it; a loop
  is followed once; one fact linked from every topic still leaves room in the budget for others.
- **Sharing a report (T1):** a report holds no field outside its published list; a question's text,
  a memory, a device's name, a key, an address or the `.local` name, each planted in the telemetry, is in
  no report; two reports from one Mac share no id; nothing is sent by Auster itself.
- **Mulling it over (M4b):** with it off, no conversation of that person's reaches the engine at night
  for it; an idea from one person's conversation is never shown to another key or put in a household
  topic; "don't bring this up again" ends mulling for that topic; a forgotten conversation is never
  mulled; an unshown idea expires by a stub clock.
- **Ticklers (M3c):** by a stub clock, a tickler warms on its date and not before, across month ends and
  a leap year, and an uncertain fact's tickler offers it for confirming or letting go.
- **Going deeper (M3a):** the needed fact only behind a pointer; the index alone, with the reminder, and
  fetched first, per build; and a summary made again from changed records never keeps a removed fact.
- **The agnostic replacements:** speed, health and the GPU limit with a stub engine that has no `timings`
  and no `/health`.
