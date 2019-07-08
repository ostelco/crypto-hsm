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


This script will traverse a state machine in the sequence

     INITIAL->CSR_READY->DONE

The script uses the library "key-admin-lib.sh" to do
low level manipulations, but the state transitions and the
actual tasks are performed in the case statement below.

The script is invoked using three parameters, two of which are
given as environment variables, the third as a single command
line parameter.

The environment variables are:

   WORKFLOWS_TYPE: A token consisting of letters, numbers dash (-) and
                   lowercase characters used to name the type of
                   workflow.  e.g. "web-access-csr". This variable
                   is typically set in a wrapper script such as
                   csr-for-web-access-workflow.sh

   WORKFLOWS_PATH: Path to a location in the filesystem where the
                   state, including secrets, involved in the workflow
                   will be stored.  This variable is typically set
                   in a .profile or similar, and is assumed to be
                   available whenever scripts based on
                   csr-generating-workflow.sh is run

The single command line parameter is the name of the workflow.
It will be concatenated to the WORKFLOW_PATH to generate e
file hiearchy holding the state for the workflow, including its
secrets.

In the initial stat the script will generate a certificate signing
request (CSR), and associated key file.  This CSR file should be
extracted from the workflow directory and sent to the party that
should countersign it.

In this state we're waiting for an incoming, countersigned
certificate.  When discovered, then we'll combine it with the
keyfile and generate a PKCS12 keystore file.  This .p12 file can
then be used by whoever needs the certificate.  It may be useful
to get a copy of the signing certificate used to countersign
(the "remote ca-cert" file), so that it can be put in the list
of # trusted certificates.  However, this requirement can be
bypassed by declaring the certificate in .p12 as trusted.

The .p12 certificate will be "protected" by a password
(because, it has to, and the feature can't as far as I know
be switched off).  That password is generated automatically, and
will be "secret$workflow" where "$workflow" is the name of the
workflow associated with the signing process.

A jks (java keystore) file will also be generated, but that is
not a result to be trusted.  It currently doesn't seem to work
in the sense that when a java program tries to use it for crypto,
it will crash rather than work.   The password for the
jks is set to the string "foobar".

From the above it should be understood that not much trust is
put into the practice of protecting keystores with passwords.

Currently this script will _NOT_ progress to a "DONE" state, but will
indefinitely be  in a  CSR_READY state.  This is for debugging
purposes, but also shouldn't be much of a concern as applying the
operations in the CSR_READY state shouls be idempotent, generating the
exacte same output every time it is invoked.

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


Some more details:

Since we are waiting for a  CSR coming from Idemia, we will
immediately transition to the "WAITING_FOR_CSR" state
Looking for a CSR coming in from idemia.  If we get
to that state (meaning we see an incoming .csr.pem file),
we will countersign it and send it back to its origin.
 We will also make a file called the "CERTIFICATE_CHAIN_DOC" that
contains both the signed CSR and the signing CRT that was used
to countersign.  This file should then be used by
the reverse proxy (envoy or other) that terminates the incoming
SSL connection.  Finally some information is printed about the
certificate, and the state machine is put into state DONE
meaning that further invocations will have no effect.



key-admin-lib.sh
--

A shell script library intended to manipulate cryptograhic
certificates, signing requests, keys, and associated objects.
