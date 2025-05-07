#!/bin/bash
set -e

apt-get update
apt-get upgrade -y

apt-get install -y git curl wget build-essential software-properties-common