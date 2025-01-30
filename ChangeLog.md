* 11 [build] marcing

    Added ability to change timezone using enviromental value.
    Patch provided by Anton Castelli
    (Gitlab #38)

* 10 [doc] marcing

    Readme rewrite to include ipvlan networks.
    (Gitlab #31)

* 9 [build] marcing

    Kea-compose moved to ipvlan networks.
    (Gitlab #31)

* 8 [build] wlodek

    Run kea under kea user not root.
    (Gitlab #20)

* 7 [build] marcing

    Added kea-compose server

* 6 [build] marcing

    Changed cloudsmith repository instalation procedure to automatic
    (Gitlab #18)

* 5 [build] Wlodek

    Default config files are included into containers
    (Gitlab #10)

* 4 [build] Wlodek

    Kea-dhcp-ddns Dockerfile added.
    (Gitlab #10)

* 3 [build] Wlodek

    Added dhcp4 and dhcp6 Dockerfiles each with Control
    Agent started with supervisor. Premium code can be installed
    using build time argument PREMIUM.
    (Gitlab #8)

* 2 [build] andrei

    Added Gitlab CI pipeline.
    (Gitlab #2)

* 1 [build] tomek

    Migrated to Alpine 3.17
    (Gitlab #1)

For complete code revision history, see
    http://gitlab.isc.org/isc-projects/kea-docker

LEGEND
* [bug]   General bug fix.  This is generally a backward compatible change,
          unless it's deemed to be impossible or very hard to keep
          compatibility to fix the bug.
* [build] Compilation and installation infrastructure change.
* [doc]   Update to documentation. This shouldn't change run time behavior.
* [func]  New feature.  In some cases this may be a backward incompatible
          change, which would require a bump of major version.
* [sec]   Security hole fix. This is no different than a general bug
          fix except that it will be handled as confidential and will cause
          security patch releases.
* [perf]  Performance related change.

*: Backward incompatible or operational change.
