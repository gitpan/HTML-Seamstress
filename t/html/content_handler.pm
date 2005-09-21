package html::content_handler;
#use strict;
use warnings;
use base qw(HTML::Seamstress);

my $tree;

#my ($name,$date);
sub new {
$tree = __PACKAGE__->new_from_file('/home/metaperl/perl/src/seamstress/t/html/content_handler.html');

# content_accessors
$name = $tree->look_down(id => q/name/);
$date = $tree->look_down(id => q/date/);

# highlander_accessors
;

# iter_accessors
;

# dual_iter_accessors
;

$tree;
}

# content subs

sub name {
   my $self = shift;
   my $content = shift;
   if (defined($content)) {
      $name->content_handler(name => $content);
      return $tree
   } else {
      return $name
   }

}



sub date {
   my $self = shift;
   my $content = shift;
   if (defined($content)) {
      $date->content_handler(date => $content);
      return $tree
   } else {
      return $date
   }

}


# highlander subs

# iter subs


# dual_iter subs


sub tree {
  $tree
}


1;

