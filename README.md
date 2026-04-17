# aux (AUXiliary Brain)

`aux` is a small utility which helps manage your library of markdown notes. It provides:
- automatic syncing between devices via a git repository
- search functionality via [qmd](https://github.com/tobi/qmd)

## Install

```
curl -fsSL gitpack.htlc.io | sh -s -- install git@github.com:melari/aux.git
```

## Usage

wip

## Development

### Server

Note: All commands should be run from within the `server/` directory.

#### Dependencies

1) This project uses rbenv. Confirm that `ruby --version` matches the .ruby-version file.
  OSX
    `$ brew install rbenv ruby-build`
    `$ rbenv install`

  Arch
    `$ sudo pacman -S --needed rbenv libyaml`
    `$ yay -S ruby-build-git`
    `$ rbenv install`

#### Running the server

Simply run `$ script/run`
