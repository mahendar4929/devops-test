variable "ingressrules" {
  type    = list(number)
  default = [22, 5986, 5985, 80, 443, 3389]
}

variable "winpassword" {
  type    = string
}
