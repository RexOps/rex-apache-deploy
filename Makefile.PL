use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-Apache-Deploy',
   VERSION_FROM => 'lib/Rex/Apache/Deploy.pm',
   PREREQ_PM => {'Rex' => '0.6.0'},
   LICENSE => 'perl'
);

