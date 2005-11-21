package html::highlander;

use strict;
use warnings;

use HTML::TreeBuilder;

use lib '/ernest/dev/seamstress/t/';
use base qw(HTML::Seamstress::Base); 

our $tree;

#warn HTML::Seamstress::Base->comp_root(); 
sub new {
  my $file = HTML::Seamstress::Base->comp_root() . 'html/highlander.html' ;

  -e $file or die "$file does not exist. Therefore cannot load";

  $tree =HTML::TreeBuilder->new;
  $tree->store_declarations;
  $tree->parse_file($file);
  $tree->eof;
  
  bless $tree, __PACKAGE__;
}

1;
