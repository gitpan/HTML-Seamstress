use HTML::Seamstress;
use File::Spec;

my $file = 'small.html';
my $abs  = File::Spec->rel2abs($file);
my $tree = HTML::Seamstress->new_from_file($file);

my @content = $tree->look_down(klass => 'content') ;

warn "found " . @content . ' nodes ' ;

our @scalar;
our @kontent;

map { 
  my $id = $_->attr('id');
  push @scalar, $id;
  push @kontent, kontent($id);

} @content;

use Data::Dumper;
$Data::Dumper::Purity = 1;

open D, '>html/hello_world.pm' or die $!;

our $pkg    = 'html::hello_world';
our $serial = Data::Dumper->Dump([$tree], ['tree']);

$serial =~ s/HTML::Seamstress/$pkg/;

our $look_down =  join ";\n",
  map { sprintf 'my $%s = $tree->look_down(id => q/%s/)', $_, $_ } @scalar;

our $kontent = join "\n", @kontent;

print D pkg();


sub kontent { sprintf <<'EOK', ($_[0]) x 4 }

sub %s {
   my $class = shift;
   my $content = shift;
   if (defined($content)) {
      $%s->content_handler(%s => $content);
   } else {
      $%s
   }
   $tree;
}
	

EOK
  

sub pkg { sprintf <<'EOPKG', $pkg, $look_down, $kontent, $abs, $serial }
package %s;
use base HTML::Seamstress;

use vars qw($tree);
tree();

# look_down for klass tags
%s;

# content subs
%s

# the html file %s
sub tree {
# serial
%s
}

1;

EOPKG
