use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Seamstress',
    'VERSION_FROM'	=> 'lib/HTML/Seamstress.pm', # finds $VERSION
    'PREREQ_PM'		=> {
			    Scalar::Listify => 0.02,
			    Tie::Cycle => 1.06,
			    HTML::Tree => 3.18
			   }, # e.g., Module::Name => 1.1
);
