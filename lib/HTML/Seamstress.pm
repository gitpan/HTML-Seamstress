package HTML::Seamstress;

use 5.008;
use strict;
use warnings;

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
		 htmls_compile
);

our $VERSION = '2.0';

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


sub HTML::Element::content_handler {
  my ($tree, $id_name, $content) = @_;



  my $content_tag = $tree->look_down($ID, $id_name);
#  warn "my $content_tag = $tree->look_down($ID, $id_name);";

  unless ($content_tag) {
    warn "$id_name not found";
    return;
  }

  # delete dummy content
  $content_tag->detach_content;        

  # add new content
  $content_tag->push_content($content);
#  warn $tree->as_HTML;
}



1;
__END__

