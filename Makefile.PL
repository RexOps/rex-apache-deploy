use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'Rex-Apache-Deploy',
   VERSION_FROM => 'lib/Rex/Apache/Deploy.pm',
   PREREQ_PM => {'Net::SSH2' => '0.1.1'},
   LICENSE => 'perl'
);

