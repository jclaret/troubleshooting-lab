cmd_/build/Module.symvers := sed 's/\.ko$$/\.o/' /build/modules.order | scripts/mod/modpost -m -a  -o /build/Module.symvers -e -i Module.symvers   -T -
