# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

# TODO: adapt this
asdf plugin test superdb https://github.com/chrismo/asdf-superdb.git "super --version"
```

Tests are automatically run in GitHub Actions on push and PR.

## Local Development: Testing Your asdf Plugin

To develop and test your asdf plugin locally, follow these steps:

1. **Remove any existing plugin (if present):**
   ```bash
   asdf plugin remove superdb
   ```

2a. **Add your plugin from your local directory:**
   ```bash
   asdf plugin add superdb /full/path/to/your/asdf-superdb
   ```
   Replace `/full/path/to/your/asdf-superdb` with the absolute path to your plugin directory.

   This is a one-time copy, so if you make changes to your plugin, you need to remove and re-add it.

2b. **Alternatively, symlink your plugin directory (if supported by your OS):**
   ```bash
   ln -s /your/local/asdf-superdb ~/.asdf/plugins/superdb
   ```

3. **Develop and test in-place:**
  - Any changes made in your local plugin directory are immediately available to asdf.
  - Use commands like:
    ```bash
    asdf install superdb <version>
    asdf list superdb
    ```

4. **If you move your plugin directory:**
   Remove and re-add the plugin with the new path.
