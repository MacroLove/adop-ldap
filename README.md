#Supported tags and respective Dockerfile links

- [`0.2.0`, `0.2.0` (*0.2.0/Dockerfile*)](https://github.com/Accenture/adop-ldap/blob/0.2.0/Dockerfile)

# What is adop-ldap?

adop-ldap is a wrapper for the dinkel/openldap image. It has primarily been built to perform extended configuration.
OpenLDAP Software is an open source implementation of the Lightweight Directory Access Protocol.

# How to use this image

The easiest way to run adop-ldap image is as follow:
```
docker run --name <your-container-name> -d -p 389:389 accenture/adop-ldap:VERSION
```

Runtime configuration can be provided using environment variables:

* `SLAPD_PASSWORD`, the LDAP admin password. Default to Jpk66g63ZifGYIcShSGM
* `SLAPD_DOMAIN`, the LDAP domain. Default to ldap.example.com
* `SLAPD_FULL_DOMAIN`, the LDAP BASE_DN. Default to dc=ldap,dc=example,dc=com
* `INITIAL_ADMIN_USER`, the initial LDAP user name with administrator rights
* `INITIAL_ADMIN_PASSWORD`, the password for the initial administrator user
* `SLAPD_ADDITIONAL_SCHEMAS`, loads additional schemas provided in the `slapd` package that are not installed using the environment variable with comma-separated enties. As of writing these instructions, there are the following additional schemas available: `collective`, `corba`, `duaconf`, `dyngroup`, `java`, `misc`, `openldap`, `pmi` and `ppolicy`.
* `SLAPD_ADDITIONAL_MODULES`, comma-separated list of modules to load. It will try to run `.ldif` files with a corresponsing name from the `module` directory. Currently only `memberof` and `ppolicy` are avaliable.
* `SLAPD_PPOLICY_DN_PREFIX` - (defaults to `cn=default,ou=policies`) sets the dn prefix used in `modules/ppolicy.ldif` for the `olcPPolicyDefault` attribute.  The value used for `olcPPolicyDefault` is derived from `$SLAPD_PPOLICY_DN_PREFIX,(dc component parts from $SLAPD_DOMAIN)`.
* `SLAPD_LDIF_BASE`, the base directory where from ldifs can be loaded. Default to "/var/tmp/ldifs".
* `SLAPD_LOAD_LDIFS`, comma-separated list of ldifs you want to load from ldifs base. This will assume that ldifs are available in SLAPD_LDIF_BASE.


# LDAP Password Policy

This image enforces password policies for ldap users to include password ageing and failures. There are two policies added in this image -

* **default** : Default policy is applied to all the accounts which haven't got _pwdPolicySubentry_ operational attribute. 
* **service-users** : This policy is applied to service accounts like Jenkins, GitLab and Nexus.

**Note** : Password policies also include the password complexity using password checker module and following rules are applied -

* Minimum length: 9
* Maximum length: no limit
* Minimum number of lowercase characters: 6
* Minimum number of uppercase characters: 1
* Minimum number of digits: 1
* Minimum number of punctuations: 1
* Your new password can not be the same as your old password 


# License
Please view [licence information](LICENCE.md) for the software contained on this image.

#Supported Docker versions

This image is officially supported on Docker version 1.9.1.
Support for older versions (down to 1.6) is provided on a best-effort basis.

# User feedback

## Documentation
Documentation for this image is available in the [SLAPD documenation page](http://www.openldap.org/software/man.cgi?query=slapd). 
Additional documentaion can be found under the [`docker-library/docs` GitHub repo](https://github.com/docker-library/docs). Be sure to familiarize yourself with the [repository's `README.md` file](https://github.com/docker-library/docs/blob/master/README.md) before attempting a pull request.

## Issues
If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/Accenture/adop-ldap/issues).

## Contribute
You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/Accenture/adop-ldap/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
