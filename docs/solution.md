# Solution

> According to [The Twelve Factor App](https://12factor.net/config) we can store _config_ in the environment. Here _config_ could be connection strings to databases and/or credentials to other external services.

 Taking our [Considerations](/#considerations) and the above into account we have settled on the following:

* __[AWS Systems Manager Parameter Store](/parameter-store)__, as a secure and central storage for secrets. Secrets are stored as parameters (key/value pairs containing secret name and value).
* __[Kubernete Secrets](https://kubernetes.io/docs/concepts/configuration/secret)__ to store application secrets that can either be mounted as files or exposed as environment variables to be used by a container in a pod.
* Use a custom __Security Manager__ component to automatically manage the lifecycle (create, update, delete) of secrets.
* Leverage the current Kubernetes security setup, using assumed roles and KIAM.

### Component Overview

```
╔═════════════════╗         ╔═════════════════════╗  
║ Parameter Store ║◄────────║ Secrets/credentials ║  
╚═════════════════╝  «put»  ╚═════════════════════╝  
         ▲                    
         │        ╔═══════════════════════════════════════════════╗
         │        ║               Kubernetes Cluster              ║
         │        ║ ╔═══════════════════════════════════════════╗ ║
         │        ║ ║                Namespace                  ║ ║
         │ «read» ║ ║   ╔════════════════╗            ╔═════╗   ║ ║
         └────────║─║───║ Secret Manager ║            ║ POD ║   ║ ║
                  ║ ║   ╚════════════════╝            ╚═════╝   ║ ║
                  ║ ║            │                       ▲      ║ ║
                  ║ ║     «sync» │    ╔════════╗         │      ║ ║
                  ║ ║            └───►║ SECRET ║─────────┘      ║ ║
                  ║ ║                 ╚════════╝ «expose»       ║ ║
                  ║ ╚═══════════════════════════════════════════╝ ║
                  ╚═══════════════════════════════════════════════╝


```

* __Secrets/credentials__ could literally be anything, but will most likely be a combination of coordinates (i.e. URI) and credentials for either managed services (e.g. provisioned using Terraform), or some external source (third-party managed).
* __Parameter Store__ is the [AWS Systems Manager Parameter Store](/parameter-store).
* __[Secret Manager](#secret-manager)__ takes care of synchronizing secrets between systems.
* The __SECRET__ is a collection of key/value pairs that are collected in a single Kubernetes secret that is either mounted as a file or exposed as environment variables in a __POD__.

### Secret Manager

The Secret Manager is an infrastructure component running in the same namespace as the __POD__ above, with AWS access rights (kiam) to pull parameters from __Parameter Store__.

It will, at regular intervals, pull stored parameters stored according to access rights and [Conventions](/usage#conventions), and synchronize these with Kubernetes secrets according to these conventions.

!!! important "Note"
    *Only secrets created by the Secret Manager are managed, all other secrets will be left untouched.*

## Alternatives

Below is a list of some of the alternatives that have been tried/considered:

* Sealed Secrets (secrets are encrypted and then included in the codebases)
* Vault (free, highly scalable, unmanged)
* AWS Secrets Manager (paid)
* Cloud KMS (paid)
* Azure Key Vault (paid)
* {== others? ==}
