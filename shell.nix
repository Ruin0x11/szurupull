#!/usr/bin/env nix-shell
with import <nixpkgs> {};
let
  # define packages to install with special handling for OSX
  basePackages = [
    gnumake
    gcc
    readline
    openssl
    zlib
    libxml2
    curl
    libiconv
    elixir_1_9
    glibcLocales
    nodejs-12_x
    yarn
    postgresql
  ];

  inputs = basePackages
    ++ lib.optional stdenv.isLinux inotify-tools
    ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
        CoreFoundation
        CoreServices
      ]);

  # define shell startup command
  hooks = ''
    # this allows mix to work on the local directory
    mkdir -p .nix-mix
    mkdir -p .nix-hex
    export MIX_HOME=$PWD/.nix-mix
    export HEX_HOME=$PWD/.nix-hex
    export PATH=$MIX_HOME/bin:$PATH
    export PATH=$HEX_HOME/bin:$PATH
    export LANG=en_US.UTF-8
    export ERL_AFLAGS="-kernel shell_history enabled"

        export PGDATA="$PWD/db"
        export SOCKET_DIRECTORIES="$PWD/sockets"
        mkdir $SOCKET_DIRECTORIES
        initdb
        echo "unix_socket_directories = '$SOCKET_DIRECTORIES'" >> $PGDATA/postgresql.conf
        pg_ctl -l $PGDATA/logfile start
        createuser postgres --createdb -h localhost
        function end {
          echo "Shutting down the database..."
          pg_ctl stop
          echo "Removing directories..."
          rm -rf $PGDATA $SOCKET_DIRECTORIES
        }
        trap end EXIT
  '';

in mkShell {
  buildInputs = inputs;
  shellHook = hooks;
}
