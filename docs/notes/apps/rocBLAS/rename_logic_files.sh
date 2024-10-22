for f in *.yaml; do
  fnew=`echo $f | sed 's/phoenix/strixpoint/'`
  mv $f $fnew
done
