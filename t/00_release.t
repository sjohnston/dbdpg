#!perl

## Make sure the version number is consistent in all places

use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use lib 't','.';

if (! $ENV{RELEASE_TESTING}) {
	plan (skip_all =>  'Test skipped unless environment variable RELEASE_TESTING is set');
}
plan tests => 2;

my $vre = qr{(\d+\.\d+\.\d+\_?\d*)};

my %filelist = (
	'dbdimp.c'             => [1, [ qr{ping test v$vre},        ]],
	'META.yml'             => [3, [ qr{version\s*:\s*$vre},     ]],
	'Pg.pm'                => [3, [ qr{VERSION = qv\('$vre'},
			                        qr{documents version $vre},
                                    qr{ping test v$vre},        ]],
	'lib/Bundle/DBD/Pg.pm' => [1, [ qr{VERSION = '$vre'},       ]],
	'Makefile.PL'          => [1, [ qr{VERSION = '$vre'},       ]],
	'README'               => [1, [ qr{is version $vre},
                                    qr{TEST VERSION \($vre},    ]],
	'Changes'              => [1, [ qr{^(?:Version )*$vre},     ]],
);

my %v;
my $goodversion = 1;
my $goodcopies = 1;
my $lastversion = '?';

## Walk through each file and slurp out the version numbers
## Make sure that the version number matches
## Verify the total number of version instances in each file as well

for my $file (sort keys %filelist) {
	my ($expected,$regexlist) = @{ $filelist{$file} };
	#diag "Want file $file to have $expected";

	my $instances = 0;
	open my $fh, '<', $file or die qq{Could not open "$file": $!\n};
  SLURP: while (<$fh>) {
		for my $regex (@{ $regexlist }) {
			if ($_ =~ /$regex/) {
				push @{$v{$file}} => [$1, $.];
				$instances++;
				last SLURP if $file eq 'Changes'; ## Only the top version please
			}
		}
	}
	close $fh or warn qq{Could not close "$file": $!\n};

	if ($instances != $expected) {
		$goodcopies = 0;
		diag "Version instance mismatch for $file: expected $expected, found $instances";
	}

}


if ($goodcopies) {
	pass ('All files had the expected number of version strings');
}
else {
	fail ('All files did not have the expected number of version strings');
}

if ($goodversion) {
	pass ("All version numbers are the same ($lastversion)");
}
else {
	fail ('All version numbers were not the same!');
	for my $filename (sort keys %v) {
		for my $glob (@{$v{$filename}}) {
			my ($ver,$line) = @$glob;
			diag "File: $filename. Line: $line. Version: $ver\n";
		}
	}
}

exit;

