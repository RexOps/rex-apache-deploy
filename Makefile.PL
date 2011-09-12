use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-Apache-Deploy',
   VERSION_FROM => 'lib/Rex/Apache/Deploy.pm',
   PREREQ_PM => {'Rex' => '>=0.12.0', 'YAML' => 0, 'LWP::Simple' => 0},
   LICENSE => 'GPLv3'
);

