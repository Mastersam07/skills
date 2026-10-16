# Your Next User Is an Agent: Shipping Skills With Your SDK

**Workshop workbook** · Follow along step by step. Every grey box can be copied and pasted.

In this workshop you'll take a small Dart package, **MoshoTopUp** (an SDK for buying airtime and data), watch an AI coding agent use it wrongly, then write a **skill** that teaches the agent to use it correctly, and ship that skill with the package using the Dart `skills` CLI.

By the end you will have:

- Seen the mistakes AI agents make with packages they don't know
- Written your first Agent Skill (`SKILL.md`)
- Installed it into a Flutter app with `dart run skills@ get`
- Watched the same agent get it right

---

## Before you start (do this at home if you can)

You need:

- **Flutter** installed, with Dart 3.13 or later
- **Git** 2.25 or later (check with `git --version`), or the starter zip
- **One AI coding agent**: Claude Code, Cursor, GitHub Copilot, Antigravity, Codex, Cline or OpenCode
- **The starter files** from the workshop repo

Check Flutter and Dart:

```bash
flutter --version
dart --version
```

Get **only the starter files**. These commands download the workbook and the `starter` folder, and skip the finished answer:

```bash
git clone --filter=blob:none --sparse <WORKSHOP_REPO_URL>
cd mosho-workshop
git sparse-checkout set starter
```

> No git? Download **`mosho-starter.zip`** from the repo's **Releases** page and unzip it. No internet at the venue? Copy `mosho-starter.zip` from a USB drive.

Warm up the `skills` CLI so it's downloaded before the workshop:

```bash
dart run skills@ --help
```

If that prints help text, you're ready. If it fails, update Flutter (`flutter upgrade`) and try again.

---

## The repo at a glance

```
mosho-workshop/
  starter/          ← you work here
    mosho_topup/    ← the package (SDK)
    sample_app/     ← a Flutter app that uses the package
  WORKBOOK.md       ← this file
```

The repo also has a `finished/` folder with the complete answer. You don't have it yet on purpose. Try the steps yourself first; [Getting the finished version](#getting-the-finished-version) shows how to get it when you need it.

---

## Part 1 · Meet MoshoTopUp (3 min)

MoshoTopUp lets an app buy data for a Nigerian phone number. Here is everything the package offers:

```dart
final topup = MoshoTopUp(apiKey: 'test_mosho_123');

final plans = await topup.plans(network: Network.mtn);

final result = await topup.buyData(
  phone: normalizeNigerianPhone('08031234567'),
  planId: plans.first.id,
  reference: newReference(),
);

switch (result) {
  case TopUpSuccess():
    print('Data delivered');
  case TopUpPending(:final reference):
    print('Still processing: $reference');
  case TopUpFailed(:final message):
    print('Failed: $message');
}

print(formatNaira(plans.first.amountInKobo));
```

The important rules of this package:

| Rule | Why it matters |
| --- | --- |
| Phone numbers must be in `+234` format. Use `normalizeNigerianPhone()`. | `08031234567` is rejected |
| Fetch plans with `plans()`. Never hardcode them. | Prices and plans change all the time |
| Amounts are in **kobo** (₦1 = 100 kobo). Show prices with `formatNaira()`. | Otherwise 1GB shows as ₦100,000 |
| `TopUpPending` is **not** a failure. Poll with `status(reference)`. | Telcos are often slow to confirm |
| Retrying after an error, or still pending? Reuse the **same reference**. | A new reference means a new charge, and the customer is debited twice |

The package runs on a fake backend, so nobody is charged. The last digit of the phone number decides what happens:

| Number ends in | Result |
| --- | --- |
| `0` | Pending first, then success after two `status()` checks |
| `9` | Failed, with no charge |
| anything else | Success |

Every charge is printed in your terminal. If the same number is charged twice for the same plan, you'll see a **WARNING** line.

You know these rules now, because you just read them. The AI agent hasn't read them.

---

## Part 2 · Watch the agent guess (7 min)

**1.** Open **only** the `starter/sample_app` folder in your editor and agent, not the whole repo.

**2.** Paste this prompt into your agent:

```text
Using the mosho_topup package, build a screen in this app where the user enters a phone number, picks an MTN data plan, and buys it. Show the user what happened.
```

**3.** Run the app with `flutter run` and try a number ending in `0`. Watch your terminal for `[mosho_topup]` lines.

**4.** Look at the code it wrote and tick what went wrong:

