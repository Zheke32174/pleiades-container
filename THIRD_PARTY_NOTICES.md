# Third-Party Notices

## No Vendored Source

This repository does not contain vendored third-party source code.

All external tools referenced by pleiades-container scripts are:
- Downloaded from official distribution mirrors (Gentoo stage3), OR
- Present as system packages (systemd-nspawn, tmux), OR
- Cloned from their upstream repositories at setup time

No third-party source files are committed to this repository. Each external
project remains entirely governed by its own license.

## Runtime Dependencies

| Project | Upstream URL | License |
|---------|-------------|---------|
| Gentoo Linux | https://www.gentoo.org | Various (GPL-2.0+, MIT, etc.) |
| systemd | https://github.com/systemd/systemd | LGPL-2.1+ |
| tmux | https://github.com/tmux/tmux | ISC |
| pleiades | https://github.com/Zheke32174/pleiades | MIT |

## License Compatibility

pleiades-container scripts are MIT-licensed. Because no third-party source is
vendored, there are no GPL/LGPL mixing concerns in this repository. If you
vendor any of the above tools into a derivative work, review the compatibility
of their licenses with your distribution terms.
