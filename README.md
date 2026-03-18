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

This plugin downloads prebuilt binaries from
[SuperDB releases](https://github.com/chrismo/superdb-builds/releases). If a
prebuilt binary is not available for your platform, the plugin will fall back
to building from source using `go install`.

`asdf` also allows you to install by ref:

```shell
asdf install superdb ref:aabbccdd00
# or
asdf install superdb ref:(branch|tag|sha)
```

When building from source, the plugin expects the resulting binary to be in
`$GOBIN` or `$GOPATH/bin` which should be established if you're using a recent
version of Go. If you run into problems let us know.

# Dependencies

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `go` (only needed if building from source). See [Go asdf plugin](https://github.com/asdf-community/asdf-golang?tab=readme-ov-file#install).

# Install

Plugin:

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
