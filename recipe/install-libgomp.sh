set -e -x

CHOST=$(${SRC_DIR}/.build/*-*-*-*/build/build-cc-gcc-final/gcc/xgcc -dumpmachine)

# libtool wants to use ranlib that is here, macOS install doesn't grok -t etc
# .. do we need this scoped over the whole file though?
export PATH=${SRC_DIR}/gcc_built/bin:${SRC_DIR}/.build/${CHOST}/buildtools/bin:${SRC_DIR}/.build/tools/bin:${PATH}

pushd ${SRC_DIR}/.build/${CHOST}/build/build-cc-gcc-final/

  mkdir -p ${PREFIX}/${CHOST}/sysroot/lib || true
  for lib in libgomp; do
    if [[ -d ${CHOST}/${lib} ]]; then
      make -C ${CHOST}/${lib} prefix=${PREFIX} install-toolexeclibLTLIBRARIES
      make -C ${CHOST}/${lib} prefix=${PREFIX} install-nodist_fincludeHEADERS || true
    fi
  done

  for lib in libgomp; do
    if [[ -d ${CHOST}/${lib} ]]; then
      make -C ${CHOST}/${lib} prefix=${PREFIX} install-info
    fi
  done

popd

mkdir -p ${PREFIX}/lib
mv ${PREFIX}/${CHOST}/lib/* ${PREFIX}/lib

for lib in libgomp; do
  symtargets=$(find ${PREFIX}/lib -name "${lib}.so*")
  for symtarget in ${symtargets}; do
    symtargetname=$(basename ${symtarget})
    ln -s ${PREFIX}/lib/${symtargetname} ${PREFIX}/${CHOST}/sysroot/lib/${symtargetname}
  done
done

# remove parts of openmp libs that we do not need
for tgt in libgomp.so.1 libgomp.so; do
    rm ${PREFIX}/lib/${tgt}
    rm ${PREFIX}/${CHOST}/sysroot/lib/${tgt}
done

# no static libs
find ${PREFIX}/lib -name "*\.a" -exec rm -rf {} \;
# no libtool files
find ${PREFIX}/lib -name "*\.la" -exec rm -rf {} \;
# clean up empty folder
rm -rf ${PREFIX}/lib/gcc

# Install Runtime Library Exception
install -Dm644 ${SRC_DIR}/.build/src/gcc-${PKG_VERSION}/COPYING.RUNTIME \
        ${PREFIX}/share/licenses/gcc-libs/RUNTIME.LIBRARY.EXCEPTION
