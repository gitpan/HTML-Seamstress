package HTML::Seamstress;

#use 5.008;
use strict;
use warnings;

#use Array::Dissect qw(:all);
use Carp qw(confess);
use Cwd;
use Data::Dumper;
use File::Spec;
use HTML::Element::Library;
use Scalar::Listify;


use base qw/HTML::TreeBuilder HTML::Element/;


our ($VERSION) = ('$Revision: 3.5 $' =~ m/([\.\d]+)/) ;

our $ID = 'id';

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

