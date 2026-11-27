# Auster's agents, and the link to a data center

**Status: planning, for discussion (2026-11-26).** Not checked, not phased, and nothing is built from it.
It stands on [`local-layer.md`](local-layer.md): Auster's own server in the request path (the front door),
people's keys and scopes, memory's topics, budgets, and night work. Its open decisions are AE1 to AE11.

## What the owner asked about

Auster's own agents (how they are used and organised, their budget, where their results are kept), and
the link to a data center (how easy it is to use, and how it is paid for).

## Principles, carried over

1. **Nothing leaves the Mac without a person's yes.** The data-center link is the one place the household
   can choose to send something out, so it is explicit, visible, and off until turned on.
2. **An agent acts as the person who started it,** with that person's scope and no more.
3. **Auster holds the plan, not the model.** Light models lose the thread of a long task, as they forget
   to follow pointers (`local-layer.md`, M3a). So Auster keeps the task's state and asks the model for one
   step at a time, with the reminder built in.
4. **Every run has a budget it cannot exceed,** in time, tokens, steps, energy and, where the data center
   is used, money.
5. **Results are memory,** with their sources, kept in the owner's topics and reviewed like any other.

## A. Auster's agents

### A1. What one is

A task that takes more than one answer: gather what the household knows about the summer trip and draft
a plan; compare two appliances from their manuals; tidy a topic's notes overnight. It has a goal, an
owner, a scope, the tools it may use, a budget, and a record of its steps.

### A2. Use

- **Started by a person,** in the chat, or as standing work the household sets up (night work's curation
  is the first standing agent, `local-layer.md`, M4a).
- **Tools are Auster's,** each checked against the owner's scope when used: read memory and open
  details, read a local source (a file, a calendar), write a draft into the owner's topic. Internet
  sources only where the household has turned them on (`local-layer.md`, LD11).
- **Never acting outward on its own.** An agent may draft a message, a booking or a purchase; only a
  person sends, books or buys. No tool exists for any of those in v1.
- **Never steered by what it reads.** Text from a tool's result is quoted material, as for external
  references (`local-layer.md`, M3b): it cannot start a tool call by itself or change the agent's goal.

### A3. Organisation

- **One queue on the Mac.** Interactive chat always comes first. Agents run in one engine slot at most,
  and stop the moment a household request arrives, resuming from their saved state (as night work does).
- **Auster drives the loop.** Each step: Auster gives the model the goal, a short summary of what has
  been done, the relevant memory within the budget, and the tools it may use; it checks the model's tool
  call against the tool's form and the owner's scope, runs it, and records the result. The model never
  holds the whole task in its context.
- **A stop rule.** No progress in a few steps (the same call again, no new information), or the budget
  spent, ends the run with a report of how far it got. Light builds get fewer steps, set by measurement.
- **Which builds may run agents** is measured, like everything else: a small suite of agent tasks, run by
  the evaluation tool (`local-layer.md`, C1). A build that fails it can still chat, but runs no agents.

### A4. Budget

Each run has hard limits, and each person a daily allowance, set by the household:

- **time** (wall clock) and **steps;**
- **tokens** read and written;
- **energy:** GPU time, counted against night work's limit (`local-layer.md`, LD10);
- **money,** only when a step goes to the data center (E3).

A run that reaches a limit stops and reports; it never borrows from tomorrow.

### A5. Where results are kept

- **In the owner's topic,** as a detail with a pointer in the index, marked as made by an agent, with its
  sources (which memories, which documents, which steps). Cold until a person opens or accepts it, so an
  agent's mistake does not become something the household "remembers".
- **The step record** (what was asked, which tools ran, what came back) is kept with the result for the
  owner to read, in the owner's scope, and pruned like any memory.
- **Scratch work is discarded** when the run ends.
- Telemetry counts runs, steps and tokens, never their content (`local-layer.md`, T).

## E. The link to a data center

### E1. What it is

Sending a question, or one step of an agent, to a larger model run by a provider, through the same
OpenAI-style API. The concept places it as an optional hook in phase 6. Auster runs no data center of its
own and relays nothing: the household's Mac talks to the provider the household chose.

