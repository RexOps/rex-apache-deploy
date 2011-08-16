#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:

=head1 NAME

Rex::Apache::Build - Build your WebApp Package

=head1 DESCRIPTION

With this module you can prepare your WebApp for deployment.

=head1 SYNOPSIS

 yui_path "./yuicompressor-2.4.6.jar";
     
 get_version_from "webapp/lib/MyApp.pm", qr{\$VERSION=([^;]+);};
     
 get_version_from "webapp/index.php", qr{\$VERSION=([^;]+);};
     
 task "build", sub {
    yui compress => "file1.js", "file2.js", "file3.css";
    yui compress => glob("public/javascript/*.js"), glob("public/css/*.css");
         
    build;
        
    build "webapp",
      path => "webapp/",
      version => "1.0";
 };


=head1 EXPORTED FUNCTIONS

=over 4

=cut

   
package Rex::Apache::Build;
   
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename qw(basename);
   
require Exporter;
use base qw(Exporter);
use vars qw(@EXPORT);
    
@EXPORT = qw(yui yui_path build get_version_from get_version coffee sprocketize coffee_path sprocketize_path);

use vars qw($yui_path $coffee_path $sprocketize_path $APP_VERSION);

use Rex::Commands::Run;
use Rex::Logger;

=item yui_path($path_to_yui_compressor)

This function sets the path to the yui_compressor. If a relative path is given it will search from the path where the Rexfile is in.

=cut
sub yui_path {
   ($yui_path) = @_;

   unless($yui_path =~ m/^\//) {
      $yui_path = getcwd() . "/" . $yui_path;
   }
}

=item coffee_path($path_to_coffee)

This function sets the path to the coffee compiler. If a relative path is given it will search from the path where the Rexfile is in.

=cut
sub coffee_path {
   ($coffee_path) = @_;

   unless($coffee_path =~ m/^\//) {
      $coffee_path = getcwd() . "/" . $coffee_path;
   }
}

=item sprocketize_path($path_to_sprocketize)

This function sets the path to the sprocketize compiler. If a relative path is given it will search from the path where the Rexfile is in.

=cut
sub sprocketize_path {
   ($sprocketize_path) = @_;

   unless($sprocketize_path =~ m/^\//) {
      $sprocketize_path = getcwd() . "/" . $sprocketize_path;
   }
}

=item yui($action, @files)

Run a yui command.

 task "build", sub {
    yui compress => "file1.js", "file2.js", ...;
 };

=cut
sub yui {
   my ($action, @data) = @_;

   unless(-f $yui_path) {
      die("No yuicompressor.jar found. Please download this file and define its location with yui_path '/path/to/yuicompress.jar';");
   }

   if($action eq "compress") {
      my @js_files  = grep { ! /\.min\.js$/  } grep { /\.js$/i } @data;
      my @css_files = grep { ! /\.min\.css$/ } grep { /\.css$/i } @data;

      if(@js_files) {
         for my $file (@js_files) {
            my $new_file = $file;
            $new_file    =~ s/\.js$/.min.js/;
            Rex::Logger::debug("Compressing $file -> $new_file");
            run "java -jar $yui_path -o '$new_file' $file";
         }
      }

      if(@css_files) {
         for my $file (@css_files) {
            my $new_file = $file;
            $new_file    =~ s/\.css$/.min.css/;
            Rex::Logger::debug("Compressing $file -> $new_file");
            run "java -jar $yui_path -o '$new_file' $file";
         }
      }
   }
   else {
      die("Action $action not supported.");
   }
}

=item build([$name, %options])

This function builds your package. Currently only tar.gz packages are supported.

 # this will a package of the current directory named after the 
 # directory of the Rexfile and append the version provided by 
 # get_version_from() function
 # This function builds a tar.gz archive.
 task "build", sub {
    build;
 };
    
 # this will build a package of the current directory named "my-web-app" and 
 # append the version provided by get_version_from() function.
 task "build", sub {
    build "my-web-app";
 };
     
 # this function will build a package of the directory "html", name it 
 # "my-web-app" and append the version "1.0" to it.
 task "build", sub {
    build "my-web-app",
       path => "html",
       version => "1.0",
       exclude => ["yuicompressor.jar", "foobar.html"];
 };

=cut
sub build {
   my ($name, %option) = @_;

   unless($name) {
      $name = basename(getcwd());
   }

   my $dir = getcwd();

   if(exists $option{path}) {
      $dir = $option{path};
   }

   my $version = "";

   if($APP_VERSION) {
      $version = "-" . &$APP_VERSION();
   }

   if(exists $option{version}) {
      $version = "-".$option{version};
   }

   my $old_dir = getcwd();
   chdir($dir);

   my $excludes = "";

   if(exists $option{exclude}) {
      $excludes = " --exclude " . join(" --exclude ", @{$option{exclude}});
   }

   run "tar -c $excludes --exclude '$name-*.tar.gz' --exclude '.*.sw*' --exclude '*~' --exclude Rexfile.lock --exclude Rexfile --exclude $name$version.tar.gz -z -f $old_dir/$name$version.tar.gz .\n";
   Rex::Logger::info("Build: $name$version.tar.gz");

   chdir($old_dir);
}

=item get_version_from($file, $regexp)

Get the version out of a file.

=cut
sub get_version_from {
   my ($file, $regex) = @_;

   $APP_VERSION = sub {

      unless(-f $file) {
         die("Version file not found ($file). Current Path: " . getcwd());
      }

      my ($version) = grep { $_=$1 if $_ =~ $regex; } eval { local(@ARGV) = ($file); <>; };
      
      return $version;

   };
}

sub get_version {
   return &$APP_VERSION();
}


=item sprocketize($path_to_js_files, %option)

This function calls the sprocketize command with the given options.

 task "build", sub {
    sprocketize "app/javascript/*.js",
                  include    => [qw|app/javascripts vendor/sprockets/prototype/src|],
                  asset_root => "public/js",
                  outfile    => "public/js/sprockets.js";
         
    # if called without parameters

    sprocketize;

    # it will use the following defaults:
    # - javascript (sprockets) in app/javascripts/*.js
    # - include  app/javascripts
    # - asset_root public
    # - outfile public/$name_of_directory.js
 };

=cut

sub sprocketize {
   my ($files, %option) = @_;

   my $dirname = basename(getcwd());

   unless($sprocketize_path) {
      $sprocketize_path = "sprocketize";
   }

   unless($files) {
      $files = "app/javascripts/*.js";
      $option{include}    = ["app/javascripts"];
      $option{asset_root} = "public";
      $option{outfile}    = "public/$dirname.js";
   }

   my $includes = " -I " . join(" -I ", @{$option{include}});
   run "$sprocketize_path $includes --asset-root=" . $option{asset_root} . " $files > " . $option{outfile};
}

=back

=cut

1;
