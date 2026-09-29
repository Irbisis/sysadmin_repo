output "public_ips" {
  value = {
    for vm in yandex_compute_instance.vm : vm.name => vm.network_interface[0].nat_ip_address
  }
  description = "Публичные IP всех ВМ"
}

output "internal_ips" {
  value = {
    for vm in yandex_compute_instance.vm : vm.name => vm.network_interface[0].ip_address
  }
  description = "Внутренние IP всех ВМ"
}
