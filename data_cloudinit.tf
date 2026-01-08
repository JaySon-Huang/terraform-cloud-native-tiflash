locals {

    cloudinit_merge_type = "list(append)+dict(no_replace,recurse_list)+str()"

    # ensure_home_previleges = <<-EOT
    # #cloud-config
    # ${yamlencode({
    #     runcmd = [
    #         "set -x",
    #         "echo 'ensure home directory privileges'",
    #         "id ${local.username} || useradd -m -s /bin/bash ${local.username}",
    #         "chown -R ${local.username}:${local.username} /home/${local.username}",
    #         "chmod 755 /home/${local.username}",
    #         "echo 'ensure home directory privileges done'",
    #     ]
    #     })}
    # EOT

    # users_defs = <<-EOT
    # #cloud-config
    # ${yamlencode({
    #     groups = [
    #         { "${local.username2}" = [ "${local.username2}" ] }
    #     ],
    #     users = [
    #         { default = null },
    #         {
    #             name = "${local.username2}"
    #             groups = "${local.username2}"
    #             shell = "/bin/bash"
    #             sudo = ["ALL=(ALL) NOPASSWD:ALL"]
    #             ssh_authorized_keys = [trimspace(file(local.master_ssh_public))]
    #         }
    #     ]
    # })}
    # EOT

    users_defs_cfg = templatefile(
        "${path.module}/files/cloudinit.yaml.tftpl",
        {
            username = local.username2,
            ssh_public_key = trimspace(file(local.master_ssh_public)),
        }
    )

    userdata_add_alternative_ssh_public = <<-EOT
    #!/bin/bash
    set -x
    echo "ensure home directory privileges"
    id ${local.username} || useradd -m -s /bin/bash ${local.username}
    chown -R ${local.username}:${local.username} /home/${local.username}
    chmod 755 /home/${local.username}
    echo "ensure home directory privileges done"

    # Add alternative SSH public key to authorized_keys
    echo '${trimspace(file(local.alternative_ssh_public))}' | tee -a /home/${local.username}/.ssh/authorized_keys

    echo "ensure home directory privileges for ${local.username2}"
    id ${local.username2} || useradd -m -s /bin/bash ${local.username2}
    chown -R ${local.username2}:${local.username2} /home/${local.username2}
    chmod 755 /home/${local.username2}
    echo "ensure home directory privileges done for ${local.username2}"
    echo '${trimspace(file(local.alternative_ssh_public))}' | tee -a /home/${local.username2}/.ssh/authorized_keys
    EOT

    userdata_haproxy_cfg = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username2}/haproxy.cfg"
            permissions = "0644"
            owner       = "${local.username2}:${local.username2}"
            encoding    = "b64"
            content     = base64encode(templatefile("./files/haproxy.cfg.tftpl", {
                tidb_hosts = local.tidb_private_ips,
            }))
        }]
    })}
    EOT

    userdata_topology_yaml = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username2}/topology.yaml"
            permissions = "0644"
            owner       = "${local.username2}:${local.username2}"
            encoding    = "b64"
            content     = base64encode(templatefile("./files/topology.yaml.tftpl", {
                tidb_hosts = local.tidb_private_ips,
                tikv_hosts = local.tikv_private_ips,
                tiflash_write_hosts = local.tiflash_write_private_ips,
                tiflash_compute_hosts = local.tiflash_compute_private_ips,
                s3_region = local.region,
                s3_bucket = aws_s3_bucket.main.bucket,
            }))
        }]
    })}
    EOT

    userdata_master_ssh_pairs = <<-EOT
    #cloud-config
    ${yamlencode({
        write_files = [{
            path        = "/home/${local.username2}/.ssh/id_rsa"
            permissions = "0400"
            owner       = "${local.username2}:${local.username2}"
            encoding    = "b64"
            content     = base64encode(file(local.master_ssh_key))
        }, {
            path        = "/home/${local.username2}/.ssh/id_rsa.pub"
            permissions = "0644"
            owner       = "${local.username2}:${local.username2}"
            encoding    = "b64"
            content     = base64encode(file(local.master_ssh_public))
        }]
    })}
    EOT

    cloud_init_center_script = templatefile(
        "${path.module}/files/cloudinit_center.sh.tftpl",
        {
            username = local.username2
        }
    )
}

# For all servers except for center server, use the following cloudinit config.
data "cloudinit_config" "common_server" {
    gzip          = true
    base64_encode = true

    part {
        content_type = "text/x-shellscript"
        filename     = "add_ssh.sh"
        content      = local.userdata_add_alternative_ssh_public
    }
}

# For center server, use the following cloudinit config.
data "cloudinit_config" "center_server" {
    gzip          = true
    base64_encode = true

    # part {
    #     content_type = "text/cloud-config"
    #     filename     = "ensure_home_privileges.cfg"
    #     content      = local.ensure_home_previleges
    # }

    # part {
    #     content_type = "text/cloud-config"
    #     filename     = "create_tidb_user.cfg"
    #     content      = local.users_defs
    # }

    part {
        content_type = "text/cloud-config"
        filename     = "create_tidb_user.cfg"
        content      = local.users_defs_cfg
    }

    part {
        content_type = "text/cloud-config"
        filename     = "write_haproxy.cfg"
        content      = local.userdata_haproxy_cfg
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/cloud-config"
        filename     = "write_topology.cfg"
        content      = local.userdata_topology_yaml
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/cloud-config"
        filename     = "write_master_ssh_pairs.cfg"
        content      = local.userdata_master_ssh_pairs
        merge_type   = local.cloudinit_merge_type
    }

    part {
        content_type = "text/x-shellscript"
        filename     = "add_ssh.sh"
        content      = local.userdata_add_alternative_ssh_public
    }

    part {
        content_type = "text/x-shellscript"
        filename     = "cloudinit_center.sh"
        content      = local.cloud_init_center_script
    }

}
