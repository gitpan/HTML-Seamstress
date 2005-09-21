# Welcome to a -*- perl -*- test script
use strict;
use Test::More qw(no_plan);

warn `pwd`;
system "cd t/html; ../../seamc -debug *.html";

ok 1;

