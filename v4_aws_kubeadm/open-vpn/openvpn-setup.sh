#!/bin/bash
echo "Waiting for OpenVPN Access Server to initialize..."
sleep 90

echo "Setting admin password..."
ADMIN_PASSWORD="password"
sudo /usr/local/openvpn_as/scripts/sacli --user openvpn --new_pass "$ADMIN_PASSWORD" SetLocalPassword

echo "Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

echo "Configuring OpenVPN server settings..."
sudo /usr/local/openvpn_as/scripts/sacli --key "host.name" --value "$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.daemon.tcp.port" --value "443" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.daemon.udp.port" --value "1194" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.0" --value "10.0.0.0/16" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.1" --value "10.1.0.0/16" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_network.2" --value "10.2.0.0/16" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.routing.private_access" --value "true" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.dhcp_option.dns.0" --value "10.0.0.2" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.nat.enable" --value "true" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.nat.netmask.0" --value "10.0.0.0/16" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.nat.netmask.1" --value "10.1.0.0/16" ConfigPut
sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.server.nat.netmask.2" --value "10.2.0.0/16" ConfigPut

sudo /usr/local/openvpn_as/scripts/sacli --key "vpn.client.routing.reroute_gw" --value "false" ConfigPut

echo "Creating client profile..."
sudo /usr/local/openvpn_as/scripts/sacli --user client1 --key "prop_autologin" --value "true" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user client1 --key "prop_superuser" --value "false" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user client1 --new_pass "ClientPassword123" SetLocalPassword

echo "Creating admin profile..."
sudo /usr/local/openvpn_as/scripts/sacli --user admin --key "prop_autologin" --value "true" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user admin --key "prop_superuser" --value "true" UserPropPut
sudo /usr/local/openvpn_as/scripts/sacli --user admin --new_pass "AdminPassword123" SetLocalPassword

echo "Applying changes and restarting services..."
sudo /usr/local/openvpn_as/scripts/sacli start

echo "Generating client profiles for download..."
mkdir -p /tmp/client_profiles

CLIENT1_PROFILE=$(sudo /usr/local/openvpn_as/scripts/sacli --user client1 GetAutologin)
echo "$CLIENT1_PROFILE" > /tmp/client_profiles/client1.ovpn

ADMIN_PROFILE=$(sudo /usr/local/openvpn_as/scripts/sacli --user admin GetAutologin)
echo "$ADMIN_PROFILE" > /tmp/client_profiles/admin.ovpn

chmod 644 /tmp/client_profiles/*.ovpn

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "OpenVPN Access Server has been configured!"
echo "Admin web interface: https://$PUBLIC_IP:943/admin"
echo "Admin username: openvpn"
echo "Admin password: $ADMIN_PASSWORD"
echo ""
echo "Client profiles have been generated in /tmp/client_profiles/"
echo "Use 'scp' to download them to your local machine:"
echo "scp -i your-key.pem ec2-user@$PUBLIC_IP:/tmp/client_profiles/*.ovpn ."
echo ""
echo "Alternative URLs for client profiles:"
echo "https://$PUBLIC_IP:943/?src=connect client1"
echo "https://$PUBLIC_IP:943/?src=connect admin"
echo ""
echo "IMPORTANT: Make sure your AWS VPC routing is properly configured:"
echo "- Verify there's a route between the 10.0.0.0/16 VPC, 10.1.0.0/16 VPC, and 10.2.0.0/16 VPC"
echo "- Check that security groups allow traffic between VPCs and from VPN clients"