# Secrets

Secrets, including credentials, are handled thus:

## Goals/Considerations/Requirements

* __NO__ plain text secrets (credentials, or otherwise) in any codebase.
* Play nice together with our current Kubernetes security setup (assumed roles and kiam) {== external link perhaps? ==}.
* Facilitate our current take on Kubernetes (one capability/team/project/microservice ecosystem/namespace).
* API enabled.
* Terraform(able).
* Free (as in no subscription charge).
* No code.
* Use Kubernetes concepts.
* {== others? ==}
* Does not need to emcompass other configurations (e.g. feature toggles)
* Easy to manage and deliver secrets

{>>KIAM - Integrate AWS IAM with Kubernetes<<}

!!! note "Alternatives"
    Below is a list of some of the alternatives that have been tried/considered:

    * Sealed Secrets (secrets are encrypted and then included in the codebases)
    * Vault (free, highly scalable, unmanged)
    * AWS Secrets Manager (paid)
    * Cloud KMS (paid)
    * Azure Key Vault (paid)
    * {== others? ==}

## Secret Management

What we would like to achieve is an easy way for application developers to store and manage secrets in secure fashion, while at the same time give applications access to the secrets through standard Kubernetes features, and without using custom code to fetch remote secrets on application startup.

This has led us to identity the following needs:

* A central cloud storage for secrets.
* Kubernetes secrets, with automatic lifecycle management (create, update, delete).
* AWS IAM access level control, using roles-
* {== others? ==}

Overview of the current working solution:

```

 ╔════════════════════╗
 ║ Secret Sources...¹ ║
 ╚════════════════════╝
           │
╔══════╗   │  ╔═══════════════════════════════════════╗
║ SSM² ║◄──┘  ║               Kubernetes³             ║
╚══════╝      ║               ‾‾‾‾‾‾‾‾‾‾              ║
   ▲          ║ ╔═══════════════════════════════════╗ ║
   │          ║ ║             Capability⁴           ║ ║
   │          ║ ║             ‾‾‾‾‾‾‾‾‾‾            ║ ║
   │          ║ ║  ╔══════╗  ╔═════════╗  ╔══════╗  ║ ║
   └──────────║─║─►║  SM⁷ ║─►║ SECRET⁵ ║─►║ POD⁶ ║  ║ ║
              ║ ║  ╚══════╝  ╚═════════╝  ╚══════╝  ║ ║
              ║ ╚═══════════════════════════════════╝ ║
              ╚═══════════════════════════════════════╝

```

Components:

1. _Secret Sources_ could literally be anything, but will most likely be a combination of coordinates (i.e. URI) and credentials for either managed services provisioned using Terraform, or some external source (third-party managed).
2. _SSM_ is AWS Systems Manager Parameter Store (see info box below)
3. Our _Kubernetes_ cluster.
4. _Capability_ is the current level of granularity regarding workspace allocation. This currently aligns with namespace in Kubernetes. {==We need explanation here - maybe something about microservice ecosystem! ==}
5. _SECRET_ is a collection of key/value pairs that are collected in a single Kubernetes secret. The secrets can then be configured in the pod (or deployment) manifest, in order for an application/microservice to gain access to their values. This can be as environment variable and/or file mounts. An example is listed below.
6. The _POD_ contains the application/microservice that whats access to the secret.
7. _SM_, or [Secret Manager](#secret-manager).

!!! info "AWS Systems Manager Parameter Store"
    The _Parameter Store_ is a secure, scalable, and managed configuration store that allows storage of data in hierarchies and track versions. It integrates into other AWS offerings (include AWS Lambda), and offers control and audit access at granular levels.

## Secret Manager

The Secret Manager is an infrastructure component running in the same namespace as the _POD⁶_ above, with AWS access rights (kiam) to pull secrets from _SSM²_.

It will, at regular intervals, pull secrets from _SSM²_ according to access rights and [conventions](#conventions), and manage secrets according to these conventions. Thus keeping everything in sync.

!!! info "NB"
    *Only secrets created by the Secret Manager are managed, all other secrets will be left untouched.*

## Conventions

The management of secrets are controlled by the use of conventions. We operate with the following conventions that will be used to synchronize secrets between system.

* __Capability__

      Our current scope for a workspace is the Capability, which roughly translates to a {== team/project/product ==} that own an microservice ecosystem, which again (presently) translates to a namespace in Kubernetes.

* __Environment__

      In order to operate with different environments {>> YAGNI? <<}, we reserve a placeholder for this. However, this will default to _prod_ for now. {>> Huh? <<}

* __Application__

      The name of the application that requires secrets.

* __Secret Key__

      The name of the secret

Together these four conventions, allow us to manage secrets in SSM, and propagate these SSM parameters (based on conventions and readily available attribute in Kubernetes) to PODs and applications in the form of Kubernetes secrets.

### AWS SSM Parameter Store

Secrets are using the hierarchy availble in the Parameter Store to support the conventions.

* name: /capability/environment/application/key
* value: *the secret*
* {== Required IAM policy ==}

### Kubernetes

Secrets are created and maintained in Kubernetes based on the following convetions:

* target_namespace: capability
* secret_name: environment_application_secret
* content:
      * key: value
      * key: value
      * ...

## Consuming Secrets in Kubernetes

### Targets

- Environment variable
- Files (certificates, etc)

### Example kubernetes manifests

