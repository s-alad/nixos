{ pkgs }:

pkgs.runCommand "lightdm-bg.jpg"
  { nativeBuildInputs = [ pkgs.imagemagick ]; }
  ''
    convert ${/home/salad/Pictures/darkcarp.jpeg} \
      -resize 3200x2000\> \
      -background black -gravity center -extent 3200x2000 \
      $out
  ''
