export PATH=${coreutils}/bin
mkdir $out
for src in "$@"
do
  chmod -R +w $out
  cp -R $src $out
done
