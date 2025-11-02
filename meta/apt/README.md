## Package generation using equivs

The local apt repository will only contian packages containing metadata to install 
other dependencies for the testbed. These will be updated from time to time 
to get up to date tools and patches.

The command line utility `equivs` can be used to generate metadata packages for apt. 
There are two options: generating a new empty template or generate the packages 
required for apt. `equivs-control` will generate a new template file.

A very minimalistc configuration would look like this:

```
Section: misc
Priority: optional
Homepage: https://www.las3.de
Standards-Version: 3.9.2
Package: motra-testing
Depends: iperf, ...
Architecture: all
Description: <short description; defaults to some wise words> 
 Hello
 .
 World
```

Optionally files and build dependencies could also be added to this.

To generate the final apt packages run the builder:

```
equivs-build motra-hacking 
```