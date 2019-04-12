# Application Development & Secrets

{== **TODO:** A no-nonsense description of how to manage secrets for multiple applications in multiple environments ==}

- [ ] How to create, update, and delete resources.
- [ ] Add UI/CLI/scripts for easily managing secrets (according to conventions). {== this should plug nicely into the whole saml2aws, if it's on the terminal ==}
- [ ] How to setup Parameters as Terraform resources.
- [ ] A brief and to the point description of the secrets lifecycle. {== no ops details here ==}
- [ ] Example(s) of how to access secrets in Kubernetes. {== `envFrom`, `env`, `volumnes` ==} {>> are pod-presets too advanced? <<}

!!! info "mps - manage paramater store from cli"
    ```bash
    $ curl -sSL -o mps https://raw.githubusercontent.com/dfds/secrets/master/scripts/mps
    $ chmod +x mps
    $ ./mps put -c p-project -a papp -o key1=value1 key2=value2
    ```
