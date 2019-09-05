# Usage

Here you will find:

- How to [Create, Update & Delete Secrets](#create-update-delete-secrets).
- The [Conventions](#conventions) used for synchronizing secrets between Kubernetes and Parameter Store.
- How to [Using Secrets in Kubernetes](#using-secrets-in-kubernetes).

## Create, Update & Delete Secrets

Secrets are kept in the Parameter Store. There are numerous ways to create, update and delete these secrets, including, but not exclusive to:

* Through the [AWS Console](https://console.aws.amazon.com/systems-manager/parameters).
* Using the [AWS Command Line Interface](https://aws.amazon.com/cli/).
* Using Terraform.
* Using the [SecretManagerCLI](#secretmanagercli).

It is beyond this guide to go into details with every way of maintaining secrets in Parameter Store, but for convenience the [SecretManagerCLI](#secretmanagercli) will be given as an example.

### SecretManagerCLI

!!! hint "Installation"
    Go to [GitHub](https://github.com/thofisch/ssm2k8s) and follow the install instructions.

List all secrets:

```bash
./secrets list
```

Create/update secrets:

```bash
# create a single secret with multiple keys
./secrets put foo-service KEY1=value1 KEY2=value2

# create a single secret with a single key
./secrets put foo-service-kafka-prod KEY1=value1

# update KEY2 for secret foo-service
./secrets put foo-service KEY2=value2 --overwrite
```

_use `--overwrite` to overwrite exising secrets_

Delete secrets:

```bash
# delete KEY1 and KEY2 from secret
./secrets put foo-service KEY1=value1 KEY2=value2
```

!!! tip "Deleting secrets"
    If all the keys for a secret is delete the secret itself will be deleted, upon synchronization.

## Conventions

The hierarchical nature of Parameter Store[^1] allows for a simple way of naming and grouping secrets. Parameters can be organized according to a path (e.g. `/foo/bar/baz`). 

To enable automatic synchronization of secrets between Parameter Store and Kubernetes, use the following convetions when naming parameters:

!!! important "Parameter Naming Convention"
    ```xml
    /<application>[/paths...]/<key>
    ```

    * __`#!xml <application>` (required)__: The name of the application the secrets belongs to.
    * __[/paths...] (optional)__: Can be used to additionaly subclass the secret name/usage. This could e.g. be `kafka/prod` to specify a Kafka production secret.
    * __`#!xml <key>` (required)__: The name[^1] of the secret.

---

### Examples

| Parameter Name   | Kubernetes Secret Name | Kubernetes Secret Keys |
|------------------|------------------------|------------------------|
| `/foo/bar`       | `foo`                  | `bar`                  |

_Result: A single Kubernetes secret named `foo` with a single entry `bar`_

---

| Parameter Name   | Kubernetes Secret Name | Kubernetes Secret Keys |
|------------------|------------------------|------------------------|
| `/foo/prod/bar`  | `foo-prod`             | `bar`                  |
| `/foo/test/bar`  | `foo-test`             | `bar`                  |

_Result: Two Kubernetes secrets named `foo-prod` and `foo-test`, each with a single entry `bar`_

---

| Parameter Name   | Kubernetes Secret Name | Kubernetes Secret Keys |
|------------------|------------------------|------------------------|
| `/foo/bar`       | `foo`                  | `bar`                  |
| `/foo/baz`       | `foo`                  | `baz`                  |

_Result: A single secret named `foo` with two entries `bar` and `baz`_

## Using Secrets in Kubernetes

This guide will only concern itself about [using secrets as environment variables](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets-as-environment-variables. For other usages, see the official [Kubernetes documentation](https://kubernetes.io/docs/concepts/configuration/secret/#using-secrets).

Below is a sample deployment manifest:

```yaml
apiVersion: v1
kind: Deployment
metadata:
  name: my-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-service
  template:
    metadata:
      labels:
        app: my-service
    spec:
      containers:
      - name: my-container
        image: my-image
        env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: my-service
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: my-service
              key: password
```

Secrets are exposed to the pod as environment variables (`SECRET_USERNAME` and `SECRET_PASSWORD`) from the Kubernetes secret `my-service`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-service
type: Opaque
data:
  username: dXNlcm5hbWU=    # username as base64
  password: cGFzc3dvcmQ=    # password as base64
```
that contains the two (`username` and `password`) key/value pairs.

!!! warning "You will __NOT__ have to maintain the secret manifest yourself, as the Secret Manager takes care os this."

In order for the Secret Manager to manage the Kubernetes secret for us, we simple need to create two parameters in Parameter Store like:

| Parameter Name      | Parameter Value |
|---------------------|-----------------|
|/my-service/username | username        |
|/my-service/password | password        |

!!! tip "Using the SecretManagerCLI"
    ```bash
    ./secrets put my-service username=username password=password
    ```

The Secret Manager will then automatically pick up the newly created parameters and make sure the secret is kept in sync in Kubernetes.

### Alternative Approach

Using the [`envFrom`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#configure-all-key-value-pairs-in-a-configmap-as-container-environment-variables) it is possible to keep the deployment manifest short, at the cost of some explicitness.

The revised deployment manifest:

```yaml hl_lines="20"
apiVersion: v1
kind: Deployment
metadata:
  name: my-service
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-service
  template:
    metadata:
      labels:
        app: my-service
    spec:
      containers:
      - name: my-container
        image: my-image
        envFrom:
        - secretMapRef:
            name: my-service
```

The secret should be updated with the name of the target environment variables (`SECRET_USERNAME` and `SECRET_PASSWORD`):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-service
type: Opaque
data:
  SECRET_USERNAME: dXNlcm5hbWU=    # username as base64
  SECRET_PASSWORD: cGFzc3dvcmQ=    # password as base64
```

!!! tip "A note on using `envFrom` to expose secrets"
    When exposing secrets using `envFrom`, consider using the `SCREAMING_SNAKE_CASE` convention for key names, as this is considered standard.
    Remember that in Unix and Unix-like systems, the names of environment variables are case-sensitive.

Again, in order for the Secret Manager to manage the Kubernetes secret for us, we simple need to create two parameters in Parameter Store, this time with revised names, like:

| Parameter Name             | Parameter Value |
|----------------------------|-----------------|
|/my-service/SECRET_USERNAME | username        |
|/my-service/SECRET_PASSWORD | password        |

!!! tip "Using the SecretManagerCLI"
    ```bash
    ./secrets put my-service SECRET_USERNAME=username SECRET_PASSWORD=password
    ```
Again, the Secret Manager will then automatically pick up the newly created parameters and make sure the secret is kept in sync in Kubernetes.
