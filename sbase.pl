#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Cwd;
use HTML::Seamstress;
use File::Basename;
use File::Path;
use File::Slurp;
use File::Spec;
use Data::Dumper;
use Pod::Usage;

our $VERSION = 1.0;

my $_P = 'HTML::Seamstress::Base' ;

print "
I want to generate $_P and save it somewhere on 
\@INC so that it can be found by Perl. 
Here are your choices:\n\n";



my $INC;
printf("%2d - $_\n", $INC++) for (grep { $_ !~ /^[.][.]?$/ } @INC) ;

print "Enter the number of your choice: ";
my $dir = <STDIN>;
my $incdir = $INC[$dir];

my $outdir = "$incdir/HTML/Seamstress";

eval { mkpath [$outdir] };

if ($@) {
  die "I'm sorry. I could not make $outdir
Why dont you try mkdir -p $outdir
for me and then restart.
"
}

sub template {
  my $comp_root = shift;
sprintf
'package HTML::Seamstress::Base;

use base qw(HTML::Seamstress);

use vars qw($comp_root);

BEGIN {
  $comp_root = "%s"; # IMPORTANT: last character must be "/"
}

use lib $comp_root;

sub comp_root { $comp_root }

1;', $comp_root;

}


sub comp_root {
  print "
Ok, now I need to know the directory *above*
where your HTML files are. If your files are
in /usr/htdocs/, I recommend you give me the 
directory /usr so that you can obtain your
HTML files via use htdocs::filename.

So, what is the absolute path to 
your document root? ";

  my $comp_root=<STDIN>;
  chomp $comp_root;

#  $comp_root .= "/" 
#      unless ($comp_root =~ m!/$!);

  $comp_root;
}

my $outfile = "$outdir/Base.pm";

open  O, ">$outfile" or die "Could not write to $outfile: $!";
our  $C = comp_root;
print O template($C);

print "$_P has been written to $outdir as $outfile\n";









=head1 NAME

 sbase - Create class which will provide access to HTML files as modules

=head1 SYNOPSIS

 sbase $DOCUMENT_ROOT/..

=head1 DESCRIPTION

That's the whole description, but it looks funny doesn't it? Why is that
C</..> there? Well, it's very simple you see. This program sets up a class
which makes it possible to access your HTML files. If you want to access
/usr/htdocs/index.html via C<use htdocs::index> then your document root
should be C</usr> and not C</usr/htdocs>. If you would rather access 
C</usr/htdocs/index.html> via C<use index> then supply C<$DOCUMENT_ROOT> 
instead.

I prefer the longer module name because it makes namespace clashes much 
less likely.

=cut
