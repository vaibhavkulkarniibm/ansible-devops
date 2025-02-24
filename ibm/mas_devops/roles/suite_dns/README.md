suite_dns
=========

This role will manage MAS and DNS provider integration.  IBM Cloud Internet Services is the only supported DNS provider currently.

### Cloud Internet Services (CIS)
This role will create DNS entries automatically in the CIS service instance.  Two different modes are available:

#### Top Level DNS entries
This mode will create the entries directly using your DNS zone value. It is usually recommended when you have 1x1 relationship between MAS Instance -> CIS service. e.g: mas.whirlpool.com, where the domain matches exactly the CIS zone name.

#### Subdomain DNS entries
This mode will create entries using a subdomain. It allows you to have multiple MAS instances using same CIS service. e.g: dev.mas.whirlpool.com, where 'dev' is the subdomain.

#### Webhook
The Webhook Task will deploy a cert-manager webhook for CIS integration.  The webhook is responsible for managent the certificate challenge requests from letsencrypt and CIS.  This task will also create two ClusterIssuers by default, pointing to Staging & Production LetsEncrypt servers.

!!! note
    There are issues with how cert-manager works with LetsEncrypt staging servers. We end up with a secret for the certificate that doesn't contain the LetsEncrypt CA; but the staging service does not use a well known cert, so we end up with MAS unable to trust the certificates generated by LetsEncrypt staging.

    At present there is no workaround for this, so do not use the LetsEncrypt staging certificate issuer.


Role Variables
--------------

TODO: Finish documentation


Example Playbook
----------------

```yaml
---
- hosts: localhost
  any_errors_fatal: true
  vars:
    # Choose which catalog source to use for the MAS install, default to the IBM operator catalog
    mas_catalog_source: "{{ lookup('env', 'MAS_CATALOG_SOURCE') | default('ibm-operator-catalog', true) }}"

    # Which MAS channel to subscribe to
    mas_channel: "{{ lookup('env', 'MAS_CHANNEL') | default('8.x', true) }}"

    # MAS configuration
    custom_domain: "{{ lookup('env', 'MAS_DOMAIN') | default(None)}}"
    mas_instance_id: "{{ lookup('env', 'MAS_INSTANCE_ID') }}"

    # MAS configuration - Entitlement
    mas_entitlement_key: "{{ lookup('env', 'MAS_ENTITLEMENT_KEY') }}"

    # --- DNS settings ----------------------------------------------------------------------------------------
    # you can obtain CRN from overview page of your CIS service in IBM Cloud
    cis_crn: "{{ lookup('env', 'CIS_CRN') }}"
    # Domain prefix is whatever you want to append to your DNS entry to make it unique
    cis_subdomain: "{{ lookup('env', 'CIS_SUBDOMAIN') }}"
    # generate a Service ID apikey in IBM Cloud for strict access to the 'Internet Services` service with
    # an 'Access Policy' of Editor/Manager
    cis_apikey: "{{ lookup('env', 'CIS_APIKEY') | default(lookup('env', 'IBMCLOUD_APIKEY'), true) }}"

    # Email used register letsencrypt certificates and receive cert notifications
    cis_email: "{{ lookup('env', 'CIS_EMAIL') }}"
    # Skip DNS entries creation
    cis_skip_dns_entries: "{{ lookup('env', 'CIS_SKIP_DNS_ENTRIES') | default(false, true) }}"
    # Skip CIS cluster issuer creation, in case you just want to create the DNS entries
    cis_skip_cluster_issuer: "{{ lookup('env', 'CIS_SKIP_CLUSTER_ISSUER') | default(false, true) }}"
    # Do you want to update a DNS entry if it already exists?
    update_dns: "{{ lookup('env', 'UPDATE_DNS_ENTRIES') | default(true, true) }}"
    # e.g: "apps.joaopauloksn.cp.fyre.ibm.com" Default will be always from cluster ingress CR.
    custom_ocp_ingress: "{{ lookup('env', 'OCP_INGRESS') | default(None, true)}}"

    # If cis, custom_cluster_issuer = cis-letsencrypt-production-{{ mas_instance_id }}
    # If PKI, custom_cluster_issuer = MAS_CUSTOM_CLUSTER_ISSUER
    # If not specified, custom_cluster_issuer = autogenerated
    default_custom_cluster_issuer: "'cis-letsencrypt-production-{{ mas_instance_id }}"
    custom_cluster_issuer: "{{ (cis_crn != '') | ternary (lookup('env', 'MAS_CUSTOM_CLUSTER_ISSUER') | default(default_custom_cluster_issuer, true), lookup('env', 'MAS_CUSTOM_CLUSTER_ISSUER') | default(None, true)) }}"
    certificate_duration: "{{ lookup('env', 'CERTIFICATE_DURATION') | default('8760h0m0s', true) }}"
    certificate_renew_before: "{{ lookup('env', 'CERTIFICATE_RENEW_BEFORE') | default('720h0m0s', true) }}"

    mas_config_dir: "{{ lookup('env', 'MAS_CONFIG_DIR') }}"

  roles:
    - ibm.mas_devops.suite_dns
    - ibm.mas_devops.suite_install
    - ibm.mas_devops.suite_config
    - ibm.mas_devops.suite_verify
```

License
-------

EPL-2.0
