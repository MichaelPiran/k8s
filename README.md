# Kubernetes con kubeadm e Ansible

Questo playbook crea un cluster Kubernetes con un nodo control plane e uno o piu worker su Ubuntu/Debian. Installa `containerd`, `kubeadm`, `kubelet`, `kubectl` e la rete Flannel.

Il ramo configurato e Kubernetes **v1.37**, l'ultima minor stabile al 31 agosto 2026; la release corrente e `v1.37.0`. Il playbook installa l'ultima patch disponibile nel ramo al momento dell'esecuzione, poi mette i pacchetti Kubernetes in `hold` per evitare aggiornamenti involontari.

## Prerequisiti

Sul computer da cui viene eseguito Ansible:

- Ansible Core installato.
- Una chiave SSH privata per accedere ai nodi.

Su ciascun nodo:

- Ubuntu o Debian con accesso a Internet.
- Utente SSH autorizzato a eseguire `sudo`.
- Hostname, indirizzo IP e MAC univoci.
- Almeno 2 CPU e 2 GB RAM per il control plane.
- Connettivita completa tra control plane e worker.

## Configurazione

Creare l'inventario locale dal template:

```bash
cp inventory.example.ini inventory.ini
```

Modificare `inventory.ini`:

```ini
[control_plane]
master ansible_host=192.168.1.10

[workers]
worker ansible_host=192.168.1.11

[k8s_cluster:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=~/.ssh/id_ed25519
kubernetes_minor_version=v1.37
pod_network_cidr=10.244.0.0/16
flannel_version=v0.27.3
```

Configurazioni da impostare:

| Variabile | Descrizione |
| --- | --- |
| `ansible_host` | IP raggiungibile del relativo nodo. |
| `ansible_user` | Utente SSH presente su tutti i nodi. |
| `ansible_ssh_private_key_file` | Percorso locale della chiave SSH privata. |
| `kubernetes_minor_version` | Ramo del repository Kubernetes, per esempio `v1.37`. |
| `pod_network_cidr` | Rete virtuale dei Pod. Con Flannel usare `10.244.0.0/16`. |
| `flannel_version` | Versione del manifest Flannel da installare. |

Non usare per `pod_network_cidr` una rete gia impiegata dalla LAN o dalle VM. Per aggiungere worker, aggiungere altre righe al gruppo `[workers]`.

## Firewall

Consentire almeno queste porte tra i nodi:

| Nodo | Porte TCP | Porte UDP |
| --- | --- | --- |
| Control plane | `6443`, `2379-2380`, `10250`, `10257`, `10259` | - |
| Worker | `10250`, `10256`, `30000-32767` | `8472` per Flannel |

Le regole precise possono variare in base al sistema operativo, alla CNI e ai servizi pubblicati.

## Installazione

Verificare prima l'accesso SSH e poi eseguire il playbook tramite Make:

```bash
make ping
make install
```

I comandi Ansible equivalenti sono:

```bash
ansible all -i inventory.ini -m ansible.builtin.ping
ansible-playbook -i inventory.ini k8s.yml
```

Se `sudo` richiede una password, eseguire direttamente `ansible-playbook` aggiungendo `--ask-become-pass`.

## Connessione kubectl

Dopo l'installazione, recuperare dal control plane la configurazione amministrativa:

```bash
make kubeconfig
```

Il comando salva la connessione in `./kubeconfig` con permessi `0600`. Il file e escluso da Git. Si puo indicare un percorso diverso senza modificare il Makefile:

```bash
make kubeconfig KUBECONFIG_FILE="$HOME/.kube/k8s-lab.conf"
```

Usare la connessione nella shell corrente oppure passarla direttamente a `kubectl`:

```bash
export KUBECONFIG="$PWD/kubeconfig"
kubectl get nodes -o wide

# Comandi equivalenti disponibili nel Makefile
make nodes
make pods
```

## Verifica

Dal control plane:

```bash
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes -o wide
sudo kubectl --kubeconfig=/etc/kubernetes/admin.conf get pods -A
```

Tutti i nodi devono raggiungere lo stato `Ready`.

## Dati sensibili

`inventory.ini`, chiavi private, password Ansible Vault e kubeconfig sono esclusi da Git tramite `.gitignore`. Non inserire password o chiavi nel template `inventory.example.ini`; per segreti aggiuntivi usare Ansible Vault o variabili d'ambiente.