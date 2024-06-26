#!/bin/bash


sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

if id ${var.newuser} &>/dev/null; then
    echo "User newuser already exists, no need to create."
else
    # Create the user "newuser" because they do not exist
    sudo adduser newuser --gecos "First" --disabled-password
    echo "${var.newuser}:${var.password}" | sudo chpasswd
    echo '${var.newuser} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/newuser
    echo "User ${var.newuser} created and configured."
fi
