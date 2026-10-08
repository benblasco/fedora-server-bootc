# Forgejo Actions build

Continuous integration for the bootc container image via [`.forgejo/workflows/container-build.yml`](.forgejo/workflows/container-build.yml). This is the Forgejo port of [`Jenkinsfile.container`](Jenkinsfile.container).

## Runner and job image

Deploy and configure Forgejo Actions runners with [podman-container-yaml](https://github.com/benblasco/podman-container-yaml) (`run-podman-quadlet-forgejo.yml`). The workflow uses:

- **`runs-on: fedora-server-bootc`**
- Job container: [`quay.io/containers/aio`](https://quay.io/repository/containers/aio) (official Podman + Buildah + Skopeo image from [containers/image_build](https://github.com/containers/image_build))

The workflow installs **`nodejs`**, **`git`**, **`jq`**, and **`curl`** once per job with `microdnf`. Node is required for JavaScript Actions (`actions/checkout`, `redhat-actions/buildah-build`). `jq`/`curl` support registry sizing and Signal notifications. No custom CI image is required beyond [`quay.io/containers/aio`](https://quay.io/repository/containers/aio).

After changing runner labels or `container:` options in Ansible, re-run the playbook and restart `forgejo-runner.service`. See [README.forgejo.md](https://github.com/benblasco/podman-container-yaml/blob/main/README.forgejo.md) in that repo.

**Runner version:** Homelab runners use **forgejo-runner v6.x**, which supports JavaScript actions through **`node20`** only. The workflow pins **`actions/checkout@v4`** (`runs.using: node20`). To use `checkout@v5`/`@v6` (`node24`), upgrade the runner to **[>= v9.1.0](https://codeberg.org/forgejo/runner/releases/tag/v9.1.0)** in podman-container-yaml, then restart `forgejo-runner.service`. Check on a runner host: `forgejo-runner --version` and `systemctl is-active forgejo-runner.service`.

## Repository secrets

Configure the three `SIGNAL_*` repository secrets per [README.forgejo-notification.md](README.forgejo-notification.md) (same values as Jenkins).

## Triggers

- **Schedule:** Sunday ~06:15 Australia/Melbourne (cron is UTC in the workflow file).
- **Manual:** `workflow_dispatch` in the Actions tab.

Scheduled workflows run only from the **default branch**.

## Troubleshooting

### `crun: executable file 'node' not found` on a `uses:` step

The aio image is still the right choice for Buildah/Skopeo. Forgejo runs JavaScript Actions inside the job container and needs **`node`** on `PATH`. Install it in the bootstrap `microdnf` step (as in the workflow), or use a custom image that includes aio tools plus Node.js. That does **not** replace the runner’s own Node runtime labels (`node20`, `node24`, etc.) declared in each action’s `action.yml`.

### `runs.using` … `got node24` at job setup

The runner validates each action before steps run. **`actions/checkout@v6`** (and v5) declare **`node24`**; **forgejo-runner v6.2.x** only allows `[composite docker node12 node16 node20 go]`. Symptom: job fails right after cloning the checkout action, with no checkout step executed.

- **Fix in this repo:** keep **`actions/checkout@v4`** (`node20`). `redhat-actions/buildah-build@v2` is already `node20`.
- **Fix on the host:** upgrade forgejo-runner to **>= v9.1.0**, then you may use newer checkout versions if you want.

Workflow YAML must exist on the repository **default branch** for the Actions tab and `workflow_dispatch` to list it.

## Verify

On a runner host:

```bash
getenforce
podman pull quay.io/containers/aio:latest
podman run --rm quay.io/containers/aio:latest buildah version
podman run --rm quay.io/containers/aio:latest skopeo version
podman run --rm quay.io/containers/aio:latest sh -c 'microdnf install -y nodejs git && node --version && git --version'
```

After a successful run:

```bash
skopeo inspect --tls-verify=false "docker://nuc.lan:5000/fedora-server-bootc:main-$(date +%Y%m%d)" \
  | jq '[.LayersData[].Size] | add' | numfmt --to=iec-i --suffix=B
```

Confirm the Signal group message includes `size=` on success ([README.forgejo-notification.md](README.forgejo-notification.md)).
