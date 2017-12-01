{ pkgs ? import <nixpkgs> {} }:

with pkgs;
stdenv.mkDerivation { 
      name = "gnat-gpl-2017"; 
      src = fetchurl { 
        url = "http://mirrors.cdn.adacore.com/art/591c6d80c7a447af2deed1d7"; 
        sha1 = "9682e2e1f2f232ce03fe21d77b14c37a0de5649b"; 
      }; 

      dontBuild = true; 
      dontStrip = true; 
      unpackCmd = "tar -xzf $curSrc"; 

      buildInputs = [ gnugrep file patchelf makeWrapper ncurses5 
                      xorg.libXinerama xorg.libXrender xorg.libSM xorg.libICE xorg.libX11 
                      xorg.libXext
                      bzip2 zlib]; 

      patches = [ ./nix-font-config.patch ];

      installPhase = '' 
        set -e 
        make ins-all prefix="$out" 
        for path in $out/{bin,libexec/gcc/x86_64-pc-linux-gnu/6.3.1,libexec/gprbuild}/*; do 
          if file "$path" | grep -q -i "elf"; then 
            echo "Patching $path" 
            if file "$path" | grep -q -i "executable"; then 
              patchelf --set-interpreter "${stdenv.glibc}/lib/ld-linux-x86-64.so.2" "$path" 
            fi 
            patchelf --set-rpath "${stdenv.glibc}/lib" "$path" 
          fi 
        done 
        mkdir -p $out/share/gnat/bin 
        mv $out/bin/* $out/share/gnat/bin 
        for path in $out/share/gnat/bin/{gnat,gpr}*; do 
          if file "$path" | grep -q -i "elf"; then 
            makeWrapper $path $out/bin/$(basename $path) --prefix PATH : $out/share/gnat/bin --set GNAT_ROOT $out --set GCC_ROOT $out --set LIBRARY_PATH "${stdenv.glibc}/lib" 
          fi 
        done 
        mkdir -p $out/share/gcc-bin
        # Default linker
        for path in $out/share/gnat/bin/{gcc,g++,ld}; do
          if file "$path" | grep -q -i "elf"; then
            mv $path $out/share/gcc-bin/$(basename $path)
            makeWrapper $out/share/gcc-bin/$(basename $path) $path --add-flags "-Wl,--dynamic-linker=${stdenv.glibc}/lib/ld-linux-x86-64.so.2"
          fi
        done
        makeWrapper $out/share/gnat/bin/gps $out/bin/gps --prefix PATH : $out/share/gnat/bin --set GNAT_ROOT $out --set GCC_ROOT $out --set GPS_ROOT $out --prefix LD_LIBRARY_PATH : $out/lib/gps/:${ncurses5}/lib:${xorg.libXinerama}/lib:${xorg.libXrender}/lib:${xorg.libSM}/lib:${xorg.libICE}/lib:${xorg.libX11}/lib:${xorg.libXext}/lib:${bzip2.out}/lib
        for path in etc share lib libexec lib64; do
           ln -s $out/$path $out/share/gnat/$path
        done
      ''; 
    } 
