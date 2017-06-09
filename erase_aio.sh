#!/bin/bash
sudo virsh destroy aio_mcp
sudo virsh undefine aio_mcp
sudo virsh net-destroy mcp_ext
sudo virsh net-undefine mcp_ext

