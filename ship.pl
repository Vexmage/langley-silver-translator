#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

# Langley Silver & the Antediluvian Translator
# Commit 1: scaffold + intro + minimal input loop.
# Later commits add the world model and regex-driven command interpretation.

sub intro {
  say "Langley Silver & the Antediluvian Translator";
  say "----------------------------------------";
  say "You’re a cabin boy on a pirate ship carrying antediluvian artifacts.";
  say "The cook, Langley Silver, slips you a strange translator and a warning:";
  say "“Speak your meaning, not your syntax.”";
  say "";
  say "Type 'help' for commands. Type 'quit' to exit.";
}

sub show_help {
  say "";
  say "Available commands (stub):";
  say "  help   (or ?)";
  say "  quit   (or exit)";
  say "";
  say "Everything else is not implemented yet.";
}

intro();

while (1) {
  print "\n> ";
  my $raw = <STDIN>;
  last unless defined $raw;

  chomp($raw);
  $raw =~ s/^\s+|\s+$//g;

  # Minimal stub interpretation (real regex parser arrives later)
  my $lc = lc $raw;

  if ($lc eq '' ) {
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
