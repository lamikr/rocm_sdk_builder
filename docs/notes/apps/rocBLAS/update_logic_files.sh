for f in *.yaml; do
  sed -i 's\phoenix\strixpoint\g' $f
done
for f in *.yaml; do
  sed -i 's\11, 0, 3\11, 5, 0\g' $f
done
for f in *.yaml; do
  sed -i 's\gfx1103\gfx1150\g' $f
done
for f in *.yaml; do
  sed -i 's\Device 10bf\Device 105e\g' $f
done