### E2. Ease of use

- **One setting.** Choose a provider from a short curated list (each with its privacy terms, how long it
  keeps requests, where it runs, and its prices, all dated), paste the provider's key once. The key is
  kept in macOS's own Keychain (`security`, which ships with macOS), never in a plain file.
- **Asked for, not automatic.** A person sends a question onward ("ask the bigger model"), or the
  household sets a rule for a topic. Escalating by itself when the local model seems unsure would send
  data without anyone choosing it, so it is off unless the household turns it on (AE5).
- **What is sent is shown first:** the question, and exactly which memories go with it. Private topics are
  never sent unless their owner says so, for that request. Memory goes as little as the question needs.
- **Seen afterwards:** each escalation is listed for its owner, with what was sent and what it cost.

### E3. Billing

- **The household pays the provider directly,** with its own key. Auster never handles money and is never
  a middleman, which also keeps principle 1: no account with Auster, nothing about the household sent to
  the project.
- **Auster keeps a local count:** tokens sent and received, multiplied by the provider's published prices
  from the curated list, as an estimate, shown per person and per month. The provider's own bill is the
  truth; Auster says so.
- **Caps, enforced on the Mac:** a monthly limit for the household and for each person, with a warning
  before it is reached. Once reached, escalation stops until the next month or until a person raises it.
- **Agents and money:** a step an agent sends to the data center counts against the run's money limit and
  its owner's allowance (A4).

### E3a. A share for the project, at the household's price

The owner asked (2026-11-26) whether the project could take a tiny share of what households spend with
providers, while they pay the same price as going direct. **Only one shape keeps the principles:** the
household signs up with the provider and pays it directly, at the provider's own price, through an Auster
referral link, and the provider pays the project a share. Auster never holds the money or sees a request.
A clearing house, where Auster buys access and resells it, would mean taking payments, keeping accounts
for households, and billing data about them reaching the project; and provider terms often forbid
reselling without a partner agreement. So it is out.

The referral shape would hold to four rules: the same terms for every curated provider, or none, so that
money never chooses the list (E4); never a reason to send more out, so escalation stays off by default
and never automatic for revenue (AE5); disclosed where the household picks a provider; and only totals,
never anything about a household, from the provider to the project. Receiving money also needs a legal
entity, which ties the project to a named person.

**Looked for on 2026-11-26.** Among the large providers, none publishes a program that pays a share of
API spending by people it refers:
- Anthropic's [referral partner program](https://www.anthropic.com/legal/referral-partner-program-terms)
  pays a fee on an enterprise contract's first order only, not on renewals or usage.
- For OpenAI, only secondhand reports, all saying there is no public API affiliate program.
- Google's Gemini API documents [partner integrations](https://ai.google.dev/gemini-api/docs/partner-integration)
  as a technical matter, with no payment.
- Mistral's [partner-served terms](https://legal.mistral.ai/terms/partner-served-deployment-terms) are for
  resellers, who do the billing themselves: the clearing-house shape.
