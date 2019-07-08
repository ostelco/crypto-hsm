# crypto-hsm

Crypto and HSM management scripts.
==

The intent is to have scripts that in a repeatable manner generate and
manipulate certificate signing requests.

We will later transition all of the work done here into something that is
managed by a HSM and possibly hashicorp vault.

... however, that will be later, for now we need to know what the current
code is doing.   We'll do that by describing file by file:


README.md
-- 

this file

LICENSE
--

This code is licensed using ther Apache 2.0 license.  That said, this
code is being kept in a _closed_ repository since it may contain
sensitive information, like phone numbers.  The code should not be
open sourced until all information  in it is confirmed to be non-sensitive.

smdp-utils
==

This directory contains a set of helper scripts that has been written
in order to add sim profiles into sm-dp+, the sim database of prime,
and HSS.  They are all intended to substitute for functions that
should by design be parts of Prime, but at the time of writing were
not used.

endpoint-smoketest.sh
--

A simple script that will test talking to an sm-dp+ using the ES2+ protocol.


extract-non-golden-msisdns.awk
--

Takes a sequence of triples of iccid, imsi, msisdn, and will only 
let through triples where the msisdn is _not_ ending with four
zeros or four nines.   Numbers matching these patterns are called
"golden" and should in general not be used by our service.


generate-import-scripts.sh
--
A wrapper code that will invoke a go language script to generate 
shell scripts that will import imsi/iccid/msisdn tripes into the
prime subsystem.    This code was written as a helper to
systematically generate import scripts from the data found in the
spreadsheet we use to keep track of the sim profile batches. It is
very much ad-hoc, but also intended to keep the state outside the
heads of the operators, but in the scdripts they use.

The import-scripts are put in a directory calledf "result".


generate-sql-for-activation-code-updates.sh
--

Given a list of ICCIDs, generate an sql script that  will update the
database of Prime so that all the ICCIDs are marked as available for
allocations by users.      This is to bypass the mechanism already
inside Prime to activate profiles in SM-DP+, to compensate for the facdt
at the time of writing (juli 2019) the cryptographic certificates used
to contacdt the SM-DP+  It is a field expedient weapon, designed to
get a job done, not for aestethic enjoyment.

process-iccids.sh
--

Given a list of ICCIDs, will contact the SM-DP+ and  activate the
profiles associated with the ICCIDs


spawner.sh
--

process-iccids.sh can process about one iccid per second.   This is
slow.   In order to process more iccids per second, the spawner was
written.  The spawner will fire off many proccess-iccid.sh scripts in
parallell so that many more iccids are processed per second.


update-profile.sh
--

A copy of the update-profile.sh script that was originally developed,
in a different repository, i order to test out assumptions about ES2+
and the connections to SM-DP+ using two-way TLS.  

It has since been used as  kind of swiss army knife for doing things
with sim profiles both with sm-dp+ and with HSS activation.


src
===

The code in this directory is used to create and distribute secrets
used for accessing the sm-dp+, and also to configure secrets used by
the kubernetes clusters running prime.

csr-for-es2plus-prime-certificate.sh
--

High level script for generating  certificates to be used when using a web
browser to access SM-DP+ from the prime.


     csr-for-es2plus-prime-certificate.sh workflow-name

The workflow-name is the name that will be associated with both the
certificates being generated and the workflow used to generate it.

csr-for-web-access-workflow.sh
--


High level script for generating  certificates to be used when using a web
browser to access the web user interface.  Typical usage is:


     csr-for-web-access-workflow.sh workflow-name

The workflow-name is the name that will be associated with both the
certificates being generated and the workflow used to generate it.



csr-generating-workflow.sh
--

An implementation of the basic csr (certificate signing request)
workflow.  That workflow is used to generated fully signed and
countersigned crypographic X.509 certificates used for TLS (Transport
Lever Security) authentication


deploy-secrets.sh
--
Deploy secrets into a kubernetes cluster intended for running Prime.


idemia-es2-client-certificate-for-return-channel-workflow.sh
--

High level script for generating scripts to be used by Prime when
receiving TLS authenticated connections coming in from the SM-DP+.
THe usage is

     idemia-es2-client-certificate-for-return-channel-workflow.sh  workflow-name

The workflow-name is the name that will be associated with both the
certificates being generated and the workflow used to generate it.



key-admin-lib.sh
--

A shell script library intended to manipulate cryptograhic
certificates, signing requests, keys, and associated objects.





