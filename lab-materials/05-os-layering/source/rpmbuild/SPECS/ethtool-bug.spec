Name:           ethtool
Version:        99.0
Release:        1%{?dist}
Summary:        Fake ethtool with bug for troubleshooting exercise

License:        GPLv2
URL:            http://example.com/fake-ethtool
BuildArch:      x86_64
ExclusiveArch:  x86_64

Source0:        ethtool

Provides:       ethtool
Conflicts:      ethtool < 99.0

%description
This is a fake/broken ethtool package for troubleshooting purposes.
Whenever you run `ethtool`, it will just print "this is a bug".

%prep
# nothing to prep

%build
# nothing to build

%install
mkdir -p %{buildroot}/usr/sbin
install -m 0755 %{SOURCE0} %{buildroot}/usr/sbin/ethtool

%files
/usr/sbin/ethtool

%changelog
* Sun Aug 17 2025 Troubleshooting Lab - 99.0-1
- Fake ethtool package that only prints "this is a bug"

