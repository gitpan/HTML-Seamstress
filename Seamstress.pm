package HTML::Seamstress;

use Carp qw(croak);

# perl core

use Data::Dumper;
use Symbol;

# CPAN

use HTML::Tree;
use Cache::MemoryCache;

# pragmas

use 5.006;
use strict;
use warnings;

# version

our $VERSION = sprintf '%s', q$Revision: 1.11 $ =~ /\S+\s+(\S+)\s+/;


# code

my $starttag_attr   = 'starttag';
my $endtag_attr   = 'endtag';
my $plaintext_attr   = 'plaintext';
my $supply_attr   = 'supply';
my $iterator_attr = 'iterator';
my $worker_attr   = 'worker';

# temp package creation stuff

my $temp_package_prefix = 'HTML::Seamstress::PageObject';
my $temp_package_count;
sub temp_package {
    sprintf "%s_%d", $temp_package_prefix, $temp_package_count++ ;
}

# Cache::Cache stuff

# for an html page, let's create the perl object associated with it:

sub make_page_obj {
    my ($self,$config) = @_;
    my $page = $config->{using};
    my $page_object;
    
    if ($page) {
	eval "require $page";
	croak $@ if ($@);
	$page_object = $page->new;
    }

    $page_object;
}


# The "constructor", so to speak. 

sub weave {

    my ($class, @config) = @_;

    my %config = @config;

    my $self = bless \%config, $class;
    
#    warn $config{html};

    $config{html} or die "HTML file $config{html} not defined.";

    my $tree = HTML::TreeBuilder->new_from_file($config{html})
      or die "error building tree from $config{html}: $!";


#    warn 'TREE: ', $tree->dump;

    $tree->ignore_ignorable_whitespace(0);

    $self->{tree}     = $tree;

    $self->{page_object} = $self->make_page_obj(\%config);

    $self->{visitor}  = \&HTML::Seamstress::visitor;

    $self->visit($tree->root);
}

sub compile {
    
    my ($class, @config) = @_;

    my %config = @config;

    my $self = bless \%config, $class;
    
#    warn $config{html};

    my $tree = HTML::TreeBuilder->new_from_file($config{html}) 
	or die "cannot open HTML file $config{file}: $!";

    $tree->ignore_ignorable_whitespace(0);

    $self->{tree}     = $tree;

#    warn 'making page obj';

    $self->{page_object} = $self->make_page_obj(\%config);

    $self->{visitor}  = \&HTML::Seamstress::cvisitor;
    $self->{code}     = [];

    $self->visit($tree->root);

#    warn Dumper($self->{page_object}) ;

    print "use HTML::TreeBuilder;\n";
    use Cwd;
    my $dir = getcwd;

    if ($config{using}) {
      print "use lib '$dir';\n";
      print "use $config{using};\n" ;
      print " my \$s = $config{using}->new;\n" ;
    }
    print 'my $tree = ';

    my @dump = split /\s+/, Dumper($tree);
    my $dump = join "", splice @dump, 2;

    print "$dump\n";

#    warn "Page Object Code: ", Dumper($self->{page_object}{code}) ;

    map { 
	if ($_->{addr} eq '0.1.1.1.0') {
#	    warn "** 0.1.1.1.0 code blessing: ", ref($_->{code});
#	    warn "** code -> ", $_->{code}->() ;
	}
	print $_->{code}->() ;
    } @{$self->{page_object}{code}} ;
#    warn Data::Dumper::Dumper($self->{page_object}{storable});

}


# nothing but a quick visit everywhere
sub simple_visit {

    my ($self,$node) = @_; # self is an HTML::TreeBuilder object
    my $is_end_tag;

    if (not ref $node) {
	print $node;
    } else {
#	warn "open at", $node->starttag;
	my @children = $node->content_list;
#	warn "children: @children";
	$self->visit($_) for @children;
#	warn "close at", $node->endtag;
    }

}

