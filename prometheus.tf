# ******************************* Prometheus setup ***********************************

module "prometheus_compute" {
  #source = "../terraform-os-compute"
  source               = "git@github.com:dinivas/terraform-openstack-instance.git"

  instance_name                 = "${var.project_name}-prometheus"
  image_name                    = "${var.prometheus_image_name}"
  flavor_name                   = "${var.prometheus_compute_flavor_name}"
  keypair                       = "${module.project_generated_keypair.name}"
  network_ids                   = ["${module.mgmt_network.network_id}"]
  subnet_ids                    = ["${module.mgmt_network.subnet_ids}"]
  instance_security_group_name  = "${var.project_name}-prometheus-sg"
  instance_security_group_rules = "${var.prometheus_security_group_rules}"
  security_groups_to_associate  = ["${module.common_security_group.name}"]
  metadata                      = "${var.metadata}"
}

resource "openstack_networking_floatingip_v2" "prometheus_floatingip" {
  count = "${var.floating_ip_pool != "" ? 1 : 0}"

  pool = "${var.floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "prometheus_floatingip_associate" {
  floating_ip           = "${openstack_networking_floatingip_v2.prometheus_floatingip.0.address}"
  instance_id           = "${module.prometheus_compute.ids[0]}"
  fixed_ip              = "${module.prometheus_compute.network_fixed_ip_v4[0]}"
  wait_until_associated = true
}


data "template_file" "prometheus_config" {
  template = "${file("${path.module}/templates/prometheus.yml.tpl")}"
  vars = {
    project_name = "${var.project_name}"
    prometheus_scrape_interval = "30s"
    prometheus_evaluation_interval = "30s"
    prometheus_scrape_timeout = "30s"
  }
}

resource "null_resource" "prometheus_configure" {

  triggers = {
    template = "${data.template_file.prometheus_config.rendered}"
  }

  # provide some connection info
  # connection {
  #   type        = "ssh"
  #   user        = "root"
  #   private_key = "${var.ssh_private_key}"
  #   host        = "${element(var.public_ips, count.index)}"
  # }

  provisioner "file" {
    content     = "${data.template_file.prometheus_config.rendered}"
    destination = "/etc/prometheus/prometheus.yml"
  }
}
