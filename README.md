## dosemu2-mxc: run DOSEMU2 in a sandbox

Runs [DOSEMU2](https://github.com/dosemu2/dosemu2) and its DOS programs inside
a [microsoft/mxc](https://github.com/microsoft/mxc) sandbox, using MXC's
unprivileged Linux **bubblewrap** backend. There is no image to build and no
container runtime or root needed.

Inside the sandbox:

- the host's `/usr`, `/etc` and `/usr/local` are visible read-only, so the
  `dosemu` you have installed is the one that runs;
- your workspace directory is writable and is the working directory;
- everything else (`$HOME`, ssh keys, other projects) is hidden;
- the environment is cleared and rebuilt from scratch, so host secrets in
  environment variables don't leak in;
- network access is off unless you ask for it;
- X11 is forwarded, so the SDL/X front end opens on your desktop.

### Useful for

- running untrusted DOS software, games and installers without exposing your
  files;
- testing dosemu2 builds and configs from a clean, predictable environment;
- keeping dosemu2 and dedb state in one throwaway `$HOME` (`.mxc/home`) away
  from your real home directory.

### Requirements

- Linux with unprivileged user namespaces, and `python3` and `curl`
- for building: the dosemu2 build dependencies installed on the host
- `dosemu2` installed on the host (the sandbox uses it as-is)

### Usage

```
./bin/mxc-fetch.sh                       # download lxc-exec v1.0.1 into .mxc/ (SHA-256 pinned)
make check                               # smoke test
./bin/mxc-run -- dosemu -dumb -E ver     # run dosemu in the sandbox
./bin/mxc-run -- dosemu                  # graphical session over X11
```

`bin/mxc-run [options] -- COMMAND...` builds an MXC request and runs it.

| Option | Effect |
|---|---|
| `--workspace DIR` | writable directory and cwd (default: `$MXC_WORKSPACE`, else the current directory); its `bin/` is put on `PATH` |
| `--cwd DIR` | run in this subdirectory of the workspace |
| `--stage` | use the debs unpacked by `mxc-stage` |
| `--ro PATH` / `--rw PATH` | expose an extra host path read-only / read-write (repeatable) |
| `--env K=V` | set an environment variable (repeatable) |
| `--net deny\|allow` | network egress, default `deny` |
| `--no-x11` | don't forward `DISPLAY` / the X socket |
| `--print-config` | print the generated MXC JSON request and exit |
| `--debug` | show MXC diagnostics |

Example, running a game from a read-only library with saves in the workspace:

```
./bin/mxc-run --ro ~/games/doom --workspace ~/dos-saves -- dosemu -dumb ~/games/doom/DOOM.EXE
```

### Build, install and run your own dosemu2

The sandbox can also build dosemu2 and run what it built, which suits letting
an AI coding agent (Claude Code, opencode, pi, ...) change the source, build,
and try the result without access to the rest of your machine:

```
./bin/mxc-deb ~/src/dosemu2                 # dpkg-buildpackage in the sandbox -> ~/src/dosemu2_*.deb
./bin/mxc-stage --clean ~/src/dosemu2_*.deb # unpack the debs, no root needed
./bin/mxc-run --stage -- dosemu -dumb -E ver   # runs the freshly built dosemu
```

- `mxc-deb SRCDIR` runs `dpkg-buildpackage -b -us -uc -tc` in `SRCDIR`. The
  debs are written next to the source directory, which is the only writable
  place. Build dependencies must be installed on the host (`dpkg-checkbuilddeps`
  lists what's missing); the sandbox can't `apt install`.
- `mxc-stage DEB...` unpacks debs into `.mxc/stage` and generates a launcher
  that uses the staged binary, plugins and data instead of the system ones.
  Nothing is installed system-wide, so it's safe to repeat and easy to reset
  with `--clean`.
- `mxc-run --stage` puts that launcher first on `PATH`.

### Makefile shortcuts

| Target | Does |
|---|---|
| `make fetch` | download the pinned MXC executor into `.mxc/` |
| `make check` | smoke test: the sandbox starts and `dosemu` runs inside it |
| `make dosemu ARGS='-dumb -E ver'` | run `dosemu` in the sandbox with the given arguments |
| `make deb SRC=DIR` | build the debs of a source tree in the sandbox |
| `make stage DEBS='a.deb b.deb'` | unpack debs into `.mxc/stage` |
| `make config` | print the generated MXC request |
| `make help` | list the targets |

### Things to try

```
# Run a DOS program with no network and no access to your home directory
./bin/mxc-run --workspace ~/dos/app -- dosemu -dumb APP.EXE

# See exactly what the sandbox allows before running anything
./bin/mxc-run --ro ~/games --rw ~/saves --print-config -- dosemu

# Run a script of dosemu commands non-interactively (CI-style testing)
./bin/mxc-run -- sh -c 'dosemu -dumb -E "ver" > out.txt'

# Open a shell in the sandbox to poke around
./bin/mxc-run -- sh

# Check a program really can't read your files
./bin/mxc-run -- sh -c "ls $HOME/.ssh"   # $HOME expands on the host; the sandbox can't see it
```

### Notes

- `$HOME` inside the sandbox is `.mxc/home` (git-ignored); dosemu2 and dedb
  config and state persist there between runs.
- Without a controlling terminal, `dosemu -dumb` works; for full-screen use,
  use the X11 front end.
- `--net allow` needs unprivileged network namespaces plus `slirp4netns`,
  `iptables` and `iproute2`. On Ubuntu 24.04+ you may also need an AppArmor
  profile for `lxc-exec`, or `kernel.apparmor_restrict_unprivileged_userns=0`.
- `/dev/kvm` can't be passed through (MXC mounts device nodes `nodev`), so
  dosemu2 uses its software CPU emulation.
- Supplementary groups are dropped; access that depends on a group rather than
  your uid won't work.

### Upgrading MXC

Bump `MXC_VERSION` and `MXC_SHA256` together in `bin/mxc-fetch.sh`.
