#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Inject::Properties;

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
use Cwd qw(getcwd);

#require Exporter;
#use base qw(Exporter);

use vars qw(@EXPORT $real_name_from_template $template_file $template_pattern);
@EXPORT = qw(inject
               generate_real_name
               template_file template_search_for);

my $work_dir = getcwd;

############ deploy functions ################

sub inject {
   my ($to, @options) = @_;

   my $option = { @options };

   my $cmd1 = sprintf (_get_extract_command($to), "../$to");
   my $cmd2 = sprintf (_get_pack_command($to), "../$to", ".");

   my $template_params = _get_template_params($template_file);

   mkdir("tmp");
   chdir("tmp");
   run $cmd1;

   if(exists $option->{"extract"}) {
      for my $file_pattern (@{$option->{"extract"}}) {

         for my $found_file (`find ../ -name '$file_pattern'`) {
            chomp $found_file;

            mkdir "tmp-b";
            chdir "tmp-b";

            my $extract_cmd  = sprintf( _get_extract_command($found_file), "../$found_file" );
            my $compress_cmd = sprintf( _get_pack_command($found_file), "../$found_file", "." );

            run $extract_cmd;

            _find_and_parse_templates();

            if(exists $option->{"pre_pack_hook"}) {
               &{ $option->{"pre_pack_hook"} }($found_file);
            }

            run $compress_cmd;

            if(exists $option->{"post_pack_hook"}) {
               &{ $option->{"post_pack_hook"} }($found_file);
            }

            chdir "..";
            rmdir "tmp-b";
         }

      }
   }

   _find_and_parse_templates();

   if(exists $option->{"pre_pack_hook"}) {
      &{ $option->{"pre_pack_hook"} };
   }

   run $cmd2;

   if(exists $option->{"post_pack_hook"}) {
      &{ $option->{"post_pack_hook"} };
   }

   chdir("..");
   system("rm -rf tmp");
}

sub _find_and_parse_templates {

   my $template_params = _get_template_params($template_file);

   for my $file (`find . -name '$template_pattern'`) {
      chomp $file;
      Rex::Logger::debug("Opening file $file");
      open(my $fh, "<$file") or die($!);
      my %con;
      while (my $line = <$fh>) {
         chomp $line;
         next if($line =~ /^#/);
         next if($line =~ /^$/);

         my ($key, $val) = $line =~ m/^(.*?)=(.*)$/;
         $con{$key} = $val;
      }
      close($fh);

      for my $k (keys %$template_params) {
         if(exists $con{$k}) {
            Rex::Logger::info("setting $k to " . $template_params->{$k} . " ($file)");
            $con{$k} = $template_params->{$k};
         }
      }

      my $new_file_name = $real_name_from_template?&$real_name_from_template($file):$file;
      Rex::Logger::debug("Writing file $new_file_name");
      open($fh, ">", $new_file_name) or die($!);
      for my $key (keys %con) {
         print $fh "$key=" . $con{$key} . "\n";
      }
      close($fh);
   }


}


############ configuration functions #############

sub generate_real_name {
   $real_name_from_template = shift;
}

sub template_file {
   $template_file = shift;
}

sub template_search_for {
   $template_pattern = shift;
}

############ helper functions #############

sub _get_extract_command {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return "tar xzf %s";
   } elsif($file =~ m/\.zip$/) {
      return "unzip %s";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return "tar xjf %s";
   } elsif($file =~ m/\.war$/) {
      return "unzip %s";
   } elsif($file =~ m/\.jar$/) {
      return "unzip %s";
   }

   die("Unknown Archive Format.");
}

sub _get_pack_command {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return "tar czf %s %s";
   } elsif($file =~ m/\.zip$/) {
      return "zip -r %s %s";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return "tar cjf %s %s";
   } elsif($file =~ m/\.war$/) {
      return "zip -r %s %s";
   } elsif($file =~ m/\.jar$/) {
      return "zip -r %s %s";
   }

   die("Unknown Archive Format.");
}

# read the template file and return a hashref.
sub _get_template_params {
   my %inject;
   open(my $fh, "<$work_dir/$template_file") or die($!);
   while (my $line = <$fh>) {
      chomp $line;
      next if($line =~ /^#/);
      next if($line =~ /^$/);

      my ($key, $val) = ($line =~ m/^(.*?)=(.*)$/);
      $inject{$key} = $val;
   }
   close($fh);

   return \%inject;
}

sub _get_ext {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return ".tar.gz";
   } elsif($file =~ m/\.zip$/) {
      return ".zip";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return ".tar.bz2";
   } elsif($file =~ m/\.war$/) {
      return ".war";
   } elsif($file =~ m/\.jar$/) {
      return ".jar";
   }

   die("Unknown Archive Format.");

}

####### import function #######

sub import {

   no strict 'refs';
   for my $func (@EXPORT) {
      Rex::Logger::debug("Registering main::$func");
      *{"$_[1]::$func"} = \&$func;
   }

}



1;
