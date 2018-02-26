Name: pg_strom-PG@@PGSQL_PKGVER@@
Version: @@STROM_VERSION@@
Release: @@STROM_RELEASE@@%{?dist}
Summary: PG-Strom extension module for PostgreSQL
Group: Applications/Databases
License: GPL 2.0
URL: https://github.com/heterodb/pg-strom
Source0: @@STROM_TARBALL@@.tar.gz
BuildRequires: postgresql@@PGSQL_PKGVER@@       >= 9.6.0
BuildRequires: postgresql@@PGSQL_PKGVER@@-devel  >= 9.6.0
BuildRequires: cuda                             >= 8.0
Requires: nvidia-kmod
Requires: cuda                                  >= 8.0
Requires: postgresql@@PGSQL_PKGVER@@
Requires: postgresql@@PGSQL_PKGVER@@-server
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
AutoReqProv: no

%define __pg_config     /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_config
%define __pkglibdir     %(%{__pg_config} --pkglibdir)
%define __pkgbindir     %(%{__pg_config} --bindir)
%define __pkgsharedir   %(%{__pg_config} --sharedir)
%define __cuda_path     /usr/local/cuda

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
%{__pkgbindir}/kfunc_info
%{__pkgsharedir}/extension/*

%changelog
