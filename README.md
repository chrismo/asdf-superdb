<div align="center">

# asdf-superdb [![Build](https://github.com/chrismo/asdf-superdb/actions/workflows/build.yml/badge.svg)](https://github.com/chrismo/asdf-superdb/actions/workflows/build.yml) [![Lint](https://github.com/chrismo/asdf-superdb/actions/workflows/lint.yml/badge.svg)](https://github.com/chrismo/asdf-superdb/actions/workflows/lint.yml)

[SuperDB](https://superdb.org/) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

**TODO: adapt this section**

- `bash`, `curl`, `tar`, and [POSIX utilities](https://pubs.opengroup.org/onlinepubs/9699919799/idx/utilities.html).
- `go` (for building from source). See [Go asdf plugin](https://github.com/asdf-community/asdf-golang?tab=readme-ov-file#install).
- `SOME_ENV_VAR`: set this environment variable in your shell config to load the correct version of tool x.

# Install

Plugin:

This plugin is new and not stable, so it is not registered with
https://github.com/asdf-vm/asdf-plugins yet.

```shell
asdf plugin add superdb https://github.com/chrismo/asdf-superdb.git
```

superdb:

```shell
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
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/chrismo/asdf-superdb/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [chrismo](https://github.com/chrismo/)
