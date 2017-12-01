{ pkgs ? import <nixpkgs> {} }:

with pkgs;
stdenv.mkDerivation { 
      name = "spark-discovery-2017"; 
      src = fetchurl { 
        url = "http://mirrors.cdn.adacore.com/art/592c5299c7a447388d5c991d"; 
        sha256 = "0hyayqvnkfssgm6ibch18b9ymc66c38xh5jk47lvjsppy822wc8b"; 
      }; 

      dontBuild = true; 
      dontStrip = true; 
      unpackCmd = "tar -xzf $curSrc"; 

      buildInputs = [ gnugrep file patchelf makeWrapper ];

      installPhase = '' 
        mkdir -p $out
        tar cf - bin include lib libexec share | (cd $out && tar xf -)
        patchelf --set-interpreter "${stdenv.glibc}/lib/ld-linux-x86-64.so.2" $out/bin/gnatprove
        for path in $out/libexec/spark/bin/*; do
          if file "$path" | grep -q -i "elf"; then 
            echo "Patching $path" 
            if file "$path" | grep -q -i "executable"; then 
               patchelf --set-interpreter "${stdenv.glibc}/lib/ld-linux-x86-64.so.2" "$path" 
            fi 
            patchelf --set-rpath "${stdenv.glibc}/lib" "$path" 
          fi 
        done 
      ''; 
    } 
