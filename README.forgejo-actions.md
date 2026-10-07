# Forgejo Actions build

Continuous integration for the bootc container image via [`.forgejo/workflows/container-build.yml`](.forgejo/workflows/container-build.yml). This is the Forgejo port of [`Jenkinsfile.container`](Jenkinsfile.container).

## Runner and job image

Deploy and configure Forgejo Actions runners with [podman-container-yaml](https://github.com/benblasco/podman-container-yaml) (`run-podman-quadlet-forgejo.yml`). The workflow uses:

- **`runs-on: fedora-server-bootc`**
- Job container: [`quay.io/containers/aio`](https://quay.io/repository/containers/aio) (official Podman + Buildah + Skopeo image from [containers/image_build](https://github.com/containers/image_build))

The workflow installs **`jq`** and **`curl`** once per job with `microdnf` (for `skopeo inspect` sizing and Signal notifications). No custom CI image is required.

After changing runner labels or `container:` options in Ansible, re-run the playbook and restart `forgejo-runner.service`. See [README.forgejo.md](https://github.com/benblasco/podman-container-yaml/blob/main/README.forgejo.md) in that repo.

## Repository secrets

Add under the Forgejo repo → **Settings → Secrets** (same values as Jenkins; see [README.jenkins-notification.md](README.jenkins-notification.md)):

| Secret | Jenkins credential ID |
|--------|------------------------|
| `SIGNAL_WEBHOOK_URL` | `signal_webhook_url` |
| `SIGNAL_NUMBER` | `signal_number` |
| `SIGNAL_GROUP_ID` | `signal_group_id` |

## Triggers

- **Schedule:** Sunday ~06:15 Australia/Melbourne (cron is UTC in the workflow file).
- **Manual:** `workflow_dispatch` in the Actions tab.

Scheduled workflows run only from the **default branch**.

## Verify

On a runner host:

```bash
getenforce
podman pull quay.io/containers/aio:latest
podman run --rm quay.io/containers/aio:latest buildah version
podman run --rm quay.io/containers/aio:latest skopeo version
```

After a successful run:

```bash
skopeo inspect --tls-verify=false "docker://nuc.lan:5000/fedora-server-bootc:main-$(date +%Y%m%d)" \
  | jq '[.LayersData[].Size] | add' | numfmt --to=iec-i --suffix=B
```

Confirm the Signal group message includes `size=` on success.
