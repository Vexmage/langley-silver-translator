#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

# Langley Silver & the Antediluvian Translator
# Commit 2: world data structures + room rendering.
# The command parser and gameplay actions arrive in later commits.

# -----------------------------
# Player state (scalars/arrays)
# -----------------------------
my $name     = '';
my $health   = 10;
my $score    = 0;
my $turn     = 0;
my $location = 'galley';

my @inventory     = ();   # item ids
my @visited_rooms = ();   # room ids
my @encounters    = ();   # strings like "rat_swarm:survived"

# -----------------------------
# World state (hashes/arrays)
# -----------------------------
my %ITEMS = (
  translator => {
    name     => 'Antediluvian Translator',
    desc     => 'A palm-sized brass ovoid etched with impossible script. It hums when you speak.',
    takeable => 0,
    tags     => [qw(relic tool language)],
  },
  rum_rag => {
    name     => 'Rum Rag',
    desc     => 'A rag soaked in cheap rum. Flammable. Also… medicinal, if you’re desperate.',
    takeable => 1,
    tags     => [qw(flammable cloth)],
  },
  bone_key => {
    name     => 'Bone Key',
    desc     => 'A key carved from something that was never meant to be a key.',
    takeable => 1,
    tags     => [qw(key strange)],
  },
  black_log => {
    name     => 'Black Log',
    desc     => 'A logbook page. The ink crawls if you stare. The translator might help.',
    takeable => 1,
    tags     => [qw(text clue)],
  },
);

my %ROOMS = (
  galley => {
    name  => "Galley",
    desc  => "The cook’s domain. Langley Silver sits like a king among pots and secrets.",
    exits => { up => 'deck' },
    items => [], # translator is implicit; Langley gives it during intro
    flags => { visited => 0 },
  },
  deck => {
    name  => "Main Deck",
    desc  => "Salt air, creaking boards, and sailors pretending not to be afraid of the haul.",
    exits => { down => 'galley', fore => 'forecastle', aft => 'captains_cabin', hatch => 'hold' },
    items => ['rum_rag'],
    flags => { visited => 0 },
  },
  forecastle => {
    name  => "Forecastle",
    desc  => "Coils of rope and a superstitious hush. Something skitters in the shadows.",
    exits => { aft => 'deck' },
    items => ['black_log'],
    flags => { visited => 0, rat_swarm_alive => 1 },
  },
  captains_cabin => {
    name  => "Captain’s Cabin",
    desc  => "Maps, a locked chest, and a captain who’s suddenly very interested in privacy.",
    exits => { fore => 'deck' },
    items => [], # chest is environmental for now
    flags => { visited => 0, chest_locked => 1 },
  },
  hold => {
    name  => "Cargo Hold",
    desc  => "Crates. Shadows. And one artifact that makes your teeth ache when you breathe near it.",
    exits => { up => 'deck' },
    items => ['bone_key'],
    flags => { visited => 0, artifact_solved => 0 },
  },
);

my %NPCS = (
  langley => {
    name  => "Langley Silver",
    room  => 'galley',
    mood  => 'wary',
    dialog => {
      greet => "“Cabin boy… you’ve got quick eyes. Take this translator. Don’t let the ship learn you have it.”",
      hint  => "“Speak your meaning, not your syntax. The relic listens for intent.”",
    },
  }
);

# -----------------------------
# Utility helpers
# -----------------------------
sub room_here {
  return $ROOMS{$location};
}

sub describe_room {
  my $r = room_here();

  say "";
  say $r->{name};
  say "-" x length($r->{name});
  say $r->{desc};

  my @items = @{ $r->{items} // [] };
  if (@items) {
    say "You see: " . join(", ", map { $ITEMS{$_}{name} } @items);
  }

  my @exits = sort keys %{ $r->{exits} };
  say "Exits: " . join(", ", @exits);
}

sub show_help {
  say "";
  say "Available commands (stub):";
  say "  help   (or ?)";
  say "  quit   (or exit)";
  say "";
  say "World rendering is live; parsing and actions arrive in later commits.";
}

# -----------------------------
# Intro
# -----------------------------
sub intro {
  say "What’s your name, cabin boy?";
  print "> ";
  chomp($name = <STDIN>);
  $name ||= "Nameless";

  say "";
  say "Langley Silver wipes his hands on his apron and leans close.";
  say $NPCS{langley}{dialog}{greet};
  say "He presses something warm and humming into your palm.";
  say "You received: " . $ITEMS{translator}{name};
  say "";
  say $NPCS{langley}{dialog}{hint};

  # For commit 2, we keep translator “implicit” (not in inventory yet).
  # Later commits can model it as a permanent item flag if you want.

  describe_room();
}

# -----------------------------
# Main loop (still a stub for now)
# -----------------------------
intro();

while (1) {
  print "\n> ";
  my $raw = <STDIN>;
  last unless defined $raw;

  chomp($raw);
  $raw =~ s/^\s+|\s+$//g;

  my $lc = lc $raw;

  if ($lc eq '') {
    next;
  } elsif ($lc eq 'help' || $lc eq '?') {
    show_help();
  } elsif ($lc eq 'quit' || $lc eq 'exit') {
    say "You bow out. The ship creaks approvingly.";
    last;
  } else {
    say "Not implemented yet. Try 'help'.";
  }
}