%define pgsql_pkgver   %(echo %{pgsql_version} | sed 's/\\.//g')

Name: pg-strom-PG%{pgsql_pkgver}
Version: %{strom_version}
Release: %{strom_release}%{?dist}
Summary: PG-Strom extension module for PostgreSQL
Group: Applications/Databases
License: GPL 2.0
URL: https://github.com/heterodb/pg-strom
Source0: %{strom_tarball}.tar.gz
BuildRequires: postgresql%{pgsql_pkgver}        >= 9.6.0
BuildRequires: postgresql%{pgsql_pkgver}-devel  >= 9.6.0
BuildRequires: cuda                             >= 8.0
Requires: nvidia-kmod
Requires: cuda                                  >= 8.0
Requires: postgresql%{pgsql_pkgver}
Requires: postgresql%{pgsql_pkgver}-server
BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root

%define __pg_config     /usr/pgsql-%{pgsql_version}/bin/pg_config
%define __pkglibdir     %(%{__pg_config} --pkglibdir)
%define __pkgbindir     %(%{__pg_config} --bindir)
%define __pkgsharedir   %(%{__pg_config} --sharedir)
%define __cuda_path     /usr/local/cuda

%description
PG-Strom is an extension for PostgreSQL, to accelerate analytic queries
towards large data set using the capability of GPU devices.

%prep
%setup -q -n %{strom_tarball}

%build
rm -rf %{buildroot}
%{__make} -j 8 CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config}
echo %{__cuda_path}/lib64 > pgstrom-cuda-lib64.conf

%install
rm -rf %{buildroot}
%{__make} CUDA_PATH=%{__cuda_path} PG_CONFIG=%{__pg_config} DESTDIR=%{buildroot} install

# config to use CUDA/NVRTC
%{__install} -Dp pgstrom-cuda-lib64.conf %{buildroot}/etc/ld.so.conf.d/pgstrom-cuda-lib64.conf

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
%config(noreplace) /etc/ld.so.conf.d/pgstrom-cuda-lib64.conf

%changelog
* Sat Jan 20 2018 KaiGai Kohei <kaigai@heterodb.com>
- initial RPM specfile
