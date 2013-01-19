#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Deploy::Git;

use strict;
use warnings;

use Rex -base;

use vars qw(@EXPORT);
@EXPORT = qw(deploy switch_to_version);

sub deploy {
   my ($commit, %option) = @_;

   if(! %option) {
      if(Rex::Config->get("package_option")) {
         %option = %{ Rex::Config->get("package_option") };
      }
   }

   my $commit_to_deploy = $commit;
   my $repo_path        = $option{path};
   my $force            = ($option{force}?"-f":"");
   my $switch           = $option{switch};

   run "git init $repo_path";
   run "GIT_DIR=$repo_path/.git git config receive.denyCurrentBranch ignore";

   my $server = connection->server;
   my $user   = $option{user} || Rex::Config->get_user;

   LOCAL {
      run "git push git+ssh://$user\@$server$repo_path $commit_to_deploy:refs/heads/master $force";

      if($? != 0) {
         die("Error pushing refs.");
      }
   };

   if($switch) {
      switch_to_version($commit_to_deploy, %option);
   }
}

sub switch_to_version {
   my ($version, %option) = @_;

   my $repo_path = $option{path};

   run "cd $repo_path && git reset --hard $version";

   if($? != 0) {
      die("Error switching to $version");
   }
}

sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"$_[1]::$func"} = \&$func;
   }

}

1;
