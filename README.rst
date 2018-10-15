IxTclNetwork is the TCL package for the IxNetwork Low Level API that allows you to configure and run IxNetwork tests.

Installing
==========

* The master branch always contains the latest official release. It is only updated on new IxNetwork releases.
* The dev branch contains improvements and fixes of the current release that will go into the next release version.

To install the version in `github <https://github.com/ixiacom/ixnetwork-api-tcl>`_ :
 1. Clone the repository.
 2. Set **TCLLIBPATH** environment variable to IxTclNetwork library path from the cloned repository.

Documentation
=============
For general language documentation of IxNetwork API see the `Low Level API Guide <http://downloads.ixiacom.com/library/user_guides/ixnetwork/8.50/EA_8.50_Rev_A/QuickReferenceGuides/LLAPI_reference_guide.pdf>`_ and the `IxNetwork API Help <http://downloads.ixiacom.com/library/user_guides/ixnetwork/8.50/EA_8.50_Rev_A/IxNetwork_HTML5/IxNetwork.htm>`_.
This will require a login to `Ixia Support <https://support.ixiacom.com/user-guide>`_ web page.


IxNetwork API server / TCL Support
==================================
IxTclNetwork API lib 8.50.1501.9 supports:

* Tcl 8.5 and 8.6
* IxNetwork Windows API server 8.40+
* IxNetwork Web Edition (Linux API Server) 8.50+

Compatibility with older versions may continue to work but it is not actively supported.


Compatibility Policy
====================
IxNetwork Low Level API library is supported on the following operating systems:
    - Microsoft Windows
    - CentOS 7 on x64 platform
    
IxNetwork Low Level API library has been tried, but it is not officially supported, on the 
following operating systems/language version combinations:
    - CentOS 6.3, 6.4, 6.5 on x64 platform - Tcl 8.5
    - Arch Linux on x64 platform - Tcl 8.6
    - Free BSD 10.1 on x64 platform - Tcl 8.6
    - OS X Yosemite on x64 platform - Tcl 8.6
    

Related Projects
================
* IxNetwork API Python Bindings: https://github.com/ixiacom/ixnetwork-api-py
* IxNetwork API Perl Bindings: https://github.com/ixiacom/ixnetwork-api-pl
* IxNetwork API Ruby Bindings: https://github.com/ixiacom/ixnetwork-api-rb
