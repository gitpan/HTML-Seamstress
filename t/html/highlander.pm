package html::highlander;
use strict;
use warnings;
use base qw(HTML::Seamstress);

my $tree;

my ($age_dialog);
sub new {
$tree = __PACKAGE__->new_from_file('/home/terry/perl/hax/HTML-Seamstress-2.6/t/html/highlander.html');

# content_accessors
;

# highlander_accessors
$age_dialog = $tree->look_down(id => q/age_dialog/);

$tree;
}

# content subs

# highlander subs

sub age_dialog {
   my $class = shift;
   my $aref = shift;
   my $local_root_id = 'age_dialog';

   if ($aref) {
      $age_dialog->highlander($local_root_id, $aref, @_);
      return $tree
   } else {
      return $age_dialog
   }

}



sub tree {
  $tree
}


1;

