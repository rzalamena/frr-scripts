# FRR scripts

Scripts to automate repeated commands when developing and testing FRR.

## Usage

1.  Get the FRR source code somehow.

2.  Install FRR build dependencies (check out the development manual[1]).

3.  Build FRR with the `compile.sh` script.

    ```sh
    # The compile script supports two toggles:
    env SYSTEMD=no ASAN=no ./compile.sh

    # SYSTEMD adds support for systemd (requires libsystemd-dev package).
    # ASAN compiles FRR with address sanitizer (requires modern compiler).
    ```

4.  Install FRR.

    ```sh
    env SYSTEMD=no ./install.sh
    ```

[1]: http://docs.frrouting.org/projects/dev-guide/en/latest/index.html
