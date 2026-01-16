#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

# Langley Silver & the Antediluvian Translator
# Commit 2: world data structures + room rendering.
# Commit 3: regex-driven command interpretation (translator layer).
# Gameplay actions arrive in later commits.

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

# -----------------------------
# Regex-driven parser (translator layer)
# -----------------------------
sub parse_command {
  my ($raw) = @_;
  $raw //= '';
  $raw =~ s/^\s+|\s+$//g;

  my $input = lc $raw;

  # Strip common filler words to simulate "intent parsing"
  $input =~ s/\b(the|a|an|to|please|kindly|just)\b//g;
  $input =~ s/\s+/ /g;
  $input =~ s/^\s+|\s+$//g;

  # Ordered patterns: first match wins.
  my @patterns = (
    [ qr/^(help|\?)$/ ,                 sub { return { action => 'HELP' } } ],
    [ qr/^(quit|exit)$/ ,               sub { return { action => 'QUIT' } } ],
    [ qr/^(inv|inventory|i)$/ ,         sub { return { action => 'INVENTORY' } } ],

    # LOOK / EXAMINE
    [ qr/^(look|l)$/ ,                  sub { return { action => 'LOOK' } } ],
    [ qr/^(look|l|examine|inspect)\s+(?:at\s+)?(.+)$/ ,
                                       sub { return { action => 'LOOK', target => $_[0] } } ],

    # MOVE
    [ qr/^(go|move|walk|run)\s+(.+)$/ ,
                                       sub { return { action => 'MOVE', target => $_[0] } } ],
    [ qr/^(up|down|fore|aft|hatch)$/ ,
                                       sub { return { action => 'MOVE', target => $_[0] } } ],

    # TAKE
    [ qr/^(take|get|grab|pick\s+up)\s+(.+)$/ ,
                                       sub { return { action => 'TAKE', target => $_[0] } } ],

    # TALK
    [ qr/^(talk|speak)\s+(?:to\s+)?(.+)$/ ,
                                       sub { return { action => 'TALK', target => $_[0] } } ],

    # USE
    [ qr/^(use)\s+(.+?)(?:\s+on\s+(.+))?$/ ,
                                       sub { return { action => 'USE', item => $_[0], target => $_[1] } } ],
  );

  for my $p (@patterns) {
    my ($re, $mk) = @$p;
    if ($input =~ $re) {
      my @caps = ($1, $2, $3);
      return $mk->(@caps);
    }
  }

  return { action => 'UNKNOWN', raw => $raw };
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

  # For commit 2/3, we keep translator “implicit” (not in inventory yet).
  # Later commits can model it as a permanent item flag if you want.

  describe_room();
}

# -----------------------------
# Main loop (parser is live; actions are stubbed)
# -----------------------------
intro();

while (1) {
  print "\n> ";
  my $raw = <STDIN>;
  last unless defined $raw;

  chomp($raw);
  $raw =~ s/^\s+|\s+$//g;

  next if $raw eq '';

  my $cmd = parse_command($raw);

  if ($cmd->{action} eq 'HELP') {
    show_help();
  } elsif ($cmd->{action} eq 'QUIT') {
    say "You bow out. The ship creaks approvingly.";
    last;
  } elsif ($cmd->{action} eq 'UNKNOWN') {
    say "The translator clicks softly. It cannot parse that. Try 'help'.";
  } else {
    # Commit 3 stub: show the interpreted intent, but don't execute gameplay yet.
    my $msg = "Parsed: $cmd->{action}";
    $msg .= " target='$cmd->{target}'" if defined $cmd->{target};
    $msg .= " item='$cmd->{item}'"     if defined $cmd->{item};
    say "$msg (not implemented yet)";
  }
}
