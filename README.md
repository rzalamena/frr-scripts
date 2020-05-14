FRR scripts
===========

Scripts to automate repeated commands when developing and testing FRR.

Usage
-----

1.  Get the FRR source code somehow.

2.  Install FRR build dependencies (check out the development manual[1]).

3.  Build FRR with the `compile.sh` script.

    ```sh
    # Compile FRR using N jobs with address sanitizer:
    ./compile.sh --asan --jobs=$(grep -c 'processor' /proc/cpuinfo)

    # To see all availabe options, run:
    ./compile.sh --help
    ```

4.  Install FRR.

    ```sh
    # Install FRR with systemd support.
    ./install.sh --systemd

    # To see all availabe options, run:
    ./install.sh --help
    ```

[1]: http://docs.frrouting.org/projects/dev-guide/en/latest/index.html
