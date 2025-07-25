<div align="center">

# asdf-superdb [![Build](https://github.com/chrismo/asdf-superdb/actions/workflows/build.yml/badge.svg)](https://github.com/chrismo/asdf-superdb/actions/workflows/build.yml) [![Lint](https://github.com/chrismo/asdf-superdb/actions/workflows/lint.yml/badge.svg)](https://github.com/chrismo/asdf-superdb/actions/workflows/lint.yml)

[SuperDB](https://superdb.org/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [About](#about)
- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# About

[SuperDB](https://superdb.org/) is currently in pre-release and has no official
tags or versioned releases. Since it is introducing breaking changes from its
predecessor [zq](https://zed.brimdata.io/docs/commands/zq) as development
proceeds, early adopters may want to manage installed versions, and this plugin
allows that to happen.

Pseudo-versions are defined in this plugin by assigning a timestamped version to
the latest sha on the listed date. The timestamp is: `(last digit of the
year)(mm)(dd)`.

```text
  Version  Sha
  -------  ---
  0.50529  c8cc05e6
  0.50630  f86de86d
```

The full list is here: [versions.txt](scripts/versions.txt) and will be updated
roughly once a month. If there's a specific version you'd like included, please
submit a PR.

`asdf` always allows you to install by ref as well:

```shell
asdf install superdb ref:aabbccdd00
# or
asdf install superdb ref:(branch|tag|sha)
```

`super` binaries are built using `go install` direct from the
[repository](https://github.com/brimdata/super). This plugin expects the
resulting binary to be in `$GOBIN` or `$GOPATH/bin` which should be established
if you're using a recent version of Go. If you run into problems let us know.

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `go` (for building from source). See [Go asdf plugin](https://github.com/asdf-community/asdf-golang?tab=readme-ov-file#install).

# Install

Plugin:

This plugin is new and not stable, so it is not registered with
https://github.com/asdf-vm/asdf-plugins yet.

```shell
asdf plugin add superdb https://github.com/chrismo/asdf-superdb.git
```

superdb:

```shell
# asdf version 0.16.0 or later

# Show all installable versions
asdf list all superdb

# Install specific version
asdf install superdb latest

# Set a version globally (on your ~/.tool-versions file)
asdf set --home superdb latest

# Now superdb commands are available
super --version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install and manage versions.

# Contributing

Contributions of any kind are welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/chrismo/asdf-superdb/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [chrismo](https://github.com/chrismo/)
