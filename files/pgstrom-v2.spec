%define PGSQL_PKGVER	%(echo @@PGSQL_VERSION@@ | sed 's/[^0-9]//g')

Name: pg_strom-PG%{PGSQL_PKGVER}
Version: @@STROM_VERSION@@
Release: @@STROM_RELEASE@@%{?dist}
Summary: PG-Strom extension module for PostgreSQL
Group: Applications/Databases
License: GPL 2.0
URL: https://github.com/heterodb/pg-strom
Source0: @@STROM_TARBALL@@.tar.gz
Source1: systemd-pg_strom.conf
BuildRequires: postgresql%{PGSQL_PKGVER}
BuildRequires: postgresql%{PGSQL_PKGVER}-devel
BuildRequires: cuda >= 9.1
Requires: nvidia-kmod
Requires: cuda >= 9.1
%if "%{PGSQL_PKGVER}" == "96"
Requires: postgresql%{PGSQL_PKGVER}-server >= 9.6.9
%else
%if "%{PGSQL_PKGVER}" == "10"
Requires: postgresql%{PGSQL_PKGVER}-server >= 10.4
%else
Requires: postgresql%{PGSQL_PKGVER}-server
%endif
%endif
Obsoletes: nvme_strom < 1.2
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root
AutoReqProv: no

%package test
Summary: PG-Strom related test tools and scripts
Group: Applications/Databases

%define __pg_config     /usr/pgsql-@@PGSQL_VERSION@@/bin/pg_config
%define __pkglibdir     %(%{__pg_config} --pkglibdir)
%define __pkgbindir     %(%{__pg_config} --bindir)
%define __pkgsharedir   %(%{__pg_config} --sharedir)
%define __cuda_path     /usr/local/cuda
%define __systemd_conf  %{_sysconfdir}/systemd/system/postgresql-%{PGSQL_PKGVER}.service.d/pg_strom.conf

%description
PG-Strom is an extension for PostgreSQL, to accelerate analytic queries
towards large data set using the capability of GPU devices.

%description test
This package provides test tools and scripts related to PG-Strom

%prep
%setup -q -n @@STROM_TARBALL@@

%build
rm -rf %{buildroot}
%{__make} -j 8 CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config}

%install
rm -rf %{buildroot}
%{__make} CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config} DESTDIR=%{buildroot} install
%{__install} -Dpm 644 %{SOURCE1} %{buildroot}/%{__systemd_conf}

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
%config %{__systemd_conf}
%if "%{PGSQL_PKGVER}" != "96" && "%{PGSQL_PKGVER}" != "10"
%{__pkglibdir}/bitcode/pg_strom*
%endif

%files test
%{__pkgbindir}/dbgen-dbt3
%{__pkgbindir}/dbgen-ssbm

%changelog