- [ ] Passed the phone number as typed (`080...`) instead of using `normalizeNigerianPhone()`
- [ ] Hardcoded the data plans instead of calling `plans()`
- [ ] Showed `amountInKobo` as naira (₦100,000 for 1GB) instead of using `formatNaira()`
- [ ] Treated `TopUpPending` as a failure, or didn't handle it at all
- [ ] Created a new reference when retrying (double debit!)

**5.** Undo the agent's changes so you start fresh.

If you cloned with git:

```bash
git restore .
git clean -fd
```

If you used a zip or USB, copy `starter/sample_app/lib` from the original download back over your changed one.

---

## Part 3 · Create your skill (3 min)

A **skill** is a folder with a `SKILL.md` file inside. It teaches an AI agent how to use something correctly. Dart packages ship skills in a `skills/` folder next to `lib/`.

**1.** Go into the package:

```bash
cd starter/mosho_topup
```

**2.** Create the skill:

```bash
dart run skills@ create
```

**3.** When it asks for a **name**, paste:

```text
mosho-topup-buy-data
```

> The name **must** start with the package name. `mosho_topup` becomes `mosho-topup-`. If it doesn't, the CLI silently skips your skill.

**4.** When it asks for a **description**, paste:

```text
Use when writing code that buys data or airtime with the mosho_topup package, including phone number handling, fetching plans, showing prices, and handling pending or failed top-ups.
```

> The description is how the agent decides **when** to use your skill. Be specific about the situations it covers.

**5.** Check that it was created:

```bash
ls skills/mosho-topup-buy-data
```

You should see `SKILL.md`.

---

## Part 4 · Write the skill (15 min)

Open `skills/mosho-topup-buy-data/SKILL.md`. Keep the part at the top between the `---` lines. Below it, add each section. Try writing them in your own words first; the boxes are there if you get stuck.

### 4.1 · What this package is

```markdown
# Buying data with mosho_topup

mosho_topup buys airtime and data for Nigerian phone numbers. Create one `MoshoTopUp` client and reuse it.
```

### 4.2 · The rules

Turn each mistake from Part 2 into a rule. Write them as clear instructions to the agent.

```markdown
## Rules

- Always pass phone numbers through `normalizeNigerianPhone()` before calling the SDK. Never pass raw user input like `08031234567`. It throws a `FormatException` for invalid numbers; show that to the user as a validation error.
- Always load plans with `topup.plans(network: ...)`. Never hardcode plan names, sizes, prices, or plan IDs.
- All amounts are in kobo. Display prices with `formatNaira(plan.amountInKobo)`. Never divide or format kobo yourself.
- `buyData` returns a sealed `TopUpResult`. Use an exhaustive `switch` on `TopUpSuccess`, `TopUpPending`, and `TopUpFailed`. Failures are results, not exceptions, so do not rely on try/catch for them.
- `TopUpPending` is not a failure. Tell the user it's processing and poll `topup.status(reference)` every few seconds, up to about 10 attempts.
- Create one reference per purchase with `newReference()`. If a call throws or the result is still pending, retry or check again with that same reference. Only create a new reference for a new purchase: after `TopUpFailed`, or when the phone number or plan changes. A new reference creates a new charge.
```

### 4.3 · A complete example

Agents learn best from one complete, correct example.

````markdown
## Example

```dart
import 'package:mosho_topup/mosho_topup.dart';

final topup = MoshoTopUp(apiKey: 'test_mosho_123');

Future<TopUpResult> buyPlan(String rawPhone, DataPlan plan) async {
  final phone = normalizeNigerianPhone(rawPhone);
  final reference = newReference();

  var result = await topup.buyData(
    phone: phone,
    planId: plan.id,
    reference: reference,
  );

  for (var attempt = 0; result is TopUpPending && attempt < 10; attempt++) {
    await Future.delayed(const Duration(seconds: 3));
    result = await topup.status(reference);
  }

  return result;
}

String describe(TopUpResult result) => switch (result) {
      TopUpSuccess() => 'Data delivered!',
      TopUpPending() => 'Still processing. We will keep checking.',
      TopUpFailed(:final message) => 'Failed: $message',
    };
```
````

### 4.4 · Mistakes to avoid

Listing wrong patterns helps the agent avoid them.

```markdown
## Do not

- Do not hardcode plans like "1GB for ₦1,000".
- Do not show `amountInKobo` directly as a naira price.
- Do not treat `TopUpPending` as an error.
- Do not call `newReference()` again when retrying after an error or a pending result.
```

