#!/bin/bash 
#
# pdcs at atmosfera.unam.mx
# copyright Universidad Nacional Autonoma de Mexico 2022/2023 
#

export HOME_APPS=$PWD #$HOME/software/apps
export COMPILER_NAME=gcc 
# Debian 10 COMPILER_VERSION=9
# Debian 11 COMPILER_VERSION=10
# Ubuntu 20 COMPILER_VERSION=9
# Ubuntu 22 COMPILER_VERSION=11 
export COMPILER_VERSION=10 #9, 10, 11
export COMP_VERSION=$COMPILER_NAME/$COMPILER_VERSION

_banner(){

echo "#######################################################"
echo   $*
echo "#######################################################"

}

_modulo(){
local APP_NAME="$1" 
local APP_VERSION="$2"


local __CPPFLAGS="$(echo $APP_NAME | tr [a-z] [A-Z] | tr "-" "_" )_CPPFLAGS"
local __LDFLAGS="$(echo $APP_NAME | tr [a-z] [A-Z] | tr "-" "_" )_LDFLAGS"
local __ROOT="$(echo $APP_NAME | tr [a-z] [A-Z] | tr "-" "_" )_ROOT"
local __NAME="$(echo $APP_NAME | tr [a-z] [A-Z] | tr "-" "_" )"

mkdir -pv $HOME_APPS/modulefiles/Compiler/$COMP_VERSION/$APP_NAME/ && \

cat <<LUAMOD > $HOME_APPS/modulefiles/${MODULE_FILE}.lua 
local apps = "$HOME_APPS"
local pkg = "$APP_NAME"
local pkg_version = "$APP_VERSION"
local compiler = "$COMPILER_NAME"
local compiler_version = "$COMPILER_VERSION"
local base = pathJoin(apps,pkg,compiler,compiler_version,pkg_version)
local cppflags = "-I"..base.."/include"
local ldflags = "-L"..base.."/lib".." -Wl,-rpath="..base.."/lib"
local ldlibrary = base.."/lib" 


prepend_path("PATH",pathJoin(base,"bin"))
--prepend_path("LD_LIBRARY_PATH",pathJoin(base,"lib"))
prepend_path("MANPATH",pathJoin(base,"share/man"))


setenv("$__CPPFLAGS",cppflags)
setenv("$__LDFLAGS",ldflags)
setenv("$__ROOT",base)
setenv("$__NAME",base)

if (os.getenv("LD_LIBRARY_PATH") == nil )  then  
        setenv("LD_LIBRARY_PATH",ldlibrary)
    else  
        prepend_path("LD_LIBRARY_PATH",ldlibrary)
end

if (os.getenv("CPPFLAGS") == nil )  then  
        setenv("CPPFLAGS",cppflags)
    else  
        setenv("CPPFLAGS",cppflags.." "..os.getenv("CPPFLAGS"))
end

if (os.getenv("LDFLAGS") == nil )  then  
        setenv("LDFLAGS",ldflags)
    else  
        setenv("LDFLAGS",ldflags.." "..os.getenv("LDFLAGS"))
end
LUAMOD

test $APP_NAME == "jasper" && echo "setenv(\"${__NAME}INC\",base..\"/include\")" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua
test $APP_NAME == "jasper" && echo "setenv(\"${__NAME}LIB\",base..\"/lib\")" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua
test $APP_NAME == "netcdf-fortran" && echo "setenv(\"NETCDF\",base)" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua 
test $APP_NAME == "netcdf-c" && echo "setenv(\"NETCDF\",base)" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua 

}

_variables(){

local APP_NAME=$1
local APP_VERSION=$2
local APP_URL=$3

echo " export APP_NAME=$APP_NAME
APP_VERSION=$APP_VERSION
APP_ROOT=$HOME_APPS/$APP_NAME
APP_BUILD=$HOME_APPS/$APP_NAME/$COMP_VERSION/build
APP_INSTALL=$HOME_APPS/$APP_NAME/$COMP_VERSION/$APP_VERSION
APP_URL=https://github.com/pdcs-cca/compila-WRF/raw/main/src/${APP_NAME}-${APP_VERSION}.tar.gz
MODULE_FILE=Compiler/$COMP_VERSION/$APP_NAME/$APP_VERSION
"
}

_setup(){
test -d $APP_INSTALL && return 0
test "$1" == "check" && local CHECK=1 && shift
mkdir -pv $APP_BUILD
cd $APP_BUILD
curl -L $APP_URL | tar xzf -
cd $APP_NAME-$APP_VERSION/
./configure $@  |& tee configure-$(date +%s).log
make -j8 |& tee compile-$(date +%s).log
test ! -z "$CHECK" && make -j4 check
make install
_modulo $APP_NAME $APP_VERSION
}