sub visit {

    my ($self,$node) = @_; # self is parse tree
    my $rv;

#    warn "current_node: $node";

    my $is_end_tag = 0; # kill compiler warning
    $rv = $self->{visitor}->($self->{page_object},$node,$is_end_tag);
#	warn sprintf "%s OPEN rv: %d", $node->starttag, $rv;

    my $RV;
    if (ref($rv) eq 'Set::Array') {
	$RV = scalar @$rv;
    }
#    warn "ref node: ", ref($node);
    if (ref($node) and ($RV or $rv)) {
	my @children = $node->content_list;
	$self->visit($_) for @children;

	$is_end_tag = 1;
	$rv = $self->{visitor}->($self->{page_object},$node,$is_end_tag);
#	    warn sprintf "%s CLOSE rv: %d", $node->endtag, $rv;
	$self->visit($node) if $rv;
    } 
}

sub proc_supply {
    my ($supply, $s, $node, $is_end_tag) = @_;

    if ($is_end_tag) { print $node->endtag; return 0; }

    my $retval = eval $supply;
    die "eval of $supply failed: $@" if ($@);
	
    if (not $is_end_tag) { print $node->starttag }

    return $retval;
}

sub proc_iterator {
    my ($iterator, $s, $node, $is_end_tag) = @_;

    if ($is_end_tag) { print $node->endtag; return 1; }

    my $retval = eval $iterator;
    die "eval of $iterator failed: $@" if ($@);
    
#    warn "eval of iterator: ", Data::Dumper::Dumper($retval);
 
    if (not $is_end_tag) { print $node->starttag }

    return $retval;
}

sub proc_worker {
    my ($worker, $s, $node, $is_end_tag) = @_;

    if ($is_end_tag) { print $node->endtag; return 0; }

    $s->{node} = $node;

    my $retval = eval $worker;
    die "eval of $worker failed: $@" if ($@);
	
    if (not $is_end_tag) { print $node->starttag }

    return $retval;
}

sub visitor {

    my ($object, $node, $is_end_tag) = @_;
    
    # For text nodes, simply emit the text as-is and return.
    if (not ref $node) {
	print $node;
	return 1;
    }

#    warn sprintf "SUPPLY_ATTR (%s): $supply_attr", $node->attr('class');
    if ($node->attr('class') eq $supply_attr) {
	my $supply = $node->attr('id');
	my $tmp = proc_supply($supply, $object, $node, $is_end_tag);
#	warn "SUPPLY: ", Data::Dumper::Dumper($tmp);
	$object->{supply} = $tmp;
	return  $tmp;
    }

    if ($node->attr('class') eq $iterator_attr) {
	my $iterator = $node->attr('id');
#	warn "it : $iterator";
	my $tmp = proc_iterator($iterator, $object, $node, $is_end_tag);
	$object->{iterator} = $tmp;
#	warn "ITERATOR: ", Data::Dumper::Dumper($tmp);
	return $tmp;
    }

    if ($node->attr('class') eq $worker_attr) {
	my $worker = $node->attr('id');
#	warn "wrk : $worker";
	my $tmp = proc_worker($worker, $object, $node, $is_end_tag);
	$object->{worker} = $tmp;
#	warn "worker rets: ", Data::Dumper::Dumper($tmp);
	return $tmp;
    }


    if ($is_end_tag) {
	print $node->endtag;
	return 0;
    } else {
	print $node->starttag;
	return 1;
    }
}

sub bean_store {
    my ($object, $code, $node) = @_;

    my $address = ref($node) ? $node->address : 'none-plaintext' ;

#    warn "pushing $code";

    push @{$object->{code}}, {
	code => $code,
	node => $node,
	addr => $address
	};
}

