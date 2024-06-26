#!/bin/bash


sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

if id ${var.user} &>/dev/null; then
    echo "User user already exists, no need to create."
else
    # Create the user "newuser" because they do not exist
    sudo adduser ${var.user} --gecos "First" --disabled-password
    echo "${var.user}:${var.password}" | sudo chpasswd
    echo '${var.user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${var.user}
    echo "User ${var.user} created and configured."
fi
