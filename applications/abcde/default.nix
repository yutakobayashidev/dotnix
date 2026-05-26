{ pkgs, ... }:
{
  home.packages = with pkgs; [
    abcde
    cdparanoia
    flac
    cdrtools
  ];

  xdg.configFile."abcde.conf".text = ''
    OUTPUTDIR=/var/lib/nextcloud/data/yuta/files/music
    OUTPUTFORMAT=''${ARTISTFILE}/''${ALBUMFILE}/''${TRACKFILE}
    OUTPUTTYPE=flac
    ACTIONS=cddb,read,encode,tag,move,clean
    CDDBMETHOD=cddb
    CDDBPROTO=7
    FLACOPTS="--best -V"
    CDROMREADERSYNTAX=cdparanoia
    EJECTCD=y
    INTERACTIVE=n
    MAXPROCS=4
    PADTRACKS=y
    ONETRACK=y
    VAOUTPUTFORMAT=''${ALBUMFILE}/''${TRACKFILE}
    VA_ONETRACKOUTPUTFORMAT=''${ALBUMFILE}/''${TRACKFILE}
    PLAYLISTFORMAT=''${ARTISTFILE}/''${ALBUMFILE}/''${ALBUMFILE}.m3u
    PLAYLISTDATAPREFIX=''${ARTISTFILE}/''${ALBUMFILE}
    COMMENT=abcde version 2.9.3
  '';
}
