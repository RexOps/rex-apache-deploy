#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy::Tomcat;

=begin

=head2 SYNOPSIS

This is a (R)?ex module to ease the deployments of PHP, Perl or other languages.

=cut

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;
use Rex::Commands;
use File::Basename qw(dirname basename);
use LWP::UserAgent;

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $context_path);
@EXPORT = qw(deploy context_path);

############ deploy functions ################

sub deploy {

   my ($file, $option) = @_;

   no strict;
   no warnings;
   my $rnd_file = get_random(8, a..z, 0..9);
   use strict;
   use warnings;

   if(! exists $option->{"context_path"}) {
      $option->{"context_path"} = $context_path;
   }

   upload ($file, "/tmp/$rnd_file.war");

   $option->{"file"} = "/tmp/$rnd_file.war";

   # zuerst muss undeployed werden
   _undeploy($option);

   # und dann wieder deployen
   _deploy($option);


   unlink "/tmp/$rnd_file.war";
}

############ helper function ##############

sub _deploy {

   my $p = shift;

   my $current_connection = Rex::get_current_connection();

	my $ua = LWP::UserAgent->new();
   my $resp = $ua->get(_get_url($current_connection->{"server"} . ":" . $p->{'port'},
                                 "deploy?path=" . $p->{"context_path"} . "&war=file:" . $p->{"file"}, 
                                 $p->{"username"}, 
                                 $p->{"password"}));
   if($resp->is_success) {
      Rex::Logger::info($resp->decoded_content);
   } else {
      Rex::Logger::info("FAILURE: " . $current_connection->{"server"} . ": " . $resp->status_line);
   }

}

sub _undeploy {

   my $p = shift;
	
	_do_action("undeploy", 
               $p->{"context_path"},
               $p->{"port"},
               $p->{"username"},
               $p->{"password"});

}

sub _get_url {
	my $server = shift;
	my $command = shift;
   my $user = shift;
   my $pw = shift;
	
	return "http://$user:$pw\@" . "$server/manager/$command";
}


sub _do_action {

   my $action = shift;
	my $path   = shift;
   my $port   = shift;
   my $user   = shift;
   my $pw     = shift;

	my $ua = LWP::UserAgent->new();
   my $current_connection = Rex::get_current_connection();

   my $resp = $ua->get(_get_url($current_connection->{"server"} . ":".$port, "$action?path=$path", $user, $pw));
   if($resp->is_success) {
      Rex::Logger::info($resp->decoded_content);
   } else {
      Rex::Logger::info("FAILURE: " . $current_connection->{"server"} . ":$port:  " . $resp->status_line);
   }

}


############ configuration functions #############

sub context_path {
   $context_path = shift;
}

####### import function #######

sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"main::$func"} = \&$func;
   }

}

1;
