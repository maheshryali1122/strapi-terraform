#!/bin/bash


sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd

if id ${user} &>/dev/null; then
    echo "User user already exists, no need to create."
else
    # Create the user "newuser" because they do not exist
    sudo adduser ${user} --gecos "First" --disabled-password
    echo "${user}:${password}" | sudo chpasswd
    echo '${user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${user}
    echo "User ${user} created and configured."
fi