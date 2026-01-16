# Langley Silver & the Antediluvian Translator (Perl)

A short terminal-based interactive fiction / roguelike-adjacent game.

You play a cabin boy on a pirate ship that’s recently hauled up antediluvian artifacts.
The ship’s cook, **Langley Silver**, secretly gives you a strange relic — an **antediluvian translator** —
and warns you: *the ship itself is listening*.

The central mechanic is interpretation.  
The game attempts to understand **messy, human-ish commands** rather than requiring strict syntax.

In the fiction, the translator interprets intent.  
In the code, **Perl’s regular expressions do**.

---

## Why Perl?

Perl is historically one of Unix’s most influential scripting languages for **text processing and interpretation**.
This project uses Perl deliberately as a “language of understanding,” not just execution.

- Commands do not need perfect syntax; the parser searches for intent.
- Regular expressions act as the translator layer between human input and system behavior.
- The code emphasizes clarity and readability over cleverness, using core Perl features:
  scalars, arrays, hashes, and explicit control flow under `strict` and `warnings`.

In this project, Perl acts less like a rigid rules engine and more like a **translator**
between human intention and machine response.

---

## Run

```bash
chmod +x ship.pl
./ship.pl

Project Status

This project is being built incrementally in small, readable stages.
Each commit introduces a distinct conceptual layer rather than a pile of features.

Current Stage: 3 — Interpreter Online

At this stage, the game world exists and player input is no longer treated as strict commands.
Instead, input is interpreted through a regex-driven “translator” layer that attempts to infer intent.

What’s implemented:

World model using Perl hashes and arrays (rooms, items, NPCs)

Intro scene with Langley Silver and the Antediluvian Translator

Room rendering (name, description, exits, visible items)

Regex-based command interpretation mapping human-like input to structured intent

Clear separation between parsing (what the player means) and execution (what the game does)

Example inputs that are successfully interpreted:

look

look at the chest

go fore

take the rag

use key on chest

At this stage, most commands are parsed and reported but not yet executed.
This is intentional: interpretation comes before mechanics.

What’s Next

Stage 4 will wire interpreted commands to actual gameplay:

Movement between rooms

Looking at items and environmental objects

Inventory management

Simple encounters and world state changes

The interpreter layer will remain unchanged; only execution logic will be added.