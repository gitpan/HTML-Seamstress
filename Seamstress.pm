package HTML::Seamstress;


# perl core

use Data::Dumper;
use Symbol;

# CPAN


use HTML::Tree;
use Cache::MemoryCache;
use Data::DRef qw(:dref_access);

# pragmas

use 5.006;
use strict;
use warnings;

# version

our $VERSION = '0.01';

# code

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

my %cache_options = ( 'namespace' => $temp_package_prefix,
		      'default_expires_in' => 600 );

my $file_cache = new Cache::MemoryCache( \%cache_options ) or
    croak( "Couldn't instantiate MemoryCache" );

# for an html page, let's create the perl object associated with it:

sub make_page_obj {
    my ($self,$config) = @_;
    my $page = $config->{using};
    my $page_object;
    
    if (!$page) {
#	$page_object = HTML::Stitchery->new(%$config);
	die "NO PAGE... default implementation needed";
    } else {
	if ($page_object = $file_cache->get($page)) {
#	    warn "$page is cached... retrieving ($page_object)";
	    return $page_object;
	} else {
	    my $fh = gensym;
	    die "make_page_obj($page): $!" unless open $fh, $page;
	    my $code = join '', <$fh>;
	    my $temp_package = temp_package;
	    $code =~ s!^\s*package\s+([\w:]+);!package $temp_package;!m;
	    eval $code;
#	    warn "EVAL ",  $code;
	    die sprintf "%s: $@", $page if $@;
	    $page_object = $temp_package->new(%$config);
	    $file_cache->set($page, $page_object) or die "cachestore failed: $!";
	}
    }
    $page_object;
}

# The "constructor", so to speak. 

sub weave {
    
    my ($class, @config) = @_;

    my %config = @config;

    my $self = bless \%config, $class;
    
#    warn $config{html};

    my $tree = HTML::TreeBuilder->new_from_file($config{html}) 
	or die "cannot open HTML file $config{file}: $!";

    $tree->ignore_ignorable_whitespace(0);

    $self->{tree}     = $tree;

    $self->{page_object} = $self->make_page_obj(\%config);

    $self->{visitor}  = \&HTML::Seamstress::visitor;

    $self->visit($tree->root);

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

    if (ref $node) {
	my $is_end_tag = 0; # kill compiler warning
	$rv = $self->{visitor}->($self->{page_object},$node,$is_end_tag);
#	warn sprintf "%s OPEN rv: %d", $node->starttag, $rv;
	if ($rv) {
	    my @children = $node->content_list;
	    $self->visit($_) for @children;

	    $is_end_tag = 1;
	    $rv = $self->{visitor}->($self->{page_object},$node,$is_end_tag);
#	    warn sprintf "%s CLOSE rv: %d", $node->endtag, $rv;
	    $self->visit($node) if $rv;
	} 
    } else {
	print $node;
    }
}

sub proc_args {
    my $this = shift;
    my @ret;
#    warn "proc_args IN: @_";
#  warn sprintf "this cgi: %s", Data::Dumper::Dumper($this->{cgi});
    for my $dref_or_scalar (@_) {
	my $r = get_value_for_dref($this, $dref_or_scalar);
	push @ret, $r and next if $r;
	push @ret, $dref_or_scalar;
    }
#    warn "proc_args OUT: @ret";
    @ret;
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

    if (my $supply = $node->attr($supply_attr)) {
	my $tmp = proc_supply($supply, $object, $node, $is_end_tag);
#	warn "SUPPLY: ", Data::Dumper::Dumper($tmp);
	$object->{supply} = $tmp;
	return  $tmp;
    }

    if (my $iterator = $node->attr($iterator_attr)) {
	warn "it : $iterator";
	my $tmp = proc_iterator($iterator, $object, $node, $is_end_tag);
	$object->{iterator} = $tmp;
#	warn "ITERATOR: ", Data::Dumper::Dumper($tmp);
	return $tmp;
    }

    if (my $worker = $node->attr($worker_attr)) {
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


1;

