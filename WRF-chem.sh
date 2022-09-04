#!/bin/bash 
# 
export HOME_APPS=$HOME/software/apps
export COMPILER_NAME=gcc
export COMPILER_VERSION=9.4.0
export COMP_VERSION=$COMPILER_NAME/$COMPILER_VERSION

_banner(){

echo "#######################################################"
figlet -tr $*
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


prepend_path("PATH",pathJoin(base,"bin"))
--prepend_path("LD_LIBRARY_PATH",pathJoin(base,"lib"))
prepend_path("MANPATH",pathJoin(base,"share/man"))


setenv("$__CPPFLAGS",cppflags)
setenv("$__LDFLAGS",ldflags)
setenv("$__ROOT",base)
setenv("$__NAME",base)


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
./configure $@ 
make -j4
test ! -z "$CHECK" && make -j4 check
make install
_modulo $APP_NAME $APP_VERSION
}
##
###
######################################################################################
######################################################################################
###
##

sudo apt -y install gfortran gcc make tcsh flex curl axel vim htop bison mpich libssl-dev mc git tmux figlet
ml purge || sudo apt -y install lmod
test -e /etc/profile.d/lmod.sh &&  source /etc/profile.d/lmod.sh

_banner "WRF 4.4.1"
ml purge 

mkdir -pv $HOME_APPS/modulefiles 
mkdir -pv $HOME_APPS/modulefiles/wrf-chem
WRF_MODULE=$HOME_APPS/modulefiles/wrf-chem/4.4.1.lua 
sudo sh -c "echo $HOME_APPS/modulefiles > /etc/lmod/modulespath "
ml use $HOME_APPS/modulefiles 

_banner "ZLIB"
eval $(_variables zlib 1.2.12 )
_setup --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml 
echo "load(\"$MODULE_FILE\")" > $WRF_MODULE

_banner "LIBAEC"
eval $(_variables libaec 1.0.6 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "CURL"
eval $(_variables curl 7.82.0 )
_setup --with-openssl  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "LIBPNG"
eval $(_variables libpng 1.6.37 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "JASPERLIB"  
eval $(_variables jasper 1.900.22 )
_setup  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "HDF5"
eval $(_variables hdf5 1.10.8 )
_setup check --enable-fortran --with-zlib=$ZLIB_ROOT --with-szlib=$LIBAEC_ROOT  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "NETCDF-C"
eval $(_variables netcdf-c 4.8.1)
_setup check  --disable-dap-remote-tests  --prefix=$APP_INSTALL 
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE


_banner "NETCDF-FORTRAN"
eval $(_variables netcdf-fortran 4.5.4)
_setup --prefix=$NETCDF_C_ROOT 
mkdir $APP_INSTALL

_banner "WRF-Chem"
mkdir -pv $HOME_APPS/wrf-chem/$COMP_VERSION
cd $HOME_APPS/wrf-chem/$COMP_VERSION
curl -L https://github.com/wrf-model/WRF/releases/download/v4.4.1/v4.4.1.tar.gz | tar xzvf - 
ln -s WRFV4.4.1 WRF
cd WRFV4.4.1 

export EM_CORE=1
export NMM_CORE=0
export WRF_CHEM=1
export WRF_KPP=1
export YACC="/usr/bin/yacc -d"
export FLEX_LIB_DIR="/usr/lib/x86_64-linux-gnu"

sed -i 's/FALSE/TRUE/' arch/Config.pl 
curl -LO https://raw.githubusercontent.com/pdcs-cca/compila-WRF/main/ubuntu-20-gcc/chem/configure.wrf
/usr/sbin/logsave  compile-$(date +%s).log  ./compile -j 4 em_real 
echo "prepend_path(\"PATH\",\"$HOME_APPS/wrf-chem/$COMP_VERSION/WRF/main\")
setenv(\"WRF_ROOT\",\"$HOME_APPS/wrf-chem/$COMP_VERSION/WRF\")
setenv(\"WRF_DIR\",\"$HOME_APPS/wrf-chem/$COMP_VERSION/WRF\") " >> $WRF_MODULE   

_banner "WPS"
cd $HOME_APPS/wrf-chem/$COMP_VERSION 
curl -L https://github.com/wrf-model/WPS/archive/refs/tags/v4.4.tar.gz | tar xzvf -
ln -sv WPS-4.4 WPS
cd WPS-4.4
curl -LO https://raw.githubusercontent.com/pdcs-cca/compila-WRF/main/ubuntu-20-gcc/chem/configure.wps
/usr/sbin/logsave  compile-$(date +%s).log  ./compile  
mkdir bin 
cp -v *.exe bin 
echo "prepend_path(\"PATH\",\"$HOME_APPS/wrf-chem/$COMP_VERSION/WPS/bin\")
setenv(\"WPS_ROOT\",\"$HOME_APPS/wrf-chem/$COMP_VERSION/WPS\")"  >> $WRF_MODULE


