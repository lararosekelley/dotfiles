# Kubernetes

Tools for working with remote clusters over Tailscale, plus a throwaway local
cluster. Kubeconfigs and tailnet logins stay out of the repo: every context lives
in the untracked `~/.kube/config`.

## Install

```bash
sudo dnf install kubernetes1.34-client helm k9s
```

Keep kubectl within one minor version of the clusters it talks to, and swap the
`kubernetes1.XX-client` package when they upgrade.

kubectx, kubens, and stern come from [krew](https://krew.sigs.k8s.io), the
kubectl plugin manager, so they run as `kubectl ctx`, `kubectl ns`, and
`kubectl stern`. Install krew with its official script (it needs `git`), then
the plugins. `.exports` already puts `~/.krew/bin` on `PATH`:

```bash
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)
kubectl krew install ctx ns stern
```

`kubectl krew upgrade` updates krew and every plugin.

k3d is not in krew. Its official script installs the release binary into
`/usr/local/bin`, using sudo, and running it again updates it:

```bash
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
```

## Shell

`.aliases` adds `k` (kubectl), `kx` (`kubectl ctx`), `kn` (`kubectl ns`), and
`tsw` (`tailscale switch`). `.bashrc` loads completion for kubectl, `k`, helm,
and k3d when they are installed. kubectl's completion does not reach plugin
arguments, so context and namespace names are typed out.

## Remote clusters over Tailscale

Clusters that run the Tailscale Kubernetes operator with its API server proxy
are reached by tailnet name, with access granted by tailnet identity rather than
exported certificates.

Let `tailscale switch` run without sudo, once:

```bash
sudo tailscale set --operator=$USER
```

Then add each account once with `tailscale login`, list them with
`tailscale switch --list`, and move between them with `tsw <account>`. The
machines stay on the personal tailnet day to day, so switch to the work one
before using its clusters, and back afterwards: until then, the personal
machines, such as the desktop's Jellyfin, are out of reach.

On the tailnet that serves the cluster, add it as a kubectl context. The proxy's
hostname comes from that cluster's access docs:

```bash
tailscale configure kubeconfig <proxy-hostname>
```

The context is named after the proxy host and becomes current. It only answers
while that tailnet is active. What it may do is decided by the tailnet policy and
the cluster's RBAC, often read-only. `kx` switches contexts and `k9s` browses the
current one.

## Local cluster

```bash
k3d cluster create dev --agents 2
k3d cluster delete dev
```

k3d adds a `k3d-dev` context and makes it current.

## k9s

`.config/k9s` sets the Callie skin and hides the logo. k9s keeps per-cluster
state under `~/.local/share/k9s`, which is not tracked.

`k8s` (`.bin/k8s`) opens k9s on the current context, read-only when that context
is a tailnet API proxy (`*.ts.net`). `k8s status` prints the active tailnet,
context, and namespace. The `k8s` tab of the herdr and tuios default sessions runs
it in the gitops and infra repos.

## Headlamp

[Headlamp](https://headlamp.dev) is a GUI alternative to k9s, from Flathub:

```bash
flatpak install flathub io.kinvolk.Headlamp
```

It reads the same `~/.kube/config` contexts. Its sandbox can read that file and
reach the network, so tailnet and k3d contexts work, but a context whose auth runs
a local program (an `exec` credential plugin such as `aws eks get-token`) fails
inside it.

The tracked `callie-theme` plugin adds Callie and Callie Light themes, picked in
Settings > Appearance after a restart. The Flatpak loads hand-installed plugins
from `~/.var/app/io.kinvolk.Headlamp/config/Headlamp/user-plugins`. The themes
use Nunito, which Flatpak apps pick up from the system fonts:

```bash
sudo dnf install vernnobile-nunito-fonts
```
