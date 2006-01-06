package HTML::Seamstress;

use strict;
use warnings;

use Carp qw(confess);
use Cwd;
use Data::Dumper;
use File::Spec;
use HTML::Element::Library;
use Scalar::Listify;


use base qw/HTML::TreeBuilder HTML::Element HTML::Element::Library/;


our ($VERSION) = ('$Revision: 3.8 $' =~ m/([\.\d]+)/) ;


sub new_from_file { # or from a FH
  my ($class, $file) = @_;

  warn $file;

  my $new = HTML::TreeBuilder->new_from_file($file);
  bless $new, $class;
}


sub html {
  my ($class, $file, $extension) = @_;

  $extension ||= 'html';

  my $pm = File::Spec->rel2abs($file);
  $pm =~ s!pm$!$extension!;
  $pm;
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

