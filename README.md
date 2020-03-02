# FRR scripts

Scripts to automate repeated commands when developing and testing FRR.

## Usage

1.  Get the FRR source code somehow.

2.  Install FRR build dependencies (check out the development manual[1]).

3.  Build FRR with the `compile.sh` script.

    ```sh
    # The compile script supports two toggles:
    env SYSTEMD=no ASAN=no JOBS=$(grep -c 'processor' /proc/cpuinfo) ./compile.sh

    # ASAN compiles FRR with address sanitizer (requires modern compiler).
    # DOC compiles FRR documentation too (requires sphinx installed).
    # FPM compiles FRR with FPM support.
    # JOBS amount of parallel compiler instances we should use.
    # SNMP adds support for snmp (requires libsnmp-dev package).
    # SYSTEMD adds support for systemd (requires libsystemd-dev package).
    ```

4.  Install FRR.

    ```sh
    env SYSTEMD=no ./install.sh

    # SYSTEMD install systemd service file.
    ```

[1]: http://docs.frrouting.org/projects/dev-guide/en/latest/index.html
