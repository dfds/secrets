# Setup

In order to tage advantage of the Secret Manager follow the steps below. To prepare an alternative setup procedure see the [Full Description](#full-description).

!!! important "Installation"
    Here are the steps needed to install the Secret Manager:

    * Download the [install.sh](install.sh).
    * Use `saml2aws` to log in to the capability of choice.
    * Run the installation script: `./install.sh`.

## Full Description

In order for the Secret Manager to function, it needs:

1. Read access to the Parameter Store through an AWS IAM role
1. Access to manage secrets in Kubernetes using RBAC.

### The AWS IAM Role

In order to read parameters from the Parameter Store, we need to create an AWS IAM Role with the following policies:

  * A trust relationship (assume role policy) to `arn:aws:iam::738063116313:role/eks-hellman-kiam-server`, in order for kiam to be able to perform actions on behalf of us.
  * A policy with read access to Parameter Store

Below is the **assume role policy document** (or trust relationship) that allows the Kubernetes cluster to assume the role:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::738063116313:role/eks-hellman-kiam-server"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

and the specific **policy document** with read access to Parameters Store:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:Describe*",
        "ssm:Get*",
        "ssm:List*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Kubernetes Manifests

In order for the Secret Manager to be able to manage Kubernetes secrets, we need:

1. To annotate the Secret Manager `POD` with the ARN of the AWS IAM Role described in the above section (see the first highlighted line in the `deployment.yaml` manifest below):

    ```yaml hl_lines="14 16"
    apiVersion: apps/v1
    kind: Deployment
    metadata:
    name: secrets
    spec:
    selector:
        matchLabels:
        app: secrets
    template:
        metadata:
        labels:
            app: secrets
        annotations:
            iam.amazonaws.com/role: arn:aws:iam::153642329677:role/secrets
        spec:
        serviceAccountName: secret-sa
        containers:
        - name: secrets
            image: thofisch/secrets:v0.2.1
            resources:
            limits:
                memory: "128Mi"
                cpu: "500m"
            ports:
            - containerPort: 8080
            env:
            - name: AWS_DEFAULT_REGION
            value: eu-central-1
            - name: KUBERNETES_NAMESPACE
            valueFrom:
                fieldRef:
                fieldPath: metadata.namespace
    ```

2. To create a Kubernetes `Role` with "full access" to Kubernetes Secrets:

    ```yaml
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
    name: secret-role
    rules:
    - apiGroups: [""] # "" indicates the core API group
    resources: ["secrets"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
    ```

3. Create a Kubernetes `ServiceAccount` to be used by the Secret Manager `POD` (see the second highlighted line in the `deployment.yaml` manifest above):

    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
    name: secret-sa
    ```

4. Connect the Kubernetes `Role` and `ServiceAccount` using a `RoleBinding`:

    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
    name: secret-role-binding
    roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: Role
    name: secret-role
    subjects:
    - kind: ServiceAccount
        name: secret-sa
    ```
