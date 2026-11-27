# Concept: central services, a relay to data centers, and figures shared back

> **Status: parked, unscheduled.** Collected 2026-11-27 from the owner thinking aloud, for later
> discussion. Not part of any plan and not phased: the plans in `docs/plans/` are built without it.
> If it is taken up, it becomes a phase stub in `SPEC.md` and a plan of its own, checked before anything
> is built. The nearest plans it would touch are `docs/plans/agents-and-escalation.md` (E, the link to a
> data center) and `docs/plans/local-layer.md` (T1, sharing a report back).

## 1. The idea

Auster's principles are no dependency and nothing leaving the Mac without a person's yes. The owner's
point: hybrid models exist, where a central party carries messages and collects anonymous figures to
make things better without harming privacy, and **transparency is the key,** for figures shared back
and for a way through to data centers alike. No firm view either way.

**The test any central part must pass: Auster works without it.** If the central service vanished
tomorrow, every household's Mac would go on exactly as before, less the extras it chose. A central part
that passes this, is off until a person turns it on, and shows what it sends is a help, not a dependency.

## 2. Two roles

- **A collector of figures** (`docs/plans/local-layer.md`, T1) can be built so that the centre learns little: a
  published list of fields, the exact bytes shown on the Mac first, the collector's code and the totals
  published, a relay that hides the sender's address from the collector (Oblivious HTTP, RFC 9458), and
  perhaps aggregation in which no one server sees one household's figures (the IETF's Distributed
  Aggregation Protocol; its state to be checked before relying on it). Low risk, and worth much: every
  figure in the registry was measured on one Mac.
- **A way through to data centers** (one account, one bill, switching providers, and traffic pooled so
  that a provider cannot tell which household asked) necessarily sees every request, since the provider
  must read it. "No logs" cannot be proven from outside. It also brings back what the agents plan's E3a found: money, a
  provider's terms on reselling, a legal entity, a service to keep up. **Where it is decides who can
  reach it:** some US households would pay a US go-between gladly (the agents plan, E4), and a US go-between is within
  reach of US legal process for whatever it holds, as a Swiss one is of Swiss law. Holding nothing is
  what limits that, whichever the country. A list that shows each provider's country and billing (the agents plan, E4)
  meets most of the wish without a go-between.

## 3. The pooled relay that keeps nothing

The owner's shape for the second role (2026-11-27), on the model of a VPN: what leaves a VPN is not
anonymous in itself, but it is mixed with many people's, and the VPN keeps nothing, so no one can tie it
back. Here: **many households' requests go out under one provider account and from shared addresses, and
the relay keeps no record of who sent what.** The provider sees questions and cannot tell which household
asked, even if it wanted to; the relay could tell only in the moment, and afterwards has nothing to look
up.

How it differs from a VPN, and what each difference asks for:

1. **The relay reads each request as it passes.** A VPN carries traffic encrypted end to end to the site,
   so it sees only ciphertext. The relay must sign each request with the pooled account's key, which sits
   inside the encryption, so it must open the request. "Keeps nothing" is then the whole protection, and
   it has to be shown rather than promised: the relay's code published, servers that write nothing to
   disk, independent audits; and, stronger and available today, the relay run in attested confidential
   hardware, so that the household's Mac checks which code runs before it sends anything.
2. **What a person asks can still identify them.** Pooling hides the address and the account, not the
   words. Auster helps by sending as little memory as a question needs and no private topic without its
   owner's yes (the agents plan, E2), but it cannot make a question anonymous.
3. **The pool must be large.** One household among ten is little cover. Like a VPN, it works at scale.
4. **Paying must not link back.** Paid by card, the relay knows who paid. Anonymous payment tokens
   (Privacy Pass, RFC 9576 to 9578) keep who paid apart from what was sent, and could be sold by a US
   company in dollars (section 5).
5. **A provider can still link the requests of one conversation,** since each carries the conversation so
   far; it cannot link them to a household.
6. **A provider's terms must allow it.** One account serving many households is close to reselling, which
   some providers forbid without a partner agreement. To be read provider by provider.

So it is a real product shape: a no-retention, pooled relay, ideally in attested hardware, that a US
company could bill in dollars. It is also a business of its own (an entity, a service kept up, terms),
which is why it belongs with "optional, and Auster works without it".

## 4. Ways to carry a request, from simplest

1. **A plain relay, like a VPN.** The household keeps its own provider account; the relay passes TLS
   through unread. The provider no longer sees the home's address, but knows the household from its
   account and key. Easy, and buys little.
2. **A split relay: Oblivious HTTP (RFC 9458).** The relay sees who but not what; a gateway at the
   provider sees what but not who. Apple's Private Cloud Compute is understood to use this, with third
   parties running the relay. It needs the provider to run the gateway; which AI providers do is not known.
3. **Anonymous payment tokens** (Privacy Pass), with 2 or with the pooled relay of section 3: the issuer
   knows who paid, the one that takes the tokens knows what was asked.
4. **Confidential inference.** The model itself runs in attested hardware, so even the provider cannot
   read requests: the only way to remove "someone reads it". Emerging; which providers offer it is not
   checked.

Without a provider's help, a channel either hides only the address (1) or must read requests to use a
pooled account (section 3). With its help (2 to 4) it can be blind; the standards exist.

## 5. Where it is, and who bills

Many US households would rather pay a US company: a card issuer may flag a payment to a merchant abroad,
or charge a fee on it, and some prefer US law; others choose a provider abroad for its privacy law. The
agents plan's E4 already shows each curated provider's billing company, country, currency and where
requests are answered. A US go-between would be within reach of US legal process for whatever it holds,
as a Swiss one is of Swiss law; holding nothing is what limits that, whichever the country.

## 6. Proton, as an example

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

**A simpler path for the second role:** Proton's Lumo and Infomaniak's AI Services (`docs/plans/agents-and-escalation.md`, E3a) are already
central services of this kind, run by companies whose business is privacy, in Switzerland or the EU, on
open-weight models. Auster may not need to be the way through at all: it can curate such providers (the agents plan, E4)
and let the household choose one, among those a Mac can call. Infomaniak's API is OpenAI-compatible.
Lumo has no published API (checked 2026-11-27): only unofficial clients that speak its web app's own
protocol, such as [lumo-tamer](https://github.com/ZeroTricks/lumo-tamer), which can break without
notice and are not a way for Auster to send a household's requests. Lumo could join the list only if
Proton publishes an API.

## 7. Open questions

- Whether Auster ever runs a central service, and which role first: a collector of figures, a way
  through to data centers, or neither while privacy-minded providers fill the second.
- Which providers' terms allow one account to serve many households; which run an Oblivious HTTP
  gateway; which offer confidential inference.
- How large a pool has to be before it is cover, and how a household would know the pool's size.
- Who would run it, under which law, as what kind of entity, and paid for how (tokens, a subscription).
- How the relay's "keeps nothing" is shown: published code, audits, a yearly transparency report, and
  attestation that the household's Mac checks.
