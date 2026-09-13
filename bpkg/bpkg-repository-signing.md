# bpkg-repository-signing -- how to sign a repository

## Synopsis

```
bpkg rep-create --key ...
```

## Overview

The purpose of signing a repository is to prevent tampering with packages either during transmission or on the repository _host machine_. Ideally, you would generate and sign the repository manifests on a separate _build machine_ that is behind a firewall. This way, if (or, really, when) your host machine is compromised, it will be difficult for an attacker to compromise the repository packages without being noticed. Since the repository key is kept on the build machine (or, better yet, on a _one-way_ PIV/PKCS#11 device; see below) they will not be able to re-sign the modified repository.

`bpkg` uses X.509 public key cryptography for repository signing. Currently, only the explicit _first use_ certificate authentication is implemented. That is, for an unknown (to this `bpkg` configuration) repository certificate its subject information and fingerprint are presented to the user. If the user confirms the authenticity of the certificate, then it is added to the configuration and any repository that in the future presents this certificate is trusted without further confirmations, provided its name matches the certificate's subject (see below). In the future a certificate authority (CA)-based model may be added.

The rest of this guide shows how to create a key/certificate pair for `pkg` repository signing and use it to sign a repository. At the end it also briefly explains how to store the private key on a PIV/PKCS#11 device using Yubikey 4 as an example.

## Signing Steps

### 1. Generate Private Key

The first step is to generate the private key:

```
$ openssl genrsa -aes256 2048 >key.pem
```

If you would like to generate a key without password protection (not a good idea except for testing), leave the `-aes256` option out. You may also need to add `-nodes` depending on your `openssl(1)` configuration.

### 2. Generate Certificate

Next create the certificate configuration file by saving the following into `cert.conf`. You may want to keep it around in case you need to renew an expired certificate, etc.

```
name  = example.com
org   = Example, Inc
email = admin@example.com

[req]
distinguished_name = req_distinguished_name
x509_extensions    = v3_req
prompt             = no
utf8               = yes

[req_distinguished_name]
O  = $org
CN = name:$name

[v3_req]
keyUsage         = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
subjectAltName   = email:$email
```

Adjust the first three lines to match your details. If the repository is hosted by an organization, use the organization's name for `org`. If you host it as an individual, put your full, real name there. Using any kind of aliases or nicknames is a bad idea (except, again, for testing). Remember, users of your repository will be presented with this information and if they see it was signed by someone named SmellySnook, they will unlikely trust it. Also use a working email address in case users need to contact you about issues with your certificate. Note that the `name:` prefix in the `CN` value is not a typo.

The `name` field is a canonical repository name prefix with the `pkg:` type part stripped. Any repository with a canonical name that starts with this prefix can be authenticated by this certificate (see the [Repository Manifest](bpkg-repository-manifest-reference.md#repository-manifest) reference for how a repository's canonical name relates to its `location`). For example, name `example.com` will match any repository hosted on `{,www.,pkg.,bpkg.}example.com`. While name `example.com/math` will match `{...}example.com/pkg/1/math` but not `{...}example.com/pkg/1/misc`.

A certificate name can also contain a subdomain wildcard. A wildcard name in the `*.example.com` form matches any single-level subdomain, for example `foo.example.com` but not `foo.bar.example.com`. A wildcard name in the `**.example.com` form matches any subdomain, including multi-level. The above two forms do not match the domain itself (`example.com` in the above example). If this is desired, the `*example.com` and `**example.com` forms should be used instead. Note that these forms still only match subdomains. In other words, they will not match `fooexample.com`. Wildcard names are less secure and therefore are normally only used for testing and/or internal repositories.

Once the configuration file is ready, generate the certificate:

```
openssl req -x509 -new -sha256 -key key.pem \
  -config cert.conf -days 730 >cert.pem
```

To verify the certificate information, run:

```
openssl x509 -noout -nameopt RFC2253,sep_multiline \
  -subject -dates -email <cert.pem
```

### 3. Add Certificate to Repository

Add the `certificate:` field for the base repository (`role: base`) in the `repositories` manifest file(s):

```
certificate:
\
<cert>
\
```

Replace _cert_ with the entire contents of `cert.pem` (including the `BEGIN CERTIFICATE` and `END CERTIFICATE` lines). So you will have an entry like this:

```
certificate:
\
-----BEGIN CERTIFICATE-----
MIIDQjCCAiqgAwIBAgIJAIUgsIqSnesGMA0GCSqGSIb3DQEBCwUAMDkxFzAVBgNV
.
.
.
+NOVBamEvjn58ZcLfWh2oKee7ulIZg==
-----END CERTIFICATE-----
\
```

### 4. Sign Repository

When generating the repository manifests with the `rep-create` command, specify the path to `key.pem` with the `--key` option:

```
bpkg rep-create --key /path/to/key.pem /path/to/repository
```

You will be prompted for a password to unlock the private key.

### 5. Using PIV/PKCS#11 Device

This optional step shows how to load the private key into Yubikey 4 and then use it instead of the private key itself for signing the repository. Note that you will need OpenSSL 1.0.2 or later for the signing part to work.

First change the Yubikey MKEY, PUK, and PIN if necessary. You should definitely do this if it still has the factory defaults. Then import the private key and the certificate into Yubikey (replace _mkey_ with the management key):

```
yubico-piv-tool --key=<mkey> -a import-key -s 9c <key.pem
yubico-piv-tool --key=<mkey> -a import-certificate -s 9c <cert.pem
```

After this you will normally save the certificate/private key onto backup media, store it in a secure, offline location, and remove the key from the build machine.

To sign the repository with Yubikey specify the following options instead of just `--key` as at step 4 (`"SIGN key"` is the label for the slot `9c` private key):

```
bpkg rep-create                                                     \
  --openssl-option pkeyutl:-engine --openssl-option pkeyutl:pkcs11  \
  --openssl-option pkeyutl:-keyform --openssl-option pkeyutl:engine \
  --key "pkcs11:object=SIGN%20key" /path/to/repository
```

Note that for `openssl` versions prior to `3.0.0` `bpkg` uses the `rsautl` command instead of `pkeyutl` for the data signing operation.

## See Also

- [bpkg README](README.md)
- [bpkg-rep-add](bpkg-rep-add.md)
- [bpkg-rep-create](bpkg-rep-create.md)
- [bpkg-repository-manifest-reference](bpkg-repository-manifest-reference.md)
