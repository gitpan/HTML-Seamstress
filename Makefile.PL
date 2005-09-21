#use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Seamstress',
    'VERSION_FROM'	=> 'lib/HTML/Seamstress.pm', # finds $VERSION
    'PREREQ_PM'		=> 
	      {
	       AppConfig::Std => 1.07,
	       File::Slurp => 9999.06,
	       HTML::Element::Library => 0.01,
	       HTML::PrettyPrinter => 0.03,
	       HTML::Tree => 3.18,
	       Pod::Usage => 1.16,
	      }, 
);