- OpenRouter, an aggregator, passes providers' list prices through and charges a fee on credit purchases
  ([its fee](https://openrouter.ai/blog/simplifying-our-platform-fee)). It pays apps nothing, but credits
  them in public rankings ([app attribution](https://openrouter.ai/docs/app-attribution)). As a provider
  on the curated list it would be one more party that sees requests, judged like any other (E4).

**One European provider does** (found by the owner, read the same day). Infomaniak's
[affiliate programme](https://www.infomaniak.com/en/membership) covers its
[AI Services](https://www.infomaniak.com/en/hosting/ai-tools): open models through an OpenAI-compatible
API, run in its data centers in Switzerland, which it says neither records queries nor uses them for
training. Its [terms](https://faq.infomaniak.com/2247):
- 25% of every order and renewal by a new customer, for one year after the account is made, rising to
  30%, 35% and 50% as the affiliate's total earnings pass CHF 50, 1,000 and 20,000;
- only for a new account made after clicking the link (a tag on any page's address, kept 30 days), not
  for an existing customer, and not after a refund in the first 30 days;
- paid each month once CHF or EUR 50 is owed; open to anyone;
- the affiliate sees only order numbers and commissions, nothing about the customer.

The link leads to the ordinary sales page, so a referred household seems to pay what anyone pays; the
terms do not say so outright. Against the four rules: the last is met as Infomaniak runs it, and the
second and third are Auster's to keep. The first is not: no other provider offers anything, so "the same
terms for every curated provider, or none" means none. A looser form would keep its purpose: the list is
chosen and ordered by its criteria alone, settled before any referral is looked at, and a listed
provider's link is used where it has one, with the list saying which. The share lasts a year for each
household, so it is support while Auster is growing, not a lasting income.

Infomaniak is worth judging for the curated list on its own terms (E4), money aside. Its list of models
and its prices were not read (those pages need a browser's scripts). Until the owner decides AE10, E3
stands as written: the household pays the provider directly and the project takes nothing.

### E4. Curation of providers

The list of providers is curated like models (`local-layer.md`, C2): what qualifies (no training on the
data, a stated retention, an OpenAI-style API), how often it is reviewed, and when one is removed. A
household can add its own endpoint, marked as not curated.

**Where a provider is, and who bills, are shown for each** (the owner, 2026-11-27). Many households in
the US would rather pay a US company: a card issuer may flag a payment to a merchant abroad, or charge a
fee on it, and some prefer US law. Others choose a provider abroad for its privacy law. So the list gives,
for each provider, the company that bills and its country, the currency, and where the requests are
answered, and a household can narrow the list by them. The list should hold at least one provider that
bills in US dollars from a US company and meets the criteria, so that a US household has a choice at home
without Auster in the middle. Which providers meet the criteria is to be read from their terms, not
assumed.

### E5. A central service, if there is ever one

The owner, thinking aloud (2026-11-27): hybrid models exist, where a central party carries messages and
collects anonymous figures to make things better without harming privacy, and **transparency is the
key,** for figures shared back and for a way through to data centers alike. No firm view either way.

**The test any central part must pass: Auster works without it.** If the central service vanished
tomorrow, every household's Mac would go on exactly as before, less the extras it chose. A central part
that passes this, is off until a person turns it on, and shows what it sends is a help, not a dependency.

**Two roles, not equally hard:**
- **A collector of figures** (`local-layer.md`, T1) can be built so that the centre learns little: a
  published list of fields, the exact bytes shown on the Mac first, the collector's code and the totals
  published, a relay that hides the sender's address from the collector (Oblivious HTTP, RFC 9458), and
  perhaps aggregation in which no one server sees one household's figures (the IETF's Distributed
  Aggregation Protocol; its state to be checked before relying on it). Low risk, and worth much: every
  figure in the registry was measured on one Mac.
- **A way through to data centers** (one account, one bill, switching providers, and traffic pooled so
  that a provider cannot tell which household asked) necessarily sees every request, since the provider
  must read it. "No logs" cannot be proven from outside. It also brings back what E3a found: money, a
  provider's terms on reselling, a legal entity, a service to keep up. **Where it is decides who can
  reach it:** some US households would pay a US go-between gladly (E4), and a US go-between is within
  reach of US legal process for whatever it holds, as a Swiss one is of Swiss law. Holding nothing is
  what limits that, whichever the country. A list that shows each provider's country and billing (E4)
  meets most of the wish without a go-between.

**Proton, which the owner names among the concept's inspirations (read 2026-11-27):**
- **Lumo**, its AI assistant, is the nearest example of a central AI service built for privacy. Proton
  [says](https://proton.me/support/lumo-privacy) it runs open-weight models on servers it controls in
  Europe, keeps no logs and no metadata (times, addresses), encrypts saved chats so that only the
  person's device can read them, and erases guest chats at the end of a session; requests travel by TLS,
  so the server reads them while it answers, as any relay would. One exception to "never used for
  training": feedback on Apertus, anonymised and only with explicit consent, goes to the university teams
  behind that model. Lumo's app code is published; its server code is not, and no independent audit of
  it was found. A [forum thread](https://discuss.privacyguides.net/t/proton-markets-lumo-as-open-source-but-support-calls-it-a-long-term-intention-not-the-instantaneous-state/30004?page=2)
  quotes Proton's support calling Lumo's open source "a long-term intention, not the instantaneous state".
- **Its own figures** are [on by default](https://proton.me/support/share-usage-statistics) in most of
  its apps, said to be anonymous and deleted after 30 days, with one switch in the account to turn them
  off.
- **How it earns trust:** published app code, independent audits with [published
  reports](https://proton.me/blog/security-audit), a [transparency
  report](https://proton.me/blog/transparency-report) counting the legal orders it receives, complies
  with and contests each year, Swiss law, and since 2024 a [non-profit
  foundation](https://proton.me/foundation) as majority owner, without whose consent the company cannot
  change hands.
- **How trust is spent:** in 2026 an internal memo on staff use of AI drew a backlash from its users;
  Proton [apologised](https://cybernews.com/ai-news/proton-apology-ai/) and promised to publish more of
  its code, including how it was made.

**What Auster would take from it:** published code for anything central; independent audits with their
reports published; a yearly transparency report; a structure that cannot be sold out from under the
households; and claims that never run ahead of what can be checked. **What it would not take:** figures
shared by default. Auster's are off until a person sends a report (T1), and a test proves nothing is
sent while they are off.

**A simpler path for the second role:** Proton's Lumo and Infomaniak's AI Services (E3a) are already
central services of this kind, run by companies whose business is privacy, in Switzerland or the EU, on
open-weight models. Auster may not need to be the way through at all: it can curate such providers (E4)
and let the household choose one, among those a Mac can call. Infomaniak's API is OpenAI-compatible.
Lumo has no published API (checked 2026-11-27): only unofficial clients that speak its web app's own
protocol, such as [lumo-tamer](https://github.com/ZeroTricks/lumo-tamer), which can break without
notice and are not a way for Auster to send a household's requests. Lumo could join the list only if
Proton publishes an API.

## Decisions for the owner

| | Question |
|---|---|
| AE1 | Which agent tasks come first, and whether any run without being asked (beyond night work) |
| AE2 | The tools of v1: memory and local sources only, or internet sources too where turned on |
| AE3 | Default budgets: per run and per person per day, in time, steps, tokens and energy |
| AE4 | Whether agents' results are cold until accepted, or warm when the owner started the run |
| AE5 | Whether automatic escalation ever exists, and if so with what limits |
| AE6 | The first providers on the curated list, and the criteria |
| AE7 | Monthly money caps: their defaults, and whether each person has one |
| AE8 | Whether a household can add its own endpoint, and how it is marked |
| AE9 | When the data-center link comes: with the front door, or in phase 6 as the concept says |
| AE10 | Whether to use a provider's referral link where one exists (E3a: Infomaniak's covers its AI Services; the large providers offer none), and whether the first rule loosens to "the list is chosen by its criteria alone, before any referral is looked at" |
| AE11 | Whether Auster ever runs a central service (E5), and which role first: a collector of figures, a way through to data centers, or neither while privacy-minded providers fill the second; the test either must pass is that Auster works without it |

## Tests to plan

- **Scope:** an agent started by one person never reads, writes or sends another person's private topic,
  checked at the front door against a stub engine.
- **Interactive first:** a household request arriving during an agent's step gets the engine at once; the
  agent resumes from its saved state and finishes the same.
- **Stop rule:** a stub model that repeats the same tool call is stopped within the step limit, with a
  report.
- **Never steered:** a tool result holding instructions starts no tool call and changes no goal.
- **Nothing outward:** no tool sends, books or buys; a draft is only a draft.
- **Escalation:** nothing goes to a provider while the link is off; with it on, the request carries only
  what was shown; a private topic is never in it without its owner's yes; the key never appears in a file,
  a log or a command line; the cap stops escalation at the limit.
