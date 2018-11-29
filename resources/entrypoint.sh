#!/bin/bash
# Copyright (c) 2016, Accenture All rights reserved.
# 2016/02/01 - Added run script to load configuration into ldap
# Source: https://github.com/dinkel/docker-openldap/blob/master/entrypoint.sh

# When not limiting the open file descritors limit, the memory consumption of
# slapd is absurdly high. See https://github.com/docker/docker/issues/8231
sudo ulimit -n 8192


set -e

SLAPD_LOAD_LDIFS="${SLAPD_LOAD_LDIFS},structure.ldif"

chown -R openldap:openldap /var/lib/ldap/ /var/run/slapd/

SLAPD_FORCE_RECONFIGURE="${SLAPD_FORCE_RECONFIGURE:-false}"

if [[ ! -d /etc/ldap/slapd.d || "$SLAPD_FORCE_RECONFIGURE" == "true" ]]; then

    if [[ -z "$SLAPD_PASSWORD" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_PASSWORD not set. "
        echo >&2 "Did you forget to add -e SLAPD_PASSWORD=... ?"
        exit 1
    fi

    if [[ -z "$SLAPD_DOMAIN" ]]; then
        echo -n >&2 "Error: Container not configured and SLAPD_DOMAIN not set. "
        echo >&2 "Did you forget to add -e SLAPD_DOMAIN=... ?"
        exit 1
    fi

    SLAPD_ORGANIZATION="${SLAPD_ORGANIZATION:-${SLAPD_DOMAIN}}"

    cp -a /etc/ldap.dist/* /etc/ldap

    cat <<-EOF | debconf-set-selections
        slapd slapd/no_configuration boolean false
        slapd slapd/password1 password $SLAPD_PASSWORD
        slapd slapd/password2 password $SLAPD_PASSWORD
        slapd shared/organization string $SLAPD_ORGANIZATION
        slapd slapd/domain string $SLAPD_DOMAIN
        slapd slapd/backend select HDB
        slapd slapd/allow_ldap_v2 boolean false
        slapd slapd/purge_database boolean false
        slapd slapd/move_old_database boolean true
EOF

    dpkg-reconfigure -f noninteractive slapd >/dev/null 2>&1

    dc_string=""
   
    OLD_IFS=$IFS
    IFS="."; declare -a dc_parts=($SLAPD_DOMAIN)

    for dc_part in "${dc_parts[@]}"; do
        dc_string="$dc_string,dc=$dc_part"
    done

    base_string="BASE ${dc_string:1}"

    sed -i "s/^#BASE.*/${base_string}/g" /etc/ldap/ldap.conf

    if [[ -n "$SLAPD_CONFIG_PASSWORD" ]]; then
        password_hash=`slappasswd -s "${SLAPD_CONFIG_PASSWORD}"`

        sed_safe_password_hash=${password_hash//\//\\\/}

        slapcat -n0 -F /etc/ldap/slapd.d -l /tmp/config.ldif
        sed -i "s/\(olcRootDN: cn=admin,cn=config\)/\1\nolcRootPW: ${sed_safe_password_hash}/g" /tmp/config.ldif
        rm -rf /etc/ldap/slapd.d/*
        slapadd -n0 -F /etc/ldap/slapd.d -l /tmp/config.ldif >/dev/null 2>&1
    fi
else
    slapd_configs_in_env=`env | grep 'SLAPD_'`

    if [ -n "${slapd_configs_in_env:+x}" ]; then
        echo "Info: Container already configured, therefore ignoring SLAPD_xxx environment variables"
    fi
fi
IFS=${OLD_IFS}

if [[ -n "$SLAPD_ADDITIONAL_SCHEMAS" ]]; then
    # Copy schemas from source just in case
    cp -n -a /etc/ldap.dist/schema/* /etc/ldap/schema/
	IFS=","; declare -a schemas=($SLAPD_ADDITIONAL_SCHEMAS)

	for schema in "${schemas[@]}"; do
		echo "Loading schema : $schema"
		slaptest
		set +e
		output=$(slapadd -n0 -F /etc/ldap/slapd.d -l "/etc/ldap/schema/${schema}.ldif" 2>&1)
		ret=$?
		set -e
		if [[ $ret != 0 && $(echo ${output} | grep -c "Duplicate attributeType") == 0 ]]; then
			echo "Error : unable to load schema. Message : ${output}"
			exit 1
		fi
		echo "Loaded schema : $schema"
	done
fi

if [[ -n "$SLAPD_ADDITIONAL_MODULES" ]]; then
    # Copy modules from source just in case
    cp -n -a /etc/ldap.dist/modules/* /etc/ldap/modules/
	IFS=","; declare -a modules=($SLAPD_ADDITIONAL_MODULES)

	for module in "${modules[@]}"; do
		 echo "Loading module : $module"
		 slaptest
		 module_file="/etc/ldap/modules/${module}.ldif"
		 if [ "$module" == 'ppolicy' ]; then
                        # Get the check_password configuration file if its missing.
                        cp -n -a /etc/ldap.dist/check_password.conf /etc/ldap/check_password.conf
                        # Set the default policy DN
			SLAPD_PPOLICY_DN_PREFIX="${SLAPD_PPOLICY_DN_PREFIX:-cn=default,ou=policies}"
			# Adds the structure, applies the default policy and modifies admin user policy
                        
			SLAPD_LOAD_LDIFS="${SLAPD_LOAD_LDIFS},default-ppolicy.ldif,service-users.ldif"
			sed -i "s/\(olcPPolicyDefault: \)PPOLICY_DN/\1${SLAPD_PPOLICY_DN_PREFIX},${SLAPD_FULL_DOMAIN}/g" $module_file
		 fi
		 set +e
		 output=$(slapadd -n0 -F /etc/ldap/slapd.d -l "$module_file" 2>&1)
		 ret=$?
		 set -e
		 if [[ $ret != 0 && $(echo ${output} | grep -c "already loaded") == 0 ]]; then
			echo "Error : unable to load module. Message : ${output}"
			exit 1
		 fi
		 echo "Loaded module : $module"
	done
fi
IFS=${OLD_IFS}

chown -R openldap:openldap /etc/ldap/slapd.d/

# Run script to load configuration into ldap
/usr/local/bin/ldap_init.sh ${SLAPD_LOAD_LDIFS#","}

exec "$@"