Save the file. 🎉 You've written a skill.

---

## Part 5 · Install the skill into the app (3 min)

**1.** Go to the app:

```bash
cd ../sample_app
```

**2.** Install skills from the app's dependencies. Pick the line for your agent:

| Agent | Command |
| --- | --- |
| Claude Code | `dart run skills@ get --all --agent claude` |
| Cursor | `dart run skills@ get --all --agent cursor` |
| GitHub Copilot | `dart run skills@ get --all --agent copilot` |
| Antigravity | `dart run skills@ get --all --agent antigravity` |
| Codex | `dart run skills@ get --all --agent codex` |
| Cline | `dart run skills@ get --all --agent cline` |
| OpenCode | `dart run skills@ get --all --agent opencode` |

> The CLI finds `mosho_topup` in the app's dependencies, finds its `skills/` folder, and copies your skill to where your agent looks for skills.

**3.** Confirm it's installed:

```bash
dart run skills@ list
```

You should see `mosho-topup-buy-data`.

---

## Part 6 · Run the agent again (5 min)

**1.** Start a **new** agent chat or session, so it picks up the new skill.

**2.** Paste the **same** prompt as before:

```text
Using the mosho_topup package, build a screen in this app where the user enters a phone number, picks an MTN data plan, and buys it. Show the user what happened.
```

**3.** Tick the checklist again:

- [ ] Uses `normalizeNigerianPhone()`
- [ ] Loads plans with `plans()`
- [ ] Shows prices with `formatNaira()`
- [ ] Handles `TopUpPending` and polls `status()`
- [ ] Reuses the same reference on retry (no WARNING in the terminal)

**4.** Get the finished version (see [Getting the finished version](#getting-the-finished-version)) and compare your agent's code with `finished/sample_app/lib`.

> Still seeing mistakes? Find the rule the agent ignored and make it clearer or more direct in `SKILL.md`. Then run `dart run skills@ get --all --agent <your-agent>` again and start a new session. This loop of write, test and tighten is how real skills get good.

---

## Part 7 · Ship it (3 min)

When you publish a package, the `skills/` folder is included automatically. Every app that depends on your package can install your skill with one command.

**1.** Make sure `skills/` isn't excluded. If your package has a `.pubignore` file, it must **not** list `skills/`.

**2.** See what would be published, without publishing:

```bash
cd ../mosho_topup
dart pub publish --dry-run
```

Look for `skills/mosho-topup-buy-data/SKILL.md` in the file list.

**3.** In your app projects, add this to `.gitignore` unless you commit your agent folders:

```text
.config/dart_skills
```

**The golden rule:** when your package's API changes, update the skill in the same release.

---

## Getting the finished version

Use this to compare your work in Part 6, or to catch up if you fall behind.

If you cloned with git, from inside `mosho-workshop`:

```bash
git sparse-checkout add finished
```

A `finished` folder appears next to `starter`, with the completed skill in `finished/mosho_topup/skills` and the reference screen in `finished/sample_app/lib`.

No git? Download **`mosho-finished.zip`** from the repo's **Releases** page and unzip it next to your `starter` folder.

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `dart run skills@` doesn't work | Update Flutter with `flutter upgrade` |
| Skill doesn't show in `skills list` | Check the folder name starts with `mosho-topup-` and contains `SKILL.md` |
| Copilot doesn't get the skill | Copilot isn't auto-detected. Always pass `--agent copilot` |
| Agent ignores the skill | Start a new session. Mention "mosho_topup" in your prompt. Make the description more specific |
| Totally lost | [Get the finished version](#getting-the-finished-version), copy `finished/mosho_topup/skills` into `starter/mosho_topup/`, and continue from Part 5 |

---

## Bonus challenges

1. **Add a second skill**, `mosho-topup-airtime`, for buying airtime. Keep each skill focused on one job.
2. **Add a `references/` folder** inside your skill with a file listing every `TopUpFailed` message and what the app should show the user.
3. **Ship a skill for a package you use.** Many packages don't ship skills yet. The `skills` CLI also reads community registries such as `flutter/skills`, which is a great first open-source contribution.

---

## Remember

> Your docs are for humans. Your skill is for the agent writing code for them.

Useful links:

- Dart `skills` CLI: https://pub.dev/packages/skills
- Package skills guide: https://docs.flutter.dev/ai/package-skills
- Agent Skills spec: https://agentskills.io/specification
