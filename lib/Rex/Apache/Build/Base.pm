#
# (c) Jan Gehring <jan.gehring@gmail.com>
# 
# vim: set ts=3 sw=3 tw=0:
# vim: set expandtab:
   
package Rex::Apache::Build::Base;

use strict;
use warnings;

sub new {
   my $that = shift;
   my $proto = ref($that) || $that;
   my $self = { @_ };

   $self->{maintainer}  ||= ($ENV{USER} || "unknown");
   $self->{section}     ||= "none";
   $self->{url}         ||= "http://example.tld/";
   $self->{description} ||= "No Description";

   bless($self, $proto);

   return $self;
}

for my $name (qw/
                  path
                  prefix
                  release
                  epoch
                  version
                  vendor
                  license
                  category
                  depends
                  conflicts
                  provides
                  arch
                  description
                  section
                  url
                  postinstall
                  preinstall
                  postuninstall
                  preuninstall
                  exclude
                  maintainer
                  priority
                  name
                /) {
   no strict 'refs';
   *{__PACKAGE__ . "::$name"} = sub {
      my ($self, $data) = @_;

      if($data) {
         $self->{$name} = $data;
      }

      $self->{$name};

   };
   use strict;
}

sub build {
   my ($self, $target) = @_;
   die("Must be implemented by Class.");
}

1;
