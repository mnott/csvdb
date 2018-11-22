#!/bin/sh
exec perl -x $0 "$@"
#!/usr/bin/env perl -I lib
#
# Throw away dupes (move last line to top after)
#

use strict;
use warnings;

use Text::CSV;
my $csv = Text::CSV->new({ sep_char => ',' });

my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";

my %prods;

my $sum = 0;
open(my $data, '<', $file) or die "Could not open '$file' $!\n";
while (my $line = <$data>) {
  chomp $line;

  if ($csv->parse($line)) {

      my @fields = $csv->fields();

      my $prod_id = $fields[0];
      my $prod_desc = $fields[1];

      $prods{$prod_id} = $prod_desc;
  } else {
      warn "Line could not be parsed: $line\n";
  }
}

my @prod_ids = sort keys %prods;

for my $prod_id (@prod_ids) {
	print "$prod_id,\"".$prods{$prod_id}."\"\n";
}