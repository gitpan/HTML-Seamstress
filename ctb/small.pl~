use HTML::TreeBuilder;

my $tree = HTML::TreeBuilder->new_from_file('small.html');

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

our $serial = Data::Dumper->Dump([$tree], ['tree']);
our $pkg    = 'html::hello_world';

our $look_down =  join ";\n",
  map { sprintf 'my $%s = $tree->look_down(id => q/%s/)', $_, $_ } @scalar;

our $kontent = join "\n", @kontent;

print D pkg();


sub kontent { sprintf <<'EOK', $_[0], $_[0], $_[0] }

sub %s {
	my $content = shift;
        $%s->content_handler(%s => $content);
        $tree;
}
	

EOK
  

sub pkg { sprintf <<'EOPKG', $pkg, $look_down, $kontent, $serial }
package %s;
use vars qw($tree);
use HTML::TreeBuilder;

tree();

# look_down
%s;

# content subs
%s

$tree->dump;

sub tree {
# serial
%s
}

1;

EOPKG
