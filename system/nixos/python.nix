{ pkgs, ... }:
let python =
    let
    packageOverrides = self:
    super: {
      opencv4 = super.opencv4.override {
        enableGtk2 = true;
        gtk2 = pkgs.gtk2;
        #enableFfmpeg = true; #here is how to add ffmpeg and other compilation flags
        #ffmpeg_3 = pkgs.ffmpeg-full;
        };
    };
    in
      pkgs.python3.override {inherit packageOverrides; self = python;};
in
{
environment.systemPackages = with pkgs; [
  (python.withPackages(ps: with ps; [
    opencv4
  ]))
];
}
