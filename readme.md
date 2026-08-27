# About
A simple cli time tracking utility for posix systems.

# Example
```console
$ timetracker create-item example
$ timetracker start-session example
example session started.
$ timetracker end-session example
example session ended after 5 seconds.
$ timetracker list-sessions example
example session 1/1
From: 2026-08-27 22:36:00
To:   2026-08-27 22:36:05
Duration: 5 seconds
```

# How to build
```console
$ make build
```
The final binary is located at ./build/bin/

