use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Seamstress',
    'VERSION_FROM'	=> 'Seamstress.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      { 
	      Cache::Cache => 0.08, HTML::Tree => 3.11,
	      Data::Dref => 0, HTML::Stitchery => 0,
	      HTML::Seamstress::Iterator => 0
	      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Seamstress.pm', # retrieve abstract from module
       AUTHOR     => 'T. M. Brannon <tbone@cpan.org>') : ()),
);
