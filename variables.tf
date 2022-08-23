variable "amdnodetype" {
  description = "AMD based nodegroup instance type"
  type        = string
  default       = "t3a.medium"
}
variable "amdnodedesired" {
  description = "AMD based nodegroup instance desired count"
  type        = number
  default       = 2
}
variable "amdnodemin" {
  description = "AMD based nodegroup instance minmum count"
  type        = number
  default       = 1
}
variable "armnodetype" {
  description = "ARM based nodegroup instance type"
  type        = string
  default       = "t4g.medium"
}
variable "armnodedesired" {
  description = "ARM based nodegroup instance desired count"
  type        = number
  default       = 2
}
variable "armnodemin" {
  description = "ARM based nodegroup instance minmum count"
  type        = number
  default       = 1
}
variable "prometheus" {
  description = "True or false ? for installing addons"
  type        = bool
  default       = true
}
variable "traefik" {
  description = "True or false ? for installing addons"
  type        = bool
  default       = true
}
variable "argo_rollouts" {
  description = "True or false ? for installing addons"
  type        = bool
  default       = true
}
variable "vault" {
  description = "True or false ? for installing addons"
  type        = bool
  default       = true
}
variable "metrics_server" {
  description = "True or false ? for installing addons"
  type        = bool
  default       = true
}

