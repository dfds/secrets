#!/bin/bash

[[ -n "${DEBUG}" ]] && set -x

set -eu

ROLE_NAME="SECRET_MANAGER_ROLE"
POLICY_NAME="SSMReadAccess"
ASSUME_ROLE_POLICY_DOCUMENT=$(cat << EOF
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
EOF
)
POLICY_DOCUMENT=$(cat << EOF
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
EOF
)
DEPLOYMENT="secrets"
REPO=thofisch/secrets
VERSION="0.3.0"

echo "Creating AWS IAM Role: '${ROLE_NAME}'..."

role_arn=$(aws iam create-role \
  --role-name ${ROLE_NAME} \
  --assume-role-policy-document "${ASSUME_ROLE_POLICY_DOCUMENT}" \
  --description "Allow read access to SSM parameter store" \
  --max-session-duration 3600 \
  --query Role.Arn \
  --out text)

echo "Creating AWS IAM Role Policy:'${POLICY_NAME}'..."

aws iam put-role-policy \
  --role-name ${ROLE_NAME} \
  --policy-name ${POLICY_NAME} \
  --policy-document "${POLICY_DOCUMENT}" \
  1>/dev/null

echo "Deploying '${DEPLOYMENT}'..."

cat << MANIFEST | kubectl apply --dry-run -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${DEPLOYMENT}
spec:
  selector:
    matchLabels:
      app: ${DEPLOYMENT}
  template:
    metadata:
      labels:
        app: ${DEPLOYMENT}
      annotations:
        iam.amazonaws.com/role: ${role_arn}
    spec:
      serviceAccountName: ${DEPLOYMENT}-sa
      containers:
      - name: secrets
        image: ${REPO}:${VERSION}
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
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ${DEPLOYMENT}-role
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["secrets"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ${DEPLOYMENT}-sa
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${DEPLOYMENT}-role-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ${DEPLOYMENT}-role
subjects:
  - kind: ServiceAccount
    name: ${DEPLOYMENT}-sa
MANIFEST
