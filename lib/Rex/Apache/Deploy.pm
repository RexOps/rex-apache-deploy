#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

package Rex::Apache::Deploy;

use strict;
use warnings;

use Rex::Commands::Run;
use Rex::Commands::Fs;
use Rex::Commands::Upload;

our $VERSION = '0.1';

require Exporter;
use base qw(Exporter);

use vars qw(@EXPORT $real_name_from_template $deploy_to $document_root $generate_deploy_directory $template_file $template_pattern);
@EXPORT = qw(inject deploy generate_real_name deploy_to generate_deploy_directory document_root template_file template_search_for);

sub generate_real_name {
   $real_name_from_template = shift;
}

sub template_file {
   $template_file = shift;
}

sub template_search_for {
   $template_pattern = shift;
}

sub inject {
   my ($to) = @_;

   my $cmd1 = sprintf (_get_extract_command($to), $to);
   my $cmd2 = sprintf (_get_pack_command($to), $to, ".");

   my $template_params = _get_template_params($template_file);

   mkdir("tmp");
   chdir("tmp");
   run $cmd1;

   for my $file (`find . -name $template_pattern`) {
      my $content = eval { local(@ARGV, $/) = ($file); $_=<>; $_; };
      for my $key (keys %$template_params) {
         my $val = $template_params->{$key};
         $content =~ s/\@$key\@/$val/g;
         my $new_file_name = &$real_name_from_template($file);

         open(my $fh, ">", $new_file_name) or die($!);
         print $fh $content;
         close($fh);
      }
   }

   run $cmd2;
   chdir("..");
   system("rm -rf tmp");
}

sub deploy_to {
   $deploy_to = shift;
}

sub document_root {
   $document_root = shift;
}

sub generate_deploy_directory {
   $generate_deploy_directory = shift;
}

sub deploy {
   my ($file) = @_;

   no strict;
   no warnings;
   my $rnd_file = get_random(8, a..z, 0..9);
   use strict;
   use warnings;

   upload ($file, "/tmp/$rnd_file" . _get_ext($file));

   my $deploy_dir = "$deploy_to/" . &$generate_deploy_directory($file);
   mkd $deploy_dir;

   run "cd $deploy_dir; " . sprintf(_get_extract_command($rnd_file), "/tmp/$rnd_file" . _get_ext($file));
}

sub _get_extract_command {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return "tar xzf %s";
   } elsif($file =~ m/\.zip$/) {
      return "unzip %s";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return "tar xjf %s";
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
   }

   die("Unknown Archive Format.");
}

sub _get_template_params {
   my ($template_file) = @_;
   my @lines = eval { local(@ARGV, $/) = ($template_file); <>; };
   my $r = {};
   for my $line (@lines) {
      my ($key, $val) = ($line =~ m/^(.*?) ?= ?(.*)$/);
      $val =~ s/^["']//;
      $val =~ s/["']$//;
      $r->{$key} = $val;
   }

   $r;
}

sub _get_ext {
   my ($file) = @_;

   if($file =~ m/\.tar\.gz$/) {
      return ".tar.gz";
   } elsif($file =~ m/\.zip$/) {
      return ".zip";
   } elsif($file =~ m/\.tar\.bz2$/) {
      return ".tar.bz2";
   }

   die("Unknown Archive Format.");

}


1;
