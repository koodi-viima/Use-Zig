Use-Zig
=======

Use-Zig is a PowerShell script that can be used for installing multiple Zig
(ziglang.org) versions and switching between different versions on-the-fly.

I use this script in my own development environments and the current state of
the script is currently "it works fine for me". For the time being I will be
updating it based on my personal needs and intend to keep it as simple and
generic as possible.

## Usage

Install (if not already installed) and use a specific version of Zig:

```
.\Use-Zig.ps1 0.7.1
```

Install (if not already installed) and use latest master build:

```
.\Use-Zig.ps1 master
```

Update master:

```
.\Use-Zig.ps1 master -Update
```

### Example session:
```
> .\Use-Zig.ps1 0.7.1
Downloading Zig (0.7.1) from https://ziglang.org/download/0.7.1/zig-windows-x86_64-0.7.1.zip
Installing Zig (0.7.1) to C:\Users\me\AppData\Local\Zigs\x86_64

> zig version
0.7.1

> .\Use-Zig.ps1 master
Downloading Zig (0.8.0-dev.1140+9270aae07) from https://ziglang.org/builds/zig-windows-x86_64-0.8.0-dev.1140+9270aae07.zip
Installing Zig (0.8.0-dev.1140+9270aae07) to C:\Users\me\AppData\Local\Zigs\x86_64

> zig version
0.8.0-dev.1140+9270aae07

> Use-Zig.ps1 master -Update
Version 'master' is already up-to-date
```

## How it works

The Zig versions are installed by default in
`C:\Users\YOUR_USERNAME\AppData\Local\Zigs`. You can change the location by
modifying the `$ZIGS_PATH` variable in the script.

A junction (basically a link) is created in
`C:\Users\YOUR_USERNAME\AppData\Local\Zigs\current` which always points to the
installation of the Zig version specified when running the script for the last
time. This junction is added to the Path environment variable of the current
shell, so that the Zig executable can be used immediately.

When opening a new shell the script needs to be run once for the junction
`C:\Users\YOUR_USERNAME\AppData\Local\Zigs\current` to appear in the Path. You
can add the path to the junction to your Path environment variable to be able
to use a Zig installation immediately in a new shell.
