resource "aws_ebs_volume" "ollama_models" {
  count = 2 # For each Ollama replica

  availability_zone = element(module.vpc.azs, count.index)
  size              = 60
  type              = "gp2"
  encrypted         = true

  tags = {
    Name = "ollama-models-${count.index}"
  }
}

resource "kubernetes_storage_class" "gp2_waitforfirstconsumer" {
  metadata {
    name = "gp2-waitforfirstconsumer"
  }

  storage_provisioner    = "ebs.csi.aws.com"
  volume_binding_mode    = "WaitForFirstConsumer"
  allow_volume_expansion = false

  parameters = {
    type = "gp2"
  }
}