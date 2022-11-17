#!/bin/bash 
#
# pdcs at atmosfera.unam.mx
# copyright Universidad Nacional Autonoma de Mexico 2022 
#
# Para instalación de compiladores de intel ubuntu/debia: 
#https://www.intel.com/content/www/us/en/develop/documentation/installation-guide-for-intel-oneapi-toolkits-linux/top/installation/install-using-package-managers/apt.html#apt

export HOME_APPS=$PWD #$HOME/software/apps
export COMPILER_NAME=intel 
export COMPILER_VERSION= #2021u5
export COMP_VERSION=$COMPILER_NAME/$COMPILER_VERSION

export CC=icc FC=ifort F77=ifort F90=ifort CXX=icpc
export COMPFLAGS_OPT="-ip -fPIC -fp-model precise"

export CFLAGS="$COMPFLAGS_OPT" CXXFLAGS="$COMPFLAGS_OPT" FFLAGS="$COMPFLAGS_OPT" FCFLAGS="$COMPFLAGS_OPT"


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
test $APP_NAME == "netcdf-c" && echo "setenv(\"NETCDF\",base)" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua 
test $APP_NAME == "netcdf-c" && echo "setenv(\"USENETCDFPAR\",\"0\")" >> $HOME_APPS/modulefiles/${MODULE_FILE}.lua 

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
./configure $@ || bash 
make -j4 || bash 
test ! -z "$CHECK" && make -j4 check
make install
_modulo $APP_NAME $APP_VERSION
}

_build-wrf(){

test  -e $WRF_ROOT/main/real.exe -a  -e $WRF_ROOT/main/wrf.exe -a -e $WRF_ROOT/main/ndown.exe -a -e  $WRF_ROOT/main/tc.exe && return 0

mkdir -pv $WRF_ROOT
cd $WRF_ROOT
curl -L https://github.com/wrf-model/WRF/releases/download/v4.4.1/v4.4.1.tar.gz | tar --strip-components=1  -xzvf - 
sed -i 's/FALSE/TRUE/' arch/Config.pl 
curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-intel/configure-intel.wrf > configure.wrf
/usr/sbin/logsave  compile-$(date +%s).log  ./compile -j 4 em_real 
test ! -e main/real.exe && _banner "Error !!! real.exe" && exit 1
test ! -e main/wrf.exe && _banner "Error !!! wrf.exe" && exit 1
}

_build-wps(){

test -L $WPS_ROOT/geogrid.exe -a -L $WPS_ROOT/metgrid.exe -a -L $WPS_ROOT/ungrib.exe && return 0
mkdir -pv $WPS_ROOT
cd $WPS_ROOT 
curl -L https://github.com/wrf-model/WPS/archive/refs/tags/v4.4.tar.gz | tar --strip-components=1  -xzvf -
curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/configure-intel/configure-intel.wps > configure.wps
/usr/sbin/logsave  compile-$(date +%s).log  ./compile  
test ! -d bin && mkdir bin 
test ! -L geogrid.exe && _banner "Error !!! geogrid.exe" && exit 1 
test ! -L metgrid.exe && _banner "Error !!! metgrid.exe" && exit 1 
test ! -L ungrib.exe && _banner "Error !!! ungrib.exe" && exit 1 
cp -v *.exe bin  
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

for var in $CC $FC $F77 $F90 $CXX ; 
    do   echo "test compiler --version"
        stat -c "%a %N" $(type -p $var)  || exit 0 
done

#####
#sudo apt -y install gfortran gcc make tcsh flex curl axel vim htop bison mpich libssl-dev mc git tmux figlet
#ml purge || sudo apt -y install lmod
#test -e /etc/profile.d/lmod.sh &&  source /etc/profile.d/lmod.sh

_banner "WRF 4.4.1"
#ml purge 
export WRF_ROOT=$HOME_APPS/wrf/$COMP_VERSION/WRF
export WPS_ROOT=$HOME_APPS/wrf/$COMP_VERSION/WPS

mkdir -pv $HOME_APPS/modulefiles 
mkdir -pv $HOME_APPS/modulefiles/wrf
WRF_MODULE=$HOME_APPS/modulefiles/wrf/4.4.1.lua 

#####
#test -e /etc/lmod/modulespath && sudo sh -c "echo $HOME_APPS/modulefiles > /etc/lmod/modulespath "
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
test ! -d $APP_INSTALL && mkdir $APP_INSTALL
ml $MODULE_FILE
ml
echo "load(\"$MODULE_FILE\")" >> $WRF_MODULE

_banner "WRF"
_build-wrf
echo "prepend_path(\"PATH\",\"$WRF_ROOT/main\")
setenv(\"WRF_ROOT\",\"$WRF_ROOT\")
setenv(\"WRF_DIR\",\"$WRF_ROOT\") " >> $WRF_MODULE   


_banner "WPS"
_build-wps
echo "prepend_path(\"PATH\",\"$WPS_ROOT/bin\")
setenv(\"WPS_ROOT\",\"$WPS_ROOT\")"  >> $WRF_MODULE

