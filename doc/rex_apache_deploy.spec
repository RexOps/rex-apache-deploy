%define perl_vendorlib %(eval "`%{__perl} -V:installvendorlib`"; echo $installvendorlib)
%define perl_vendorarch %(eval "`%{__perl} -V:installvendorarch`"; echo $installvendorarch)

%define real_name Rex-Apache-Deploy

Summary: Rex-Apache-Deploy is a (R)?ex Module to deploy Websites.
Name: rex-apache-deploy
Version: 0.10.0
Release: 1
License: Artistic
Group: Utilities/System
Source: http://search.cpan.org/CPAN/authors/id/J/JF/JFRIED/Rex-Apache-Deploy-0.10.0.tar.gz
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

BuildRequires: perl >= 5.8.0
BuildRequires: perl(ExtUtils::MakeMaker)
Requires: rex >= 0.18.0
Requires: perl >= 5.8.0
Requires: perl-libwww-perl
Requires: perl-YAML
Requires: unzip
Requires: zip
Requires: bzip2
Requires: tar
AutoReqProv: no

%description
Rex::Apache::Deploy is a (R)?ex Module to deploy Web sites into Apache 
and WAR-files into Tomcat. It eases the deployment process of many servers.

%prep
%setup -n %{real_name}-%{version}

%build
%{__perl} Makefile.PL INSTALLDIRS="vendor" PREFIX="%{buildroot}%{_prefix}"
%{__make} %{?_smp_mflags}

%install
%{__rm} -rf %{buildroot}
%{__make} pure_install

### Clean up buildroot
find %{buildroot} -name .packlist -exec %{__rm} {} \;


%clean
%{__rm} -rf %{buildroot}

%files
%defattr(-,root,root, 0755)
%doc META.yml 
%doc %{_mandir}/*
%{perl_vendorlib}/*

%changelog

* Tue Aug 21 2012 Jan Gehring <jan.gehring at, gmail.com> 0.10.0-1
- updated package
