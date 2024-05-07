# DevOps API

## Prerequisites

- [python] 3.11.x
- [curl]
- [terraform] or `make install/tf`
- [docker]
#### If you need to run deploy/plan/destroy targets.
- [awscli] 


**NOTE!**
On MAC M1/Intel chip requires brew and GNU MAKE upgrade

### Brew install

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### GNU make upgrade

```bash
brew install make
export PATH="/usr/local/opt/make/libexec/gnubin:$PATH" # Add to .bashrc or .zshrc
make -version # Should be higher then 3.8.1
```
---

## HOWTO

### Environmens
All envs configured in `terraform/provisioners/` dir as `.tfvars` files.

### Build
Build image
```bash
make build
```

Run container
```bash
make run
```

Cleanup
```bash
make run
```

### E2E Deoployment

Apply
```bash
make deploy env_id=<your_env_id> #F.E dev-us-east-1
```

Destroy
```bash
make destroy env_id=<your_env_id> 
```
Terraform fmt
```bash
make fix/ffmt
```


### Cleanup

```bash
make cleanup
```

<!--links-->
[awscli]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[docker]: https://docs.docker.com/get-docker/
[terraform]: https://www.terraform.io/downloads
[python]: https://www.python.org/downloads/