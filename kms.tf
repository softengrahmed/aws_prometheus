# kms key configuratino
resource "aws_kms_key" "jnj_amp" {
  description             = "AWS managed key to encrypt amp contents"
  deletion_window_in_days = var.deletion_window_in_days
  enable_key_rotation     = true
}