(dependency-management)=

# Dependency management with niv

The Nix language can be used to describe dependencies between files managed by Nix.
Nix expressions themselves can depend on remote sources, and there are multiple ways to specify their origin, as shown in [](pinning-nixpkgs).

For more automation around handling remote sources, set up [niv](https://github.com/nmattia/niv/) in your project:

```shell-session
$ nix-shell -p niv --run "niv init"
```

This command will generate `nix/sources.json` in the current directory, which is a lock file for dependencies.
It will also create `nix/sources.nix`, which exposes those dependencies as an attribute set.

:::{note}
By default, `niv init` will add the latest revision of `nixpkgs-unstable` as a source.
If you need the latest revision of a specific branch:

```shell-session
niv init --nixpkgs-branch nixos-23.05
```
:::

Import the generated `nix/sources.nix` for the top-level argument in the top-level `default.nix` and use it to refer to the Nixpkgs source directory:

```nix
{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs {};
in {
  package = pkgs.hello;
}
```

`nix-build` will call the top-level function with the default argument. This pattern allows overriding remote sources programmatically.

We recommend adding niv to the shell environment of your project, so it's readily available.

```nix
{ sources ? import ./nix/sources.nix }:
let
  pkgs = import sources.nixpkgs {};
in {
  build = pkgs.hello;
  shell = pkgs.mkShell {
    inputsFrom = [ build ];
    packages = with pkgs; [
      niv
    ]
  };
}
```

See [](sharing-shell-dependencies) for details.

## Overriding sources

As an example, we will use the previously created expression with older version of Nixpkgs.

Create a new directory and set up niv with a different version of Nixpkgs:

```shell-session
mkdir old
cd old
niv init --nixpkgs-branch 18.09
```

Create a file `default.nix` in the new directory, and import the original one with the `sources` just created.

```nix
import ../default.nix { sources = import ./nix/sources.nix; }
```

This will result in a different version being built:

```shell-sessiono
nix-build
./result/bin/hello --version | head -1
```

Sources can also be overridden on the command line:

```shell-session
nix-build .. --arg sources 'import ./nix/sources.nix'
```


Check the built-in help for details:

```shell-session
niv --help
```

## Next steps

- For more details and examples of the different ways to specify remote sources, see [](pinning-nixpkgs).
