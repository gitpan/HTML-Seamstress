package HTML::Seamstress;

#use 5.008;
use strict;
use warnings;

use Carp qw(confess);
use Data::Dumper;
use File::Spec;
use Scalar::Listify;
use Tie::Cycle;

use base qw/HTML::TreeBuilder/;

our         @ISA = qw(Exporter HTML::TreeBuilder);

require Exporter;


# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use HTML::Seamstress ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);

our $VERSION = '2.91';

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

our ($table_data, $tr_data, $gi_td);
sub table {

  my ($s, %table) = @_;

  my $table = {};

  $table->{table_node} = $s->look_down($ID, $table{gi_table});

  my @table_gi_tr = listify $table{gi_tr} ;
  my @iter_node = map 
    {
      $table->{table_node}->look_down($ID, $_)
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

our ($select_data);
sub unroll_select {

  my ($s, %select) = @_;

  my $select = {};

  my $select_node = $s->look_down($ID, $select{select_label});

  my $option = $select_node->look_down('_tag' => 'option');

  warn $option;


  $option->detach;

  while (my $row = $select{option_data_iter}->())
    {

      warn Dumper($row);
      my $o = $option->clone;
      $o->attr('value', $select{option_value}->($row));
      $o->detach_content;
      $o->push_content($select{option_content}->($row));

      $select_node->push_content($o);
    }


}


sub HTML::Element::content_handler {
  my ($tree, $id_name, $content) = @_;

  $tree->set_child_content($ID => $id_name, $content);

}

sub HTML::Element::highlander {
  my ($tree, $local_root_id, $aref, @arg) = @_;

  ref $aref eq 'ARRAY' or confess 
    "must supply array reference";
    
  my @aref = @$aref;
  @aref % 2 == 0 or confess 
    "supplied array ref must have an even number of entries";

  my $survivor;
  while (my ($id, $test) = splice @aref, 0, 2) {
    if ($test->(@arg)) {
      $survivor = $id;
      last;
    }
  }

  my $node = $tree->look_down(id => $survivor);
  $tree->set_child_content($local_root_id, $node);

}

sub HTML::Element::set_child_content {
  my $tree      = shift;
  my $content   = pop;
  my @look_down = @_;

  my $content_tag = $tree->look_down(@look_down);

  unless ($content_tag) {
    warn "@look_down not found";
    return;
  }

  $content_tag->detach_content;
  $content_tag->push_content($content);

}

sub HTML::Element::set_sibling_content {
  my ($elt, $content) = @_;

  $elt->parent->splice_content($elt->pindex + 1, 1, $content);

}



1;
__END__

