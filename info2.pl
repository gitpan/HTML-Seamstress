#!/Users/metaperl/install/bin/perl

use CGI;
use Data::Dumper;
use base qw(HTML::Seamstress);

my $q = CGI->new;
my $html = "/sw/share/httpd/htdocs/info-tidy.html";

print $q->header;

__PACKAGE__->weave(html => $html) and exit unless ($q->param('review'));

require Data::FormValidator;

my $i = {
    required => [qw(first_name email)],
    optional => [qw(last_name phone_number comments)],
    constraints => { email => 'email' }
    };
my $v = Data::FormValidator->new($i);
my $vars = $q->Vars;

my ($valid, $missing, $invalid, $unknown) = 
    $v->validate($vars, $i);

warn "dfv_results", Dumper($valid, $missing, $invalid, $unknown);

warn "calling with inject!";

my %m = map { $_ => 1 } @$missing;
my %i = map { $_ => 1 } @$invalid;

__PACKAGE__->weave(html      => $html, 
		   injecting => 
		   { 
		    review => { 
			       missing => \%m,
			       invalid => \%i
			      },
		    vars    => $vars
		   }
		  );

