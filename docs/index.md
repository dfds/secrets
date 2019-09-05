# Introduction

This guide contains:

* The [Considerations](#considerations) for managing application secrets in a secure fashion.
* A description of the implemented [Solution](/solution).
* A walkthrough, or Developers for [Setup](/setup) and [Usage](/usage).

## Considerations

* __NO__ plain text secrets (credentials, or otherwise) in any codebase.
* Utilize Kubernetes concepts.
* No code/low code.
* Managed.
* Support Terraform.
* Free (as in no subscription charge).
* Integrate with DFDS Kubernetes security (assumed roles and kiam) {== external link perhaps? ==}.
* {== others? ==}

__In summary__: We need a way for application developers to safely store and easily retrieve secrets, utilizing standard Kubernetes concepts, and without using custom code to fetch remote secrets on application startup.