sub cvisitor {

    my ($object, $node, $is_end_tag) = @_;
    
    # For text nodes, simply emit the text as-is and return.
    if (not ref $node) {
	my $code =<<"EOT";
	    print q{$node};
EOT
    my @caller = caller;
	bean_store $object, (bless sub { $code }, $plaintext_attr), $node;
	return 1;
    }

    if ($node->attr('class') eq $supply_attr and not $is_end_tag) {
	my $supply = $node->attr('id');
	my $code =<<"EOT";
	if (\$s->{supply} = $supply) {
EOT
    bean_store $object, (bless sub { $code }, $supply_attr), $node;
    }

    if (not $is_end_tag and $node->attr('class') eq $iterator_attr) {
	my $iterator = $node->attr('id');
	my $code =<<"EOT";
	{
	    last unless (\$s->{iterator} = $iterator);
EOT
    bean_store $object, (bless sub { $code } , $iterator_attr), $node;
    }

    if ($node->attr('class') eq $worker_attr) {
	my $worker = $node->attr('id');
	my $node_code = 
	    sprintf '$s->{node} = $tree->address("%s")', $node->address;
	my $code =<<"EOT";
	$node_code;
	$worker;
	print \$s->{node}->as_HTML;
EOT
    if (not $is_end_tag) {
	bean_store $object, (bless sub { $code } , $worker_attr), $node;
	return 1;
    } else {
	return 0;
    }
	
    }


    if ($is_end_tag) {
	my $endtag = $node->endtag;

	my $code =<<"EOT";
	    print q{$endtag};
EOT
    $code .= "\n} # end supply tag" if ($node->attr('class') eq $supply_attr);
    $code .= "redo\n} # end iterator tag" if ($node->attr('class') eq $iterator_attr);

    bean_store $object, (bless sub { $code } , $endtag_attr), $node;
	return 0;
    } else {
	my $starttag = $node->starttag;
	my $code =<<"EOT";
	print q{$starttag};
EOT
    bean_store $object, (bless sub { $code } , $starttag_attr), $node;
	return 1;
    }
}


1;

=head1 NAME

HTML::Seamstress - dynamic HTML generation via pure HTML and pure Perl.

=head1 SYNOPSIS
  
  # HTML
  <html>

  # supply element automatically binds $s->{supply}
  <table class=supply id="$s->_aref($s->load_data)">

    <tr>  <th>name<th>age<th>weight</th> </tr>

    # iterator element automatically binds $s->{iterator}
    <tr class=iterator id="$s->{supply}->shift">

        <td class=worker id="$s->_text($s->{iterator}->{name})">    </td>
        <td class=worker id="$s->_text($s->{iterator}->{age})">     </td>
        <td class=worker id="$s->_text($s->{iterator}->{weight})">  </td>

   </tr>

  </table>

 </html>

  # Perl call to generate HTML
  use HTML::Seamstress;
  HTML::Seamstress->weave(html => 'simple.html', using => 'Simple::Class');

  # Perl call to generate a Perl program, which when run, generates HTML
  use HTML::Seamstress;
  HTML::Seamstress->compile(html => 'simple.html', using => 'Simple::Class');

  # Simple/Class.pm
 package simple;

 use base qw(HTML::Stitchery);

 my @name   = qw(bob bill brian babette bobo bix);
 my @age    = qw(99  12   44    52      12   43);
 my @weight = qw(99  52   80   124     120  230);


 sub new {
    my $this = shift;
    bless {}, ref($this) || $this;
 }


 sub load_data {
    my @data;

    for (0 .. 5) {
	push @data, { 
	    age    => $age[rand $#age] + int rand 20,
	    name   => shift @name,
	    weight => $weight[rand $#weight] + int rand 40
	    }
    }

    return \@data;
 }

 1;

=head1 DESCRIPTION

=head2 Disclaimer One - THIS IS ALPHA SOFTWARE. USE AT YOUR OWN RISK

=head2 Disclaimer Two - This package is (too?) similar to HTML::Template

=head2 On to the description

C<HTML::Seamstress> allows webpages to be built by
serving as the bridge between experts in their respective pure
technologies: HTML experts do their thing, object-oriented Perl
experts do their thing and C<HTML::Seamstress> serves to weave the two
together, traversing the pure HTML and making use of the output of
Perl objects at various points in the traversal. 

Its distinctive feature, unlike existing techniques,
is that it uses I<pure>, standard HTML files:
no print-statement-laden CGI scripts,
no embedded statements from some programming langauge,
and no pseudo-HTML elements.
Code is cleanly separated into a separate file.
What links the two together are semantic attributes (CLASS and ID)
for HTML elements.

In model-view-controller terms, the HTML is the view. Seamstress is
the controller, making calls to view-agnostic 
Perl methods to retrieve model data
for inclusion in the view. 

In C<HTML::Seamstress> the model classes are completely view and
controller independant, and are thus use-able outside of HTML and most
importantly, unit-testable outside of Perl.

Seamstress knows what Perl methods to call and when by the looking up
CLASS attributes within a tag that are special to it. The attributes are
C<supply>, C<iterator>, and C<worker> tags. The C<id> tag is used for Perl
code.

=over 4

=item * A C<worker> class is used when actual "work" is going to
be done on the HTML file. This work is usually simple such as
C<_text>, which sets the content aspect of the C<HTML::Element> to
some text.  The others are listed in the manpage for
C<HTML::Stitchery>.

=item * A C<supply> class is called for side-effect. It creates a
store of data for use by C<iterator> and C<worker> tags. Note that
this creation may be actual or via a Perl C<tie>. C<HTML::Seamstress>
automatically stores the results of C<supply> attribute evaluation in
the page object under C<$s->{supply}> for later reference.

=item * An C<iterator> class is used to pull records from a
C<supply> store previously created. C<HTML::Seamstress>
automatically stores the results of C<iterator> attribute evaluation in
the page object under C<$s->{iterator}> for later reference.

=back


=head2 Companion modules

C<HTML::Seamstress> has one simple job as described above. A number of
other modules, work to make this a complete suite for other HTML-based
tasks:

=over 4

=item * C<HTML::Stitchery> provides a number of useful "stitches" to
be automatically woven into HTML files. These stitches are nothing
more than object methods. For practical examples of many common
dynamic HTML generation tasks such as dynamic table generation,
language localization, database connectivity, conditional HTML, and so
forth see its documentation. But in doing so, note well that all of
the above tasks are implemented as Perl object methods and incur the
minal class attribute adulteration of the HTML. In fact, the actual
attribute to be used can be configured by setting C<$worker_attr>, 
C<$supply_attr>, C<$iterator_attr> in C<HTML::Seamstress>.

=item * C<CGI::Seamstress> is a derived class of C<HTML::Seamstress>,
C<HTML::Stitchery > and C<CGI.pm>. All capabilities of each of these
individual technologies are offered to the programmer while placing no
burden on the HTML designer. It, ahem, isn't written yet. But it does
sound good and orthogonal, doesn't it? :)

=item * C<Apache::Seamstress> is a derived class of
C<HTML::Seamstress>, C<HTML::Stitchery>, C<CGI.pm>, and
C<Apache::Request>. And it isn't written yet either. Sigh. I don't think it 
should be actually. A better way to seamless support both CGI and mod_perl
is via C<Apache::Registry>


=head1 Sample usage of HTML::Seamstress

The C<t/> directory of _HTML::Stitchery_ (not HTML::Seamstress)
contains a large number of examples. Further examples are in the
CGI::Seamstress and Apache::Seamstress directories. 

This, and other small snippets of documentation are taken from Paul
J. Lucas' HTML Tree distribution
(http://homepage.mac.com/pauljlucas/software/html_tree), which
CC<HTML::Seamstress> was based on but changed due to experience.


=head2 The HTML File

The file for a web page is in pure HTML.
(It can also contain JavaScript code,
but that's irrelevant for the purpose of this discussion.)
At every location in the HTML file where something is to happen dynamically,
an HTML element must contain a C<CLASS> attribute
(and perhaps some "dummy" content).
(The dummy content allows the web page designer to create a mock-up page.)

For example,
suppose the options in a menu are to be retrieved from a relational database,
say the flavors available on an ice cream shop's web site.
The HTML would look like this:

    <SELECT NAME="Flavors" SUPPLY="$s->query_flavors">
      <SPAN CLASS=ITERATOR id="$s->{supply}->next_flavor">
        <OPTION CLASS=WORKER id="$s->_text($s->{iterator}->{flavor}" VALUE="0">
             Tooty Fruity
        </OPTION>
      </SPAN>
    </SELECT>

C<query_flavors> , C<next_flavor>, and the worker
will be used to generate HTML dynamically.
The values of the C<attributes> attributes can be any Perl code
as long as they agree with those in the code file
(specified later).The text "Tooty Fruity" is dummy content.

The C<query_flavors> C<SUPPLY> will be used
to perform the query from the database;
C<next_flavor> will be used to
fetch every tuple returned from the query
and to substitute the name and ID number of the flavor.

=head2 The Code File

The associated code file in Perl in specified via the C<weave>
configuration option of C<HTML::Seamstress>.

The implementation of the C<query_flavors()> and C<next_flavor()> methods
shall be presented in stages.

The C<query_flavors()> method begins by getting its arguments
as described above:

    sub query_flavors {
        my $this = shift;

A copy of the database and statement handles is stored in the object's hash
so the C<next_flavor()> method can access them later:

        $this->{ dbh } = DBI->connect( 'DBI:mysql:ice_cream:localhost' );
        $this->{ sth } = $this->{ dbh }->prepare( '
            SELECT   flavor_id, flavor_name
            FROM     flavors
            ORDER BY flavor_name
        ' );
        $this->{ sth }->execute();


Finally, the method returns true to tell C<HTML::Seamstress> 
to proceed with parsing the C<SELECT> element's child elements if any
rows were returned from the query.

        return $this->{sth}->rows;
    }



The C<next_flavor()> method begins identically to C<query_flavors()>:

    sub next_flavor {
        my $this = shift;

The next portion of code fetches a tuple from the database.
If there are no more tuples,
the method returns false.
This tells C<HTML::Seamstress> not to emit the HTML for the C<OPTION> element
and also tells it to stop looping:

        my( $flavor_id, $flavor_name ) = $this->{ sth }->fetchrow();
        unless ( $flavor_id ) {
            $this->{ sth }->finish();
            $this->{ dbh }->disconnect();
            return 0;
        }



The code also disconnects from the database.
(However, if C<Apache::DBI> was specified, and we are running mod_perl, then
the C<disconnect()> becomes a no-op
and the connection remains persistent.)

Finally, the method returns true to tell C<HTML::Seamstress>
to emit the HTML for the C<OPTION> element
now containing the dynamically generated content:
	return	$flavor_name;

    }


 1;

=head1 Things you may be wondering

=head2 Where is the if-then-else tag?

There is no if-then-else tag. That functionality occurs implicitly. When
a portion of the HTML document is bracketed by a tag whose C<class> is
C<supply> and that tag's C<id> when evaluated returns a Perl false value,
then that tag, and the entire HTML subtree under it are not placed in 
the output document.

This is what an if statement does

Also note, some cases of if-then-else are better handled by doing 
if-then-else in your CGI program and then issuing a redirect to one
of several appropriate pages instead of spaghetti'ing the hell out of
one document with a maelstrom of if-then-elses. 

=head2 Where is the loop tag?

Again there isn't one. The combination of C<supply> and C<iterator> serves
as a basic general purpose loop. In fact, if you look at the compiled 
code, you will see something like this:
 {
   last unless $page->{iterator}->()
   ...

   redo;
 } 

which is the most general Perl loop available.

=head2 Where is the include file tag?

There isn't one. I insist of using HTML reuse via HTML design programs.
Seamstress believes that a quality HTML designer can do quality things
with a quality program and library element re-use is one of those things.

=head1 Closely related software products

=head2 HTML::Template

I consider this package to be to be HTML::Template's little brother. 
HTML::Template is more mature than this and also has excellent 
and flexible caching technology built in. Both modules believe that 
very little logic should exist in HTML files. 

So why continue with it if the packages are similar in philosophy and 
HTML::Template is well designed and debugged? For me, the answer is manyfold:

=over 4

=item * HTML::Template is already showing signs that its restrictive
variable-only approach is somewhat weak

Note the recent creation of HTML::Template::Expr. And note that you are
moving into "3rd technology" (ie. something other than pure Perl and pure 
HTML) realm with this and you must learn it's new rules and exceptions.

In fact, HTML::Template itself requires you to learn a number of 
pseudo-HTML operators and then learn how to convert pure model code to
a hashref for use by them.

With Seamstress, if you know Perl and simply add CLASS and ID tags
in the HTML tags where you want dynamic expansion you are finished. 

=item * Because the templating instructions are within the HTML tags themselves
the page will always be cleaner than an HTML::Template page

The comparative example below will show this.

=item * HTML::Seamstress can compile its templated documents into pure Perl

This is useful for fast execution in CGI or mod_perl.

=back

Let's write a sample piece
of code in both HTML::Template and HTML::Seamstress.


 <HTML>
  <HEAD><TITLE>Test Template</TITLE>
  <BODY>
  My Home Directory is <TMPL_VAR NAME=HOME>
  <P>
  My Path is set to <TMPL_VAR NAME=PATH>
  </BODY>
  </HTML>

 <HTML>
  <HEAD><TITLE>Test Template</TITLE>
  <BODY>
    My Home Directory is <SPAN CLASS=worker id="$s->_text($ENV{HOME}")> </SPAN>
  <P>
    My Path is set to <SPAN CLASS=worker id="$s->_text($ENV{PATH}")> </SPAN>
  </BODY>
  </HTML>

Hmm, the HTML::Template code is cleaner. Let's try something harder. I have
to win this argument. :-)

 <TMPL_LOOP NAME="THIS_LOOP">
  Word: <TMPL_VAR NAME="WORD"><BR>
  Number: <TMPL_VAR NAME="NUMBER"><P>
   </TMPL_LOOP>

 <span class=supply id="$s->{this_loop}">
    <span class=iterator id="$s->{supply}->Next"> # next via Set::Array method
     Word: <br class=worker id="$s->_text($s->{iterator}{word})"></br>
     Numb: <br class=worker id="$s->_text($s->{iterator}{number})"></br>
    </span>
 </spna>




=head2 How this software differs from Paul J. Lucas' HTML_Tree 

In concept, Seamstress and Lucas' HTML_Tree (call it ltree) are the
same, with Seamstress being developed after usage of ltree. However,
there are some technical differences between the packages:

=over 4

=item * C<HTML::Seamstress>  parses the HTML using SBURKE's HTML::Tree
distribution. SBURKE's HTML parser is written in C and Paul Lucas'
HTML parser is written in C++, so they are both fast.

=item * in ltree, a .pm file must be associated with your HTML file 
and you must write your own constructor. 

Both of these steps are
optional with C<HTML::Seamstress>. You can always inherit the
C<HTML::Stitchery> constructor if you want and if you have an HTML
file that you don't want C<HTML::Seamstress> dhtml in, then you don't
have to have a dummy .pm file, simply omit the C<using> argument to
HTML::Seamstress' C<weave> method... actually at the moment I require
a file a well, but this restriction and automatic common page objects
will be made available in a later version.

=item * method lookups in ltree are done through two mechanisms: a hash
called C<%function_map>: 

   % function_map = (  href_id => \&sub_href_id , .... ) ;

and the C<class_map> attribute of your required constructor in your
required .pm file.

C<HTML::Seamstress> simply relies on Perl object-oriented single
dispatch. But it could do multiple-dispatch as well.

=item * each object method had to do its own argument splitting in
ltree:
    
   # ltree example - note API is slightly different too
   sub sub_href_id { 
      my ($this, $node, $class_arg, $is_end_tag) = @_; 
      my ($method, @arg) = split '::', $class_arg;

Because C<HTML::Seamstress> uses pure Perl in the attributes as
opposed to a pseudo-HTML-like language, it does not have to do
argument splitting but lets Perl handle that.

=item * ltree does not support traversal of infinite levels of
reference nesting. 

Instead it has a simple text() method which returns
the key in the hash of its arguments. Because C<HTML::Seamstress> uses
Perl, arbitrary degrees of nesting of hashes, arrays, as well as
method overloads could be supported. 


=head1 AUTHOR

T. M. Brannon <tbone@cpan.org>

=head1 SEE ALSO

=over 4

=item * Paul J. Lucas' HTML Tree distribution

(http://homepage.mac.com/pauljlucas/software/html_tree) 

=item * XMLC

This is a Java framework with the exact same HTML pages. It creates
DOM object files and works on HTML, XHTML and XML

  http://xmlc.enhydra.org/

=item * HTML Tidy

The demo programs tidy up their HTML output via this program:

 http://www.w3.org/People/Raggett/tidy/

=back



=cut
