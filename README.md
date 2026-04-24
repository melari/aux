# aux (AUXiliary Brain)

This repository contains two distinct pieces of software:
1. A client CLI
2. A multi-purpose server docker container

Note that the server component is fully optional and it is possible to use the CLI alone.

## Client CLI

The client CLI is a small utility which helps manage your library of markdown notes. It provides automatic syncing betwee
- automatic syncing between devices via a git repository
- search functionality via [qmd](https://github.com/tobi/qmd)

### Install

```
curl -fsSL gitpack.htlc.io | sh -s -- install git@github.com:melari/aux.git
```

### Usage


Next, you can set up your notes repository. You need to provide:
1. The directory your notes should be stored locally.
2. The syncing server (github repo) that will be used to sync your notes to your other devices. This can be your own aux server (see below), a free GitHub repo, or any other git repo provider.

```
aux link ~/path/to/your/notes git@github.com:user/my-notes.git
```

Aux runs a systemd service in the background to provide automatic file syncing. You can confirm that the service is healthy at any time by running: `aux status`

Check out other available commands with `aux help`
```
```
```
```

## Server

The aux server provides several pieces of optional functionality. Each feature is independently activated and configured using environment variables.

### Feature 1: Syncing Server

If you don't wish to use GitHub to store your notes, this container allows you to run your own git repo to act as a syncing server.

**To enable**: attach a volume to `/app/bare_repo.git`.

`docker run -v /path/on/host.git:/app/bare_repo.git aux`

Then, when you are using `aux` CLI, you can link your notes directory to your server via:

`aux link ~/my/notes name@server.com:/path/on/host.git`

### Feature 2: File Backup

Even if you do use GitHub as your syncing server, you can use this server software to mirror a copy of your notes for backup.

If you have already configured the syncing server, your files are backed up implicitly, no need to manually configure this.

If you are using GitHub as your syncing server, you need to specify the URL to your repo. This is done using the `SYNCING_SERVER_URL` environment variable.

`docker run -e SYNCING_SERVER_URL=git@github.com:user/notes.git aux`

### Feature 3: Browser-based Editor

To edit your notes on devices where you can't run the CLI, the aux server provides a web interface where you can view and edit your notes.

If you using an external syncing server, you must include `SYNCING_SERVER_URL` environment variable so the server knows where to get your notes from. This is not required if you're using the built in syncing server.

Next, enable the editor feature by setting the `RUN_EDITOR=true` environment variable.

`docker run -e SYNCING_SERVER_URL=git@github.com:user/notes.git -e RUN_EDITOR=true aux`

### Feature 4: Public Note Hosting

This feature handles rendering and serving notes which you have explicitly marked as public. This can be used to host a "public digital garden" or wiki-style knowledge base.

If you using an external syncing server, you must include `SYNCING_SERVER_URL` environment variable so the server knows where to get your notes from. This is not required if you're using the built in syncing server.

Next, enable the editor feature by setting the `RUN_PUBLIC_HOSTING=true` environment variable.

`docker run -e SYNCING_SERVER_URL=git@github.com:user/notes.git -e RUN_PUBLIC_HOSTING=true aux`

# Development

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
