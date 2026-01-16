# Langley Silver & the Antediluvian Translator (Perl)

A short terminal-based interactive fiction / roguelike-adjacent game.
You play a cabin boy on a pirate ship that’s recently hauled up antediluvian artifacts.
The ship’s cook, **Langley Silver**, secretly gives you a strange relic — an **antediluvian translator** —
and warns you: *the ship itself is listening*.

The key mechanic: the game tries to understand **messy, human-ish commands**.  
In the fiction, the translator interprets intent. In the code, **Perl’s regex** does.

## Why Perl?

Perl is historically one of Unix’s most influential scripting languages for **text processing**.
This project uses Perl intentionally as a “language of interpretation”:

- Commands don’t need perfect syntax — the parser searches for intent.
- Regex is the translator layer.
- The code emphasizes readable Perl (no code golf), using core data structures (scalars/arrays/hashes).

## Run

```bash
chmod +x ship.pl
./ship.pl