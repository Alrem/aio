#!/bin/bash
sudo virsh destroy cfg01.virtual-mcp11-aio.local
sudo virsh undefine cfg01.virtual-mcp11-aio.local
sudo virsh net-destroy mcp_ext
sudo virsh net-undefine mcp_ext

