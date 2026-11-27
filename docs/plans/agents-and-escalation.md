# Auster's agents, and the link to a data center

**Status: planning, for discussion (2026-11-26).** Not checked, not phased, and nothing is built from it.
It stands on [`local-layer.md`](local-layer.md): Auster's own server in the request path (the front door),
people's keys and scopes, memory's topics, budgets, and night work. Its open decisions are AE1 to AE9.

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

### E4. Curation of providers

The list of providers is curated like models (`local-layer.md`, C2): what qualifies (no training on the
data, a stated retention, an OpenAI-style API), how often it is reviewed, and when one is removed. A
household can add its own endpoint, marked as not curated.

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
