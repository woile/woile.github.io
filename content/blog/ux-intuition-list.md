+++
title = "Flawed UX Intuition List"
description = "An irritating collection of common app frictions that signal a deeper disconnect between data architecture and user needs."
date = 2026-04-03
tags = ["ux", "engineering", "product"]
+++

Systems surround our daily life, from a checkout at a cafe, to a doctor's appointment.
We all have felt that friction, the moments where a system stops serving us and starts demanding we serve it instead.

As engineers, we often spend our time discussing what to build (the requirements) and our nights arguing about how to build it (the tech stack).
But we rarely talk about the intuition that connects them: how the system actually feels to a human being.

## Data Architecture is User Experience

At the root of most "bad UX" isn't just a misplaced button; it's often a **failure in data architecture**.

Data architecture is the blueprint for how information is structured, stored, and retrieved.
When this blueprint is designed in a vacuum, without considering the human workflow, **we get friction**.

If your database knows my address but your checkout form asks for it again, that's not just a UI redundancy;
it's a failure of the system to utilize its own internal knowledge to help the user.

**A great system respects the user's time**. It treats data as a shared memory between the machine and the human.
When that memory fails, friction occurs.

## The "Intuition List"

Here is a collection of common digital frictions that signal a deeper disconnect in a product's design:

### 1. Data Amnesia

Being asked for your billing address during checkout when it's already in your shipping profile,
or re-entering your name on a support ticket when you're already logged in.

> Recently, at the doctor, my girlfriend was asked the same information at the reception, then by the nurse, and finally by the doctor.
> Which inspired me to write this post

### 2. Reset on back

You spend several minutes carefully filling out a multi-step form, reach the final "Review" page, and notice a small typo.
When you click "Back" to fix it, you find that the application has wiped the entire previous step, forcing you to re-enter everything from scratch.

### 3. Wild hunt

Primary actions (like "Export," "Download," or "Delete") that are buried three levels deep.
If it's a core part of the workflow, it should be visible.
When building a User Interface, consider the usually ignored axis "**task frequency**", not just "logical" grouping.
Learn your user's workflows!

> Thought: maybe as the industry, we could come up with some type of benchmark to measure core workflows

### 4. JS bloat

You open a table, expand sections, then you navigate to a different page, and when you hit the "Back" button, you have to do the whole exploration again.
If you cannot guarantee good behavior, just show everything, this way, when the user goes back, they just end up in the position they were.

### 5. "Action in Progress" Void

When a user triggers a long-running process, like uploading a file, generating a report, or deploying a stack; and the interface remains static.
Without a progress bar or step-by-step feedback, the user is left wondering if the app has crashed or if they should try again (which often makes things worse).
Which can be easily fixed with a meaningful progress indicator that communicates active state.

## Why This Matters

Spotting these issues isn't about being "picky", it's about **empathy**.
Every extra click, every redundant field, and every lost scroll position is a tiny withdrawal from the user's "trust bank.".

This can be easily extrapolated, not only to backends or CLI's, but also to any aspect of life, that's my belief.
A road with no signs, a street so wide it encourages speeding, or a kitchen without plugs.

As engineers, our job isn't just to make the code run; it's to make the friction disappear.
