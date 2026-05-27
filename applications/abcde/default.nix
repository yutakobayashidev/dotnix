{ pkgs, ... }:
{
  home.packages = with pkgs; [
    abcde
    cdparanoia
    flac
    cdrtools
  ];

  home.file.".abcde.conf".text = ''
    OUTPUTDIR=/srv/bulk/music/_inbox
    OUTPUTFORMAT=''${ARTISTFILE}/''${ALBUMFILE}/''${TRACKFILE}
    OUTPUTTYPE=flac
    ACTIONS=cddb,read,encode,tag,move,clean
    CDDBMETHOD=cddb,musicbrainz,cdtext
    CDDBPROTO=7
    FLACOPTS="--best -V"
    CDROMREADERSYNTAX=cdparanoia
    EJECTCD=y
    INTERACTIVE=n
    MAXPROCS=4
    PADTRACKS=y
    ONETRACK=n
    VAOUTPUTFORMAT=''${ALBUMFILE}/''${TRACKFILE}
    VA_ONETRACKOUTPUTFORMAT=''${ALBUMFILE}/''${TRACKFILE}
    PLAYLISTFORMAT=''${ARTISTFILE}/''${ALBUMFILE}/''${ALBUMFILE}.m3u
    PLAYLISTDATAPREFIX=''${ARTISTFILE}/''${ALBUMFILE}
  '';
}
