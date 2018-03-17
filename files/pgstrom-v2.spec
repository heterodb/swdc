Name: pg_strom-PG@@PGSQL_PKGVER@@
Version: @@STROM_VERSION@@
Release: @@STROM_RELEASE@@%{?dist}
Summary: PG-Strom extension module for PostgreSQL
Group: Applications/Databases
License: GPL 2.0
URL: https://github.com/heterodb/pg-strom
Source0: @@STROM_TARBALL@@.tar.gz
Source1: systemd-pg_strom.conf
BuildRequires: postgresql@@PGSQL_PKGVER@@
BuildRequires: postgresql@@PGSQL_PKGVER@@-devel
BuildRequires: cuda >= 9.1
Requires: nvidia-kmod
Requires: cuda >= 9.1
Requires: postgresql@@PGSQL_PKGVER@@
Requires: postgresql@@PGSQL_PKGVER@@-server
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
AutoReqProv: no

%define __pg_config     /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_config
%define __pkglibdir     %(%{__pg_config} --pkglibdir)
%define __pkgbindir     %(%{__pg_config} --bindir)
%define __pkgsharedir   %(%{__pg_config} --sharedir)
%define __cuda_path     /usr/local/cuda
%define __systemd_confdir \
    %{_sysconfdir}/systemd/system/postgresql-@@PGSQL_PKGVER@@.service.d

%description
PG-Strom is an extension for PostgreSQL, to accelerate analytic queries
towards large data set using the capability of GPU devices.

%prep
%setup -q -n @@STROM_TARBALL@@

%build
rm -rf %{buildroot}
%{__make} -j 8 CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config}

%install
rm -rf %{buildroot}
%{__make} CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config} DESTDIR=%{buildroot} install
%{__install} -Dpm 644 %{source1} \
             %{buildroot}/%{__systemd_confdir}/pg_strom.conf

%clean
rm -rf %{buildroot}

%post
ldconfig

%postun
ldconfig

%files
%defattr(-,root,root,-)
%doc LICENSE README.md
%{__pkglibdir}/pg_strom.so
%{__pkgbindir}/gpuinfo
%{__pkgsharedir}/extension/*
%{_sysconfdir}/systemd/system/postgresql-10.service.d/
%{__systemd_confdir}/pg_strom.conf

%changelog
