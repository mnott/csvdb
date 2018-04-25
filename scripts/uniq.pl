#!/bin/sh
exec perl -x $0 "$@"
#!/usr/bin/env perl -I lib
###################################################
#
# Unique a CSV file based on first column.
#
# We use it for example to unique a list of product
# codes, descriptions based on product codes.
#
# (c) 2018 Matthias Nott
#
###################################################


if (@ARGV == 0) {
	die "Please pass one csv file as parameter.\n";
}

foreach my $file (@ARGV) {
	my %data;
	my %header;
	my $row;

	open(CSV, $file) or die("Could not open file $file: $!");

	while (<CSV>) {
		chomp;
		if (/^(.*?),(.*?)$/) {
			if ($++row == 1) {
				$header{$1} = $2;
			} else {
				$data{$1} = $2;
			}
		}
	}
	close(CSV);

	foreach my $key (keys %header) {
		print $key . ",". $header{$key} . "\n";
	}
	foreach my $key (reverse sort keys %data) {
		print $key . ",". $data{$key} . "\n";
	}
}

