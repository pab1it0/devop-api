## Provision api for use/ese/trial/demo

## Prerequisites

- [python] 3.11.x
- [curl]
- [terraform] or make install/tf
- [docker]
#### If you need to run deploy/plan/destroy targets.
- [awscli] 
- [gcloud]

---

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

### Working with local virtualenv

```bash
python3 -m pip install --user virtualenv
brew install python@3.11
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

You can point your Python interpreter in the IDE to $GIT_REPO/venv/bin/python

---

## Please always work with virtualenv to avoid issues with local python packages.

### List targets and help

```bash
make help
```

### Run tests locally

```bash
make test
```

### Run api locally with sample consul/vault data

```bash
make run
```

### Rerun after code changes, keeping the existing consul/vault/redis data

```bash
make rerun
```

### Run only consul/vault/redis locally

```bash
make preprare
```

### Run local redis commander container for cache troubleshooting 

```bash
docker run --rm --name redis-commander -d -p 8081:8081 --link=redis-provision-api-local:redis -e VIEW_JSON_DEFAULT=all -e REDIS_HOSTS=local:redis:6379 rediscommander/redis-commander:latest
```

Endpoints documentation http://localhost:8000/v1/ui

Provision api endpoint http://localhost:8000

Consul ui http://localhost:8900

Vault ui http://localhost:8901

Redis ui http://localhost:8081

## All authentication tokens (consul,vault,provision api) are **test**

### Cleanup

```bash
make cleanup
```

<!--links-->
[awscli]: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
[gcloud]: https://cloud.google.com/sdk/docs/install
[docker]: https://docs.docker.com/get-docker/
[curl]: https://curl.se/download.html
[terraform]: https://www.terraform.io/downloads
[python]: https://www.python.org/downloads/