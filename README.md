# GDS Supported Platform - Teams


Persistant cluster configurations for GDS teams using the GDS Supported Platform.

## Setting a deployer pipeline

Pipelines are not currently continuously deployed and must be manually updated.

To update a pipeline for one of the cluster configurations listed in [./clusters/](./clusters) can use the following script:

```sh
CLUSTER_NAME=sandbox ./hack/set-pipeline.sh
```

## Trusted Developers

Trusted Developers are developers who have had their details confirmed and added to [./users/](./users).

The details are used to enable various authentication and authorization functions such as:

* authentication to interact with clusters (kubectl)
* authorization of access within clusters (RBAC roles)
* authentication of code changes (signed commits)
* authentication of code reviews (github approvals)
* authentication to OAUTH protected services (ie Concourse)
* authentication to interact with AWS resources (ie CloudWatch)

To add a new "trusted developer" raise a PR with the required configuration to [./users/](./users).

As an example:

```
---
name: jeff.jefferson                                           # A username for reference
email: jeff.jefferson@email.com                                # Your email address
ARN: arn:aws:iam::000000000006:user/jeff.jefferson@email.com   # IAM ARN of your gds-users account
roles:
- sandbox-sre                                                  # has "sre" level access to "sandbox" cluster
- myprogramme-myapp-dev                                        # has "dev" level access to "myapp" namespace in "myprogramme" cluster
hardware:
  id: 9000005                                                  # id of hardware token (optional)
  type: yubikey                                                # kind of hardware token (optional)
github: jefferson678                                           # github username
teams: []
pub: |                                                         # public key used for signing git commits
  -----BEGIN PGP PUBLIC KEY BLOCK-----
  ...
  -----END PGP PUBLIC KEY BLOCK-----
```

Your PR will require review by at least two other trusted developers with write access to this repository.

## Accessing a cluster

* You must be listed as a trusted developer in [./users/](./users)
* You must have a relevent role (ie the `sandbox-canary-dev` role would give you dev access to the sandbox-canary namespace)
* You will need `kubectl` and the `aws` cli tool

### ...with aws-vault

You will `aws-vault` and need an AWS profile for your target cluster, for example:

```
[profile jeff@sandbox]
source_profile=gds-users
region=eu-west-2
role_arn=arn:aws:iam::000000002:role/sandbox-user-jeff.jefferson
mfa_serial=arn:aws:iam::000000000006:mfa/jeff.jefferson@email.com
```

...you can then use the `aws` cli to fetch the `kubeconfig`:

```
aws-vault exec jeff@sandbox -- aws eks update-kubeconfig --name sandbox --kubeconfig ./kubeconfig
```

...and then use `kubectl` to communicate with the cluster:

```
aws-vault exec jeff@sandbox -- kubectl --kubeconfig ./kubeconfig get po -n my-namespace
```

### ...with gds cli

Coming soon ;-)
