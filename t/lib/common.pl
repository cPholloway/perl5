# This code is used by lib/charnames.t, lib/croak.t, lib/feature.t,
# lib/subs.t, lib/strict.t and lib/warnings.t
#
# On input, $::local_tests is the number of tests in the caller; or
# 'no_plan' if unknown, in which case it is the caller's responsibility
# to call cur_test() to find out how many this executed

# ABSTRACT:  This is a helper script for other tests

BEGIN {
    require './test.pl'; require './charset_tools.pl';
}

use Config;
use File::Path;
use File::Spec::Functions qw(catfile curdir rel2abs);

use strict;
use warnings;

# The name of the file that called this script
# Must have the '.t' file extension or it dies aquiring the pragma_name
my (undef, $file) = caller;
my ($pragma_name) = $file =~ /([A-Za-z_0-9]+)\.t$/
    or die "Can't identify pragama to test from file name '$file'";

# Force print to get flushed right away (stdout and stderr should get printed in order)
$| = 1;

my @w_files;

# if ARGV, add the args to the array and expect files to be in 't/lib/$pragma_name/@ARGV'
# else, search for files in 't/lib/$pragma_name/*' while filtering out the '.rej' extention, '~', and (Autosaved).txt
if (@ARGV) {
    print "ARGV = [@ARGV]\n";
    @w_files = map { "./lib/$pragma_name/$_" } @ARGV;
} else {
    @w_files = sort grep !/( \.rej | ~ | \ \(Autosaved\)\.txt ) \z/nx,
			 glob catfile(curdir(), "lib", $pragma_name, "*");
}

# This removes files that end with '_l1' if the system uses the EBCDIC encoding (i.e. IBM mainframe)
if ($::IS_EBCDIC) { # Skip Latin1 files
    @w_files = grep { $_ !~ / _l1 $/x } @w_files
}

# setup_multiple_progs() comes from t/test.pl line 1139
# $tests will be the number of tests to expect to get executed
# @prgs is an array containing the code to execute
my ($tests, @prgs) = setup_multiple_progs(@w_files);

# $^X is the absolute path of the perl binary in use
$^X = rel2abs($^X);
# Ensure that @INC contains only absolute paths
@INC = map { rel2abs($_) } @INC;

# Create a temporary directory in which to write files
my $tempdir = tempfile;
mkdir $tempdir, 0700 or die "Can't mkdir '$tempdir': $!";
chdir $tempdir or die die "Can't chdir '$tempdir': $!";
my $cleanup = 1;

# Ensure the temporary directory and all files/directories within it are cleaned up during global destruction
END {
    if ($cleanup) {
	chdir '..' or die "Couldn't chdir .. for cleanup: $!";
	rmtree($tempdir);
    }
}

# This is just telling it how many tests to expect to run
# if the if statement is true, then it is 'no_plan'
# else, it is the number of tests in $tests plus the number of tests that the caller makes
if ($::local_tests && $::local_tests =~ /\D/) {
    # If input is 'no_plan', pass it on unchanged
    plan $::local_tests;
} else {
    plan $tests + ($::local_tests || 0);
}

# comes from 't/test.pl'
# this is just executing the tests
run_multiple_progs('../..', @prgs);

1;
