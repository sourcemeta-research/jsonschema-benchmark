# The benchmark runner pool

GitHub's hosted runners come from a pool of CPU models, and every implementation is benchmarked in its own job, so two
jobs, or two runs, can measure on different hardware (see #211). The scheduled benchmark (and a manual run) therefore
runs on a small pool of identical Azure VMs: one VM size, so one CPU model, for every job of every run. The VMs are
started for the run and deallocated afterwards, so between runs they cost only their disks.

Pull requests and pushes to `main` still run on GitHub's hosted runners, as a check that every implementation builds
and runs; only the pool's results are comparable over time. A pool run, and the results it caches, are kept apart from
hosted ones.

## How a pool run works

1. `plan` sends the run to the pool when it is scheduled or started by hand and `BENCHMARK_POOL` is set (otherwise it
   runs on `ubuntu-latest`, as before). Pool runs never overlap.
2. `pool-start` logs in to Azure (OpenID Connect, no stored credentials), starts the VMs, and registers a runner on each
   with a label unique to this run attempt, using a registration token from the GitHub App.
3. The benchmark jobs run on the pool, one per VM at a time. Each job records its CPU, and fails if it is not
   `BENCHMARK_CPU_MODEL` (in case Azure moves the size to other hardware).
4. `pool-stop` always runs: it removes the runners, clears the VMs' Docker images, and deallocates the VMs.

To repeat a pool run, re-run all of its jobs: re-running only the failed jobs would wait for runners that `pool-stop`
has already removed.

## Setting it up

Once, by someone with access to the Azure subscription and to the repository's settings.

### 1. The VMs

With the Azure CLI signed in to the subscription:

```sh
pwsh infra/runner-pool/New-RunnerPool.ps1 -ResourceGroup jsonschema-benchmark -Location uksouth
```

This creates two `Standard_D4as_v7` VMs (4 vCPUs, AMD EPYC, Ubuntu 24.04) with Docker, the benchmark's tools and
the GitHub Actions runner, waits for them to finish installing, prints their CPU model, and deallocates them. They
accept no inbound connections: the workflow drives them with `az vm run-command`.

### 2. The workflow's Azure identity

An app registration that the workflow logs in as, trusted only for runs on `main` (scheduled and manual runs both
present the subject `ref:refs/heads/main`), and allowed only to manage the pool's VMs:

```sh
app=$(az ad app create --display-name jsonschema-benchmark-ci --query appId --output tsv)
az ad sp create --id "$app"
az ad app federated-credential create --id "$app" --parameters '{
  "name": "jsonschema-benchmark-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:sourcemeta-research/jsonschema-benchmark:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
az role assignment create --assignee "$app" --role "Virtual Machine Contributor" \
  --scope "$(az group show --name jsonschema-benchmark --query id --output tsv)"
```

### 3. The GitHub App that registers runners

Registering a repository's self-hosted runners needs the repository permission **Administration: Read and write**. In
the organization's settings, **Developer settings**, **GitHub Apps**, create an app with only that permission and no
webhook, install it on this repository, note its **App ID**, and generate a private key.

### 4. The repository's settings

| Kind | Name | Value |
|---|---|---|
| Variable | `AZURE_CLIENT_ID` | The app registration's application (client) ID. |
| Variable | `AZURE_TENANT_ID` | The Azure tenant ID. |
| Variable | `AZURE_SUBSCRIPTION_ID` | The subscription holding the pool. |
| Variable | `BENCHMARK_RESOURCE_GROUP` | `jsonschema-benchmark` |
| Variable | `BENCHMARK_POOL` | The VM names, comma-separated, as the script prints them. |
| Variable | `BENCHMARK_CPU_MODEL` | The CPU model the script printed, exactly. |
| Variable | `RUNNER_APP_ID` | The GitHub App's ID. |
| Secret | `RUNNER_APP_PRIVATE_KEY` | The GitHub App's private key. |

In **Settings**, **Actions**, **General**, keep **Require approval for all outside collaborators** for workflows from
forks: a fork's pull request could edit the workflow to target a self-hosted label. The runners exist only while a pool
run is in progress, and their labels are unique to it, but approval is the safeguard.

## Cost

Two `Standard_D4as_v7` VMs for the length of one run every two days, plus two 64 GB standard SSD disks all the
time. Deallocated VMs incur no compute charges.
