#!/bin/bash

service redis-server start && openvassd && openvasmd && gsad --allow-header-host 192.168.239.137
