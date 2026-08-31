INVENTORY ?= inventory.ini
PLAYBOOK ?= k8s.yml
KUBECONFIG_FILE ?= $(CURDIR)/kubeconfig

.PHONY: help ping install kubeconfig nodes pods

help:
	@printf '%s\n' \
		'make ping        Verifica la connessione SSH ai nodi' \
		'make install     Installa e configura Kubernetes' \
		'make kubeconfig  Scarica la configurazione kubectl' \
		'make nodes       Mostra i nodi del cluster' \
		'make pods        Mostra tutti i Pod'

ping:
	ansible all -i $(INVENTORY) -m ansible.builtin.ping

install:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)

kubeconfig:
	ansible control_plane -i $(INVENTORY) --become \
		-m ansible.builtin.fetch \
		-a "src=/etc/kubernetes/admin.conf dest=$(KUBECONFIG_FILE) flat=yes"
	chmod 600 $(KUBECONFIG_FILE)
	@printf 'Kubeconfig salvato in %s\n' '$(KUBECONFIG_FILE)'
	@printf 'Usalo con: export KUBECONFIG=%s\n' '$(KUBECONFIG_FILE)'

nodes:
	kubectl --kubeconfig $(KUBECONFIG_FILE) get nodes -o wide

pods:
	kubectl --kubeconfig $(KUBECONFIG_FILE) get pods --all-namespaces