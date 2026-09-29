terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.130"
    }
  }
  required_version = ">= 0.13"
}

provider "yandex" {
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = "ru-central1-d"
  service_account_key_file = "sa-key.json"
}

# Сеть и подсеть уже созданы в консоли — берём их по имени
data "yandex_vpc_network" "net" {
  name = "practicum"
}

data "yandex_vpc_subnet" "subnet" {
  name = "practicum-sysadmin"
}

# Группу безопасности создаёт Terraform
resource "yandex_vpc_security_group" "sg" {
  name       = "practicum-sg"
  network_id = data.yandex_vpc_network.net.id

  ingress {
    description    = "SSH"
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "HTTP"
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description    = "Proxy port 3000"
    protocol       = "TCP"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description    = "Allow all outgoing"
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

locals {
  vm_names = ["proxy", "backend1", "backend2"]
}

resource "yandex_compute_instance" "vm" {
  count = length(local.vm_names)
  name  = local.vm_names[count.index]
  #  hostname    = local.vm_names[count.index]
  platform_id = "standard-v3"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    auto_delete = false
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
    }
  }

  network_interface {
    subnet_id          = data.yandex_vpc_subnet.subnet.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.sg.id]
  }

  metadata = {
    ssh-keys = "yc-user:${var.ssh_public_key}"
  }

  scheduling_policy {
    preemptible = true
  }

  lifecycle {
    ignore_changes = [
      metadata["user-data"],
      labels,
    ]
  }
}


