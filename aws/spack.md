## Debian 11

~~~bash
setenv("EM_CORE","1")
setenv("NMM_CORE","0")
setenv("WRF_CHEM","1")
setenv("WRF_KPP","1")
setenv("YACC","/usr/bin/yacc -d")
setenv("FLEX_LIB_DIR","/usr/lib/x86_64-linux-gnu")
~~~
~~~python
if "+chem" in self.spec:
            env.set("WRF_CHEM", 1)
            env.set("WRF_KPP", 1)
            env.set("YACC", self.spec["bison"].prefix.bin.join("yacc -d") )
            env.set("FLEX_LIB_DIR", self.spec["flex"].prefix.lib)
~~~   

