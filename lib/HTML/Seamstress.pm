package HTML::Seamstress;

#use 5.008;
use strict;
use warnings;

use Array::Dissect qw(:all);
use Carp qw(confess);
use Data::Dumper;
use File::Spec;
use HTML::Element::Library;
use Scalar::Listify;
use Tie::Cycle;

use base qw/HTML::TreeBuilder HTML::Element/;


our $VERSION = '2.91e';

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

  bless $self, $class;

}


sub table {

  my ($s, %table) = @_;

  my $table = {};

  $table->{table_node} = $s->look_down(id => $table{gi_table});

  my @table_gi_tr = listify $table{gi_tr} ;
  my @iter_node = map 
    {
      $table->{table_node}->look_down(id => $_)
    } @table_gi_tr;

  tie $table->{iter_node}, 'Tie::Cycle', \@iter_node;

  $table->{content}    = $table{content};
  $table->{parent}     = $table->{table_node}->parent;


  $table->{table_node}->detach;
  $_->detach for @iter_node;

  my $add_table;

  while (my $row = $table{tr_data}->($table, $table{table_data})) 
    {
      ++$add_table;

      # wont work:      my $new_iter_node = $table->{iter_node}->clone;
      my $I = $table->{iter_node};
      my $new_iter_node = $I->clone;


      $table{td_data}->($new_iter_node, $row);
      $table->{table_node}->push_content($new_iter_node);
    }

  $table->{parent}->push_content($table->{table_node}) if $add_table;

}




1;
__END__

