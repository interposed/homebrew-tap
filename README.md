# interposed/homebrew-tap

Homebrew tap for [interposed](https://interposed.ai) tools.

## Interpose Operator

The cross-platform operator console for interposed daemons.

```sh
brew install --cask interposed/tap/interpose-operator
```

or:

```sh
brew tap interposed/tap
brew install --cask interpose-operator
```

The app is unsigned (self-distributed); the cask strips the quarantine
attribute on install and sets up the FIDO bridge helper + a login agent for
hardware-key approvals. `depends_on libfido2`.

The cask in `Casks/interpose-operator.rb` is updated automatically by the
[interpose-operator release workflow](https://github.com/interposed/interpose-operator)
on each tagged release.
