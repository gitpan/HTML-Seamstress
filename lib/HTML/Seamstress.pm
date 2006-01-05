package HTML::Seamstress;

use strict;
use warnings;

use Carp qw(confess);
use Cwd;
use Data::Dumper;
use File::Spec;
use HTML::Element::Library;
use Scalar::Listify;


use base qw/HTML::TreeBuilder HTML::Element/;


our ($VERSION) = ('$Revision: 3.6 $' =~ m/([\.\d]+)/) ;

our $ID = 'id';

sub new_from_file { # or from a FH
  my $class = shift;
  confess ("new_from_file takes only one argument")
   unless @_ == 1;
  confess ("new_from_file is a class method only")
   if ref $class;
  my $new = $class->new();
  $new->parse_file($_[0]);
  return $new;
}


sub eval_require {
  my $module = shift;

  return unless $module;

  eval "require $module";

  confess $@ if $@;
}

sub HTML::Element::expand_replace {
    my $node = shift;
    
    my $seamstress_module = ($node->content_list)[0]  ;
    eval "require $seamstress_module";
    die $@ if $@;
    $node->replace_content($seamstress_module->new) ;

}


1;
__END__

