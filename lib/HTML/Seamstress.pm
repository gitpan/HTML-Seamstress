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
#use Tie::Cycle;

use base qw/HTML::TreeBuilder HTML::Element/;


our ($VERSION) = ('$Revision: 3.3 $' =~ m/([\.\d]+)/) ;

our $ID = 'id';


# Preloaded methods go here.
sub new {

  my ($class) = @_;

  my $self = HTML::TreeBuilder->new;

  bless $self, $class;

}

sub new_from_file {

  my ($class, $file) = @_;

  $file or die "must supply file for weaving";

  my $self = HTML::TreeBuilder->new_from_file($file);

#  $self->no_space_compacting(1);

  bless $self, $class;

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

