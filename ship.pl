#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

# Langley Silver & the Antediluvian Translator
# Stage 4: world + interpreter + basic execution (look/move/take/inventory/talk/use)

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

sub has_item {
  my ($item_id) = @_;
  for my $i (@inventory) { return 1 if $i eq $item_id; }
  return 0;
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
# Stage 4: action handlers
# -----------------------------
sub do_look {
  my ($target) = @_;
  my $r = room_here();

  if (!defined $target || $target =~ /^\s*$/) {
    describe_room();
    return;
  }

  my $t = lc $target;
  $t =~ s/^\s+|\s+$//g;

  for my $id (@{ $r->{items} // [] }) {
    if (lc($ITEMS{$id}{name}) =~ /\Q$t\E/) {
      say $ITEMS{$id}{desc};
      return;
    }
  }

  for my $id (@inventory) {
    if (lc($ITEMS{$id}{name}) =~ /\Q$t\E/) {
      say $ITEMS{$id}{desc};
      return;
    }
  }

  if ($location eq 'captains_cabin' && $t =~ /(chest|box)/) {
    if ($ROOMS{captains_cabin}{flags}{chest_locked}) {
      say "A locked chest banded in iron. It smells faintly of ozone.";
    } else {
      say "The chest sits open, empty except for a lingering wrongness.";
    }
    return;
  }

  say "The translator hums, but finds no meaning in '$target' here.";
}

sub do_move {
  my ($dir) = @_;
  my $r = room_here();

  $dir //= '';
  $dir =~ s/^\s+|\s+$//g;

  if ($dir eq '') {
    say "Go where? (Try: up, down, fore, aft, hatch)";
    return;
  }

  if (!exists $r->{exits}{$dir}) {
    say "You can’t go '$dir' from here.";
    return;
  }

  $location = $r->{exits}{$dir};
  $turn++;

  if (!$ROOMS{$location}{flags}{visited}) {
    $ROOMS{$location}{flags}{visited} = 1;
    push @visited_rooms, $location;
    $score++;
  }

  describe_room();
}

sub do_inventory {
  say "";
  if (!@inventory) {
    say "You’re carrying nothing. Not even excuses.";
    return;
  }

  say "Inventory:";
  say " - " . $ITEMS{$_}{name} for @inventory;
}

sub do_take {
  my ($target) = @_;
  my $r = room_here();

  $target //= '';
  $target =~ s/^\s+|\s+$//g;
  $target = lc $target;

  if ($target eq '') {
    say "Take what?";
    return;
  }

  for my $id (@{ $r->{items} // [] }) {
    if (lc($ITEMS{$id}{name}) =~ /\Q$target\E/) {
      if (!$ITEMS{$id}{takeable}) {
        say "You can’t take that.";
        return;
      }

      $r->{items} = [ grep { $_ ne $id } @{ $r->{items} } ];
      push @inventory, $id;
      $score += 2;

      say "Taken: " . $ITEMS{$id}{name};
      return;
    }
  }

  say "You don’t see anything like that here.";
}

sub do_talk {
  my ($target) = @_;

  $target //= '';
  my $t = lc $target;

  if ($location eq 'galley' && $t =~ /(langley|cook|silver)/) {
    say $NPCS{langley}{dialog}{hint};
    return;
  }

  say "You talk to the air. It does not answer.";
}

sub do_use {
  my ($item, $target) = @_;
  $item   //= '';
  $target //= '';

  my $i = lc $item;
  my $t = lc $target;

  # Use bone key on chest
  if ($i =~ /(bone\s+key|key)/ && $t =~ /(chest|box)/) {
    if (!has_item('bone_key')) {
      say "You pat your pockets. No key.";
      return;
    }
    if ($location ne 'captains_cabin') {
      say "There’s no chest here that wants unlocking.";
      return;
    }
    if (!$ROOMS{captains_cabin}{flags}{chest_locked}) {
      say "It’s already open.";
      return;
    }

    $ROOMS{captains_cabin}{flags}{chest_locked} = 0;
    $score += 5;
    say "The bone key turns with a soft complaint. The chest clicks open.";
    say "Inside: a scrap of sailcloth marked with a symbol… like a command.";
    say "The translator purrs, delighted.";
    return;
  }

  # Use translator on black log
  if ($i =~ /(translator|relic|device)/ && $t =~ /(log|page|black)/) {
    if (!has_item('black_log')) {
      say "You don’t have the log.";
      return;
    }
    say "You hold the translator near the ink. The text settles into legible shape:";
    say "“SPEAK THE HOLD'S NAME AS INTENT, NOT AS SPELLING.”";
    $score += 3;
    return;
  }

  say "Nothing happens. The sea keeps its secrets.";
}

# -----------------------------
# Regex-driven parser (translator layer)
# -----------------------------
sub parse_command {
  my ($raw) = @_;
  $raw //= '';
  $raw =~ s/^\s+|\s+$//g;

  my $input = lc $raw;

  $input =~ s/\b(the|a|an|to|please|kindly|just)\b//g;
  $input =~ s/\s+/ /g;
  $input =~ s/^\s+|\s+$//g;

  my @patterns = (
    [ qr/^(help|\?)$/ ,                 sub { return { action => 'HELP' } } ],
    [ qr/^(quit|exit)$/ ,               sub { return { action => 'QUIT' } } ],
    [ qr/^(inv|inventory|i)$/ ,         sub { return { action => 'INVENTORY' } } ],

    [ qr/^(look|l)$/ ,                  sub { return { action => 'LOOK' } } ],
    [ qr/^(look|l|examine|inspect)\s+(?:at\s+)?(.+)$/ ,
                                       sub { return { action => 'LOOK', target => $_[0] } } ],

    [ qr/^(go|move|walk|run)\s+(.+)$/ ,
                                       sub { return { action => 'MOVE', target => $_[1] } } ],
    [ qr/^(up|down|fore|aft|hatch)$/ ,
                                       sub { return { action => 'MOVE', target => $_[0] } } ],

    [ qr/^(take|get|grab|pick\s+up)\s+(.+)$/ ,
                                       sub { return { action => 'TAKE', target => $_[1] } } ],

    [ qr/^(talk|speak)\s+(?:to\s+)?(.+)$/ ,
                                       sub { return { action => 'TALK', target => $_[1] } } ],

    [ qr/^(use)\s+(.+?)(?:\s+on\s+(.+))?$/ ,
                                       sub { return { action => 'USE', item => $_[1], target => $_[2] } } ],
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
  say "Try commands like:";
  say "  look / look at <thing>";
  say "  go <direction> (up, down, fore, aft, hatch)";
  say "  take <item>";
  say "  inventory";
  say "  talk to langley";
  say "  use <item> on <thing>";
  say "  quit";
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

  describe_room();
}

# -----------------------------
# Main loop
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
  } elsif ($cmd->{action} eq 'LOOK') {
    do_look($cmd->{target});
  } elsif ($cmd->{action} eq 'MOVE') {
    do_move($cmd->{target});
  } elsif ($cmd->{action} eq 'INVENTORY') {
    do_inventory();
  } elsif ($cmd->{action} eq 'TAKE') {
    do_take($cmd->{target});
  } elsif ($cmd->{action} eq 'TALK') {
    do_talk($cmd->{target});
  } elsif ($cmd->{action} eq 'USE') {
    do_use($cmd->{item}, $cmd->{target});
  } else {
    say "The translator clicks softly. It cannot act on that yet.";
  }
}
