use v5.10;
use strict;
use YAML::PP qw/LoadFile/;

# docker.yml organizes commands, options, and option parameters

# the following option parameter types appear in the help text;
# the hash maps them to appropriate completion functions
my $cmplfn_for = {
  bytes => 'num',
  decimal => 'num',
  duration => 'num',
  filter => 'str',
  int => 'num',
  list => 'str',
  map => 'str',
  mount => 'dir',
  string => 'str',
  strings => 'str',
  uint16 => 'num',
  ulimit => 'num',
};

my $indent_by = 2;
my $desc_at = 45;


our $COMPLETE_SHELL_VER="0.2";

my $fn = shift;
my $yml = LoadFile($fn) or die $!;

print <<HDR;
CompleteShell v$COMPLETE_SHELL_VER

N $$yml{cmd} v$$yml{version} ..'$$yml{desc}'
HDR

my $tlcmd = $yml->{cmd};
my $traverse;
$traverse = sub {
  my ($cmd, $indent) = @_;
  my $ln;
  my $ind = $indent+$indent_by;

  if ($cmd->{cmd} ne $tlcmd) {
    $ln = (" " x $indent)."C $$cmd{cmd}";
    say $ln.(" " x fill($ln))."..$$cmd{desc}";
  }
  if ($cmd->{options}) {
    for my $opt (@{$cmd->{options}}) {
      my $pm = $cmplfn_for->{$opt->{parm}};
      $ln =
	(" " x $ind).
	"O ".join(" ",$opt->{opt},$opt->{syn} && @{$opt->{syn}}).
	($pm ? " =$pm" : "");
      say $ln.(" " x fill($ln))."..";
    }
  }
  if (my $args = $cmd->{usage}) {
    $args =~ s/$tlcmd\s*//;
    $args =~ s/$$cmd{cmd}\s*//;
    $args =~ s/\[OPTIONS\]\s*//;
    my @args = ($args =~ /PATH \|/ ? ($args) : split /\s/, $args);
    for my $arg (@args) {
      say(
	(" " x $ind).
	"# FIX ME...");
      say(
	(" " x $ind).
	"A +".$arg);
    }
  }
  foreach my $scmd (values %{$cmd->{subcmds}}) {
    $traverse->($scmd, $indent+$indent_by);
  }
};

$traverse->($yml,0);



sub fill { $desc_at - length($_[0]) > 0 ? $desc_at - length($_[0]) : 1 }