_build-wrf(){

test  -e $WRF_ROOT/main/real.exe -a  -e $WRF_ROOT/main/wrf.exe -a -e $WRF_ROOT/main/ndown.exe -a -e  $WRF_ROOT/main/tc.exe && return 0
export EM_CORE=1
export NMM_CORE=0
export WRF_CHEM=1
#export WRF_KPP=1
#export YACC="$CONDA_PREFIX/bin/yacc -d"
#export FLEX_LIB_DIR="$CONDA_PREFIX/lib"

mkdir -pv $WRF_ROOT
cd $WRF_ROOT
curl -L https://github.com/wrf-model/WRF/releases/download/v4.4.1/v4.4.1.tar.gz | tar --strip-components=1  -xzvf - 
sed -i 's/FALSE/TRUE/' arch/Config.pl 
test $COMPILER_VERSION -eq 9 &&  
    curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-gcc/configure-gcc9.wrf.chem > configure.wrf || 
    curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-gcc/configure-gcc11.wrf.chem > configure.wrf
./compile -j 4 em_real |& tee compile-$(date +%s).log  
test ! -e main/real.exe && _banner "Error !!! real.exe" && exit 1
test ! -e main/wrf.exe && _banner "Error !!! wrf.exe" && exit 1
}

_build-wps(){

test -L $WPS_ROOT/geogrid.exe -a -L $WPS_ROOT/metgrid.exe -a -L $WPS_ROOT/ungrib.exe && return 0
mkdir -pv $WPS_ROOT
cd $WPS_ROOT 
curl -L https://github.com/wrf-model/WPS/archive/refs/tags/v4.4.tar.gz | tar --strip-components=1  -xzvf -
test $COMPILER_VERSION -eq 9 &&  
    curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-gcc/configure-gcc9.wps.chem > configure.wps || 
    curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-gcc/configure-gcc11.wps.chem > configure.wps
./compile  |& tee compile-$(date +%s).log  
test ! -d bin && mkdir bin 
cp -v *.exe bin  || _banner "Error !!! wps "  
}

##
###
######################################################################################
######################################################################################
###
##

test -z $HOME_APPS  && echo "HOME_APPS is empty ..." && exit 1
test -z $COMPILER_NAME  && echo "COMPILER_NAME is empty ..." && exit 1
test -z $COMPILER_VERSION  && echo "COMPILER_VERSION is empty ..." && exit 1

test -e $CONDA_PREFIX/lmod/lmod/init/profile &&  source $CONDA_PREFIX/lmod/lmod/init/profile  
alias ml=module

_banner "WRF 4.4.1"
ml purge 
export WRF_ROOT=$HOME_APPS/wrf-chem/$COMP_VERSION/WRF
export WPS_ROOT=$HOME_APPS/wrf-chem/$COMP_VERSION/WPS

mkdir -pv $HOME_APPS/modulefiles 
mkdir -pv $HOME_APPS/modulefiles/wrf-chem
WRF_MODULE=$HOME_APPS/modulefiles/wrf-chem/4.4.1.lua 
ml use $HOME_APPS/modulefiles 

_banner "ZLIB"
eval $(_variables zlib 1.2.12 )
_setup --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml 
echo $LD_LIBRARY_PATH

echo "load(\"$MODULE_FILE\")" > $WRF_MODULE

_banner "LIBAEC"
eval $(_variables libaec 1.0.6 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

#_banner "CURL"
eval $(_variables curl 7.82.0 )
_setup  --without-libidn2  --with-openssl=$CONDA_PREFIX --without-nghttp3 --without-nghttp2 --with-zlib=$ZLIB_ROOT --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo $LD_LIBRARY_PATH
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "LIBPNG"
eval $(_variables libpng 1.6.37 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo $LD_LIBRARY_PATH
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "JASPERLIB"  
eval $(_variables jasper 1.900.22 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo $LD_LIBRARY_PATH
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "HDF5"
eval $(_variables hdf5 1.10.8 )
_setup  --enable-fortran --with-zlib=$ZLIB_ROOT --with-szlib=$LIBAEC_ROOT  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo $LD_LIBRARY_PATH
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "NETCDF-C"
eval $(_variables netcdf-c 4.8.1)
_setup   --disable-dap-remote-tests  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo $LD_LIBRARY_PATH
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "NETCDF-FORTRAN"
eval $(_variables netcdf-fortran 4.5.4)
_setup --prefix=$NETCDF_C_ROOT 
test ! -d $APP_INSTALL && mkdir $APP_INSTALL

_banner "WRF-Chem"
_build-wrf
echo "prepend_path(\"PATH\",\"$WRF_ROOT/main\")
setenv(\"WRF_ROOT\",\"$WRF_ROOT\")
setenv(\"WRF_DIR\",\"$WRF_ROOT\") " >> $WRF_MODULE   


_banner "WPS"
_build-wps
echo "prepend_path(\"PATH\",\"$WPS_ROOT/bin\")
setenv(\"WPS_ROOT\",\"$WPS_ROOT\")"  >> $WRF_MODULE

