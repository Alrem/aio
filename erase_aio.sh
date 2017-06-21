#!/bin/bash
virsh destroy aio_mcp
virsh undefine aio_mcp
virsh net-destroy mcp_ext
virsh net-undefine mcp_ext
