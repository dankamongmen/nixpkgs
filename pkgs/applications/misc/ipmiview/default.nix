{ lib, stdenv
, fetchurl
, makeDesktopItem
, makeWrapper
, patchelf
, fontconfig
, freetype
, gcc
, gcc-unwrapped
, iputils
, psmisc
, xorg }:

stdenv.mkDerivation rec {
  pname = "IPMIView";
  version = "2.18.0";
  buildVersion = "201007";

  src = fetchurl {
    url = "https://www.supermicro.com/wftp/utility/IPMIView/Linux/IPMIView_${version}_build.${buildVersion}_bundleJRE_Linux_x64.tar.gz";
    sha256 = "10cv63yhh81gjxahsg4y3zp4mjivc217m4z1vcpwvvnds46c65h8";
  };

  nativeBuildInputs = [ patchelf makeWrapper ];
  buildPhase = with xorg;
    let
      stunnelBinary = if stdenv.hostPlatform.system == "x86_64-linux" then "linux/stunnel64"
      else if stdenv.hostPlatform.system == "i686-linux" then "linux/stunnel32"
      else throw "IPMIView is not supported on this platform";
    in
  ''
    patchelf --set-rpath "${lib.makeLibraryPath [ libX11 libXext libXrender libXtst libXi ]}" ./jre/lib/amd64/libawt_xawt.so
    patchelf --set-rpath "${lib.makeLibraryPath [ freetype ]}" ./jre/lib/amd64/libfontmanager.so
    patchelf --set-rpath "${gcc.cc}/lib:$out/jre/lib/amd64/jli" --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./jre/bin/java
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" ./BMCSecurity/${stunnelBinary}
  '';

  desktopItem = makeDesktopItem rec {
    name = "IPMIView";
    exec = "IPMIView";
    desktopName = name;
    genericName = "Supermicro BMC manager";
    categories = "Network";
  };

  installPhase = ''
    mkdir -p $out/bin
    cp -R . $out/

    ln -s ${desktopItem}/share $out/share

    # LD_LIBRARY_PATH: fontconfig is used from java code
    # PATH: iputils is used for ping, and psmisc is for killall
    # WORK_DIR: unfortunately the ikvm related binaries are loaded from
    #           and user configuration is written to files in the CWD
    makeWrapper $out/jre/bin/java $out/bin/IPMIView \
      --set LD_LIBRARY_PATH "${lib.makeLibraryPath [ fontconfig gcc-unwrapped.lib ]}" \
      --prefix PATH : "$out/jre/bin:${iputils}/bin:${psmisc}/bin" \
      --add-flags "-jar $out/IPMIView20.jar" \
      --run 'WORK_DIR=''${XDG_DATA_HOME:-~/.local/share}/ipmiview
             mkdir -p $WORK_DIR
             ln -snf '$out'/iKVM.jar '$out'/iKVM_ssl.jar '$out'/libiKVM* '$out'/libSharedLibrary* $WORK_DIR
             cd $WORK_DIR'
  '';

  meta = with lib; {
    license = licenses.unfree;
    maintainers = with maintainers; [ vlaci ];
    platforms = [ "x86_64-linux" "i686-linux" ];
  };
}
