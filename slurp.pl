use v5.10;
use strict;
use Carp qw/carp/;
use YAML::PP qw/Dump/;
our $VERBOSE = 0;
# [ { cmd => 'cmd',
#     desc => <brief description>
#     type => <some name, to subset cmds>
#     usage => <usage string>
#     options => [
#        { opt => '--option',
#          desc => <brief description>,
#          syn => ['--synonym1','-s'],
#          parm => <parameter type> }
#     subcmds => [ <THIS STRUCT>, ... ] },
#   ... ]

my $data = {
  cmd => 'docker',
  desc => 'A self-sufficient runtime for containers',
  usage => '',
  options => [],
  subcmds => {},
 };

open my $fh, "-|", "2>&1 docker --help";
parse($fh, $data);
close $fh;

for my $subcmd (keys %{$data->{subcmds}}) {
  open my $fh, "-|", "2>&1 docker $subcmd --help";
  parse($fh, $data->{subcmds}{$subcmd});
  1;
}

print Dump $data;

sub parse {
  my ($fh, $ptr) = @_;
  my ($in_opt, $in_cmd);
  while (<$fh>) {
    chomp;
    s/^\s+//;
    next unless $_;
    my ($key, @rest) = split / {2,}|\t/;
    for ($key) {
      /Usage:/ && do {
	$ptr->{usage} = join(" ", @rest);
	last;
      };
      /Options:/ && do {
	undef $in_cmd;
	$in_opt = 1;
	last;
      };
      /Commands:/ && do {
	undef $in_opt;
	$in_cmd = 1;
	last;
      };
      /Run '/ && do {
	undef $in_cmd;
	undef $in_opt;
      };
      $in_opt && do {
	my @o = split /,?\s+/, $key;
	my $o = shift @o;
	unless (length $o && ($o =~ /^-/)) {
	  carp "At $., '$o' not an option" if $VERBOSE;
	  last;
	}
	$o = { opt => $o };
	if (@o) {
	  push @{$o->{syn}}, grep /^-/,@o;
	  $o->{parm} = join(" ", grep !/^-/,@o);
	}
	push @{$ptr->{options}}, $o;
	last;
      };
      $in_cmd && do {
	$ptr->{subcmds}{$key} = { cmd => $key, desc => join(" ", @rest) };
	last;
      };
    }
  }
  return 1;
}
