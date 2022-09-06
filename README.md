# WRF Chem

~~~bash
curl -LO https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/WRF-Chem-gcc.sh
~~~
set HOME_APPS, COMPILER_NAME  and COMPILER_VERSION
~~~bash
vim  WRF-Chem-gcc.sh  

bash WRF-Chem-gcc.sh
~~~
# WRF 
~~~bash
curl -LO https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/WRF-gcc.sh
~~~
set HOME_APPS, COMPILER_NAME  and COMPILER_VERSION
~~~bash
vim  WRF-gcc.sh  

bash WRF-gcc.sh
~~~
# Test WRF Chem
~~~bash
curl -L https://raw.githubusercontent.com/pdcs-cca/build-WRF/main/wrfchem-test.tar.gz | tar xzvf  -
cd wrfchem-test
ml wrf-chem/4.4.1
ln -sv $WRF_ROOT/test/em_real/* .
mpiexec.hydra -n 8 wrf.exe 
~~~
