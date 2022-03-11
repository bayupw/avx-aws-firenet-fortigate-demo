/* module "fortigate_bootstrap" {
  source = "./bootstrap"
}

# 5 mins delay to get the s3 bucket objects ready
resource "time_sleep" "wait_bootstrap" {
  create_duration = "300s"
  depends_on      = [module.pan_bootstrap]
} */