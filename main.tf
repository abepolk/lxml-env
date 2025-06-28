terraform {
    required_providers {
        google = {
            source = "hashicorp/google"
            version = "6.37.0"
        }
    }
    required_version = "~> 1.5.7"
}

# This should be supplied from the command line via
# the terraform-<operation>-wrapper.sh one-line (for now) scripts.
# Do not enter interactively

variable "project_id" {
    type = string
}

provider "google" {
    project = var.project_id
}

# I may not need the startup script bucket for a startup script - just put the script in metadata defined in this template

# resource "random_id" "startup_script_bucket_id" {
#  byte_length = 8
#}
#
#resource "google_storage_bucket" "startup_script_bucket" {
#    name = "${random_id.startup_script_bucket_id.hex}-lxml-startup-script-bucket"
##    location = local.location
#    location = "us-central1"
#    storage_class = "STANDARD"
#    force_destroy = true
#    # uniform_bucket_level_access disables ACLs, which are only useful
#    # in legacy contexts and migrations from AWS
#    uniform_bucket_level_access = true
#}
#
#resource "google_storage_bucket_object" "startup_script" {
#    bucket = google_storage_bucket.startup_script_bucket.name
#    name = "lxml-startup-script"
#    source = "build_lxml_env.sh"
#}

resource "random_id" "patch_bucket_id" {
    byte_length = 8
}

resource "google_storage_bucket" "patch_bucket" {
    name = "${random_id.patch_bucket_id.hex}-lxml-patch-bucket"
#    location = local.location
    location = "us-central1"
    storage_class = "STANDARD"
    force_destroy = true
    # uniform_bucket_level_access disables ACLs, which are only useful
    # in legacy contexts and migrations from AWS
    uniform_bucket_level_access = true
}

resource "google_compute_region_instance_template" "instance_template" {
    disk {
        # Note: if this template is being used after the end of Debian 12 LTS support on June 30, 2028, this would have to be updated to a later OS
        source_image = "family/debian-12"
        # POTENTIAL BUG
        # I think `boot = true` is necessary, but I'm not sure
        boot = true
    }

    network_interface {
        network = "default"
    }

    machine_type = "e2-medium"

    # No need to disable backups as you would in the console. Same goes for disabling the installation of the Ops Agent

    # I think you generally want to set scopes = ["cloud-platform"] when creating VMs,
    # even if you're not worried about the service account (although we DO customize the service account in this template)
    service_account {
        email  = google_service_account.default.email
        # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
        scopes = ["cloud-platform"]
    }

    # Note: This is an alternative to putting in the startup script in a bucket, which I almost did earlier.
    metadata = {
        "bucket_name" = google_storage_bucket.patch_bucket.name
        "startup-script" = file("build_lxml_env.sh")
    }
}

resource "google_service_account" "default" {
    account_id = "patch-access-service-account
}

resource "google_storage_bucket_iam_binding" "binding" {
    bucket = google_storage_bucket.patch_bucket.name
    # I THINK this role is right - it's what I used in the console before
    role = "roles/storage.objectUser"
    members = [
        "serviceAccount:${google_service_account.default.email}",
    ]
}

# As a final note about this template, I will want to store Terraform state carefully (in a GCS bucket),
# in case, for example, I want to update the startup script
# without getting rid of the bucket containing all of the Git patches
# (meaning to use Terraform's apply without using destroy first)