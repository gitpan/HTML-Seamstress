#!/Users/metaperl/install/bin/perl

# QUICK PRETTY PRINTER!

use HTML::Stitchery;

my $file = shift or die "must give html file to pretty-print";

my $tree = HTML::TreeBuilder->new_from_file($file);

#$tree->dump; # a method we inherit from HTML::Element

print $tree->dump_html;
