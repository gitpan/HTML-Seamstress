package html::hello_world;
use vars qw($tree);
use HTML::TreeBuilder;

tree();

# look_down
my $name = $tree->look_down(id => q/name/);
my $date = $tree->look_down(id => q/date/);

# content subs

sub name {
	my $content = shift;
        $name->content_handler(name => $content);
        $tree;
}
	



sub date {
	my $content = shift;
        $date->content_handler(date => $content);
        $tree;
}
	



$tree->dump;

sub tree {
# serial
$tree = bless( {
                 '_done' => 1,
                 '_implicit_tags' => 1,
                 '_tighten' => 1,
                 '_head' => bless( {
                                     '_parent' => {},
                                     '_content' => [
                                                     bless( {
                                                              '_parent' => {},
                                                              '_content' => [
                                                                              'Hello World'
                                                                            ],
                                                              '_tag' => 'title'
                                                            }, 'HTML::Element' )
                                                   ],
                                     '_tag' => 'head'
                                   }, 'HTML::Element' ),
                 '_store_comments' => 0,
                 '_content' => [
                                 {},
                                 bless( {
                                          '_parent' => {},
                                          '_content' => [
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Hello World'
                                                                                 ],
                                                                   '_tag' => 'h1'
                                                                 }, 'HTML::Element' ),
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Hello, my name is ',
                                                                                   bless( {
                                                                                            '_parent' => {},
                                                                                            '_content' => [
                                                                                                            'ah, Clem'
                                                                                                          ],
                                                                                            '_tag' => 'span',
                                                                                            'id' => 'name',
                                                                                            'klass' => 'content'
                                                                                          }, 'HTML::Element' ),
                                                                                   '. '
                                                                                 ],
                                                                   '_tag' => 'p'
                                                                 }, 'HTML::Element' ),
                                                          bless( {
                                                                   '_parent' => {},
                                                                   '_content' => [
                                                                                   'Today\'s date is ',
                                                                                   bless( {
                                                                                            '_parent' => {},
                                                                                            '_content' => [
                                                                                                            'Oct 6, 2001'
                                                                                                          ],
                                                                                            '_tag' => 'span',
                                                                                            'id' => 'date',
                                                                                            'klass' => 'content'
                                                                                          }, 'HTML::Element' ),
                                                                                   '. '
                                                                                 ],
                                                                   '_tag' => 'p'
                                                                 }, 'HTML::Element' )
                                                        ],
                                          '_tag' => 'body'
                                        }, 'HTML::Element' )
                               ],
                 '_body' => {},
                 '_ignore_unknown' => 1,
                 '_pos' => undef,
                 '_ignore_text' => 0,
                 '_no_space_compacting' => 0,
                 '_implicit_body_p_tag' => 0,
                 '_warn' => 0,
                 '_p_strict' => 0,
                 '_hparser_xs_state' => \137223920,
                 '_element_count' => 3,
                 '_store_declarations' => 0,
                 '_tag' => 'html',
                 '_store_pis' => 0,
                 '_element_class' => 'HTML::Element'
               }, 'HTML::TreeBuilder' );
$tree->{'_head'}{'_parent'} = $tree;
$tree->{'_head'}{'_content'}[0]{'_parent'} = $tree->{'_head'};
$tree->{'_content'}[0] = $tree->{'_head'};
$tree->{'_content'}[1]{'_parent'} = $tree;
$tree->{'_content'}[1]{'_content'}[0]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[1]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1]{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[2]{'_parent'} = $tree->{'_content'}[1];
$tree->{'_content'}[1]{'_content'}[2]{'_content'}[1]{'_parent'} = $tree->{'_content'}[1]{'_content'}[2];
$tree->{'_body'} = $tree->{'_content'}[1];

}

1;

