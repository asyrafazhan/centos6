#!/bin/bash

#############################################
# Install vps for indonesian phreak
# Debian 7
# By ww.fb.com/ardi85
#############################################

export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0'`;
MYIP2="s/xxxxxxxxx/$MYIP/g";
ether=`ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:`
if [ "$ether" = "" ]; then
        ether=eth0
fi


function setup_basic {
# go to root
cd

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT +7
ln -fs /usr/share/zoneinfo/Asia/Jakarta /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
wget -O /etc/apt/sources.list "https://raw.github.com/yurisshOS/debian7os/master/sources.list.debian7"
wget "http://www.dotdeb.org/dotdeb.gpg"
wget "http://www.webmin.com/jcameron-key.asc"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
cat jcameron-key.asc | apt-key add -;rm jcameron-key.asc

# remove unused
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

# update
apt-get update; apt-get -y upgrade;

# install webserver
apt-get -y install nginx php5-fpm php5-cli

# install essential package
echo "mrtg mrtg/conf_mods boolean true" | debconf-set-selections
apt-get -y install bmon iftop htop nmap axel nano iptables traceroute sysv-rc-conf dnsutils bc nethogs openvpn vnstat less screen psmisc apt-file whois ptunnel ngrep mtr git zsh mrtg snmp snmpd snmp-mibs-downloader unzip unrar rsyslog debsums rkhunter
apt-get -y install build-essential

# disable exim
service exim4 stop
sysv-rc-conf exim4 off

# update apt-file
apt-file update
# download script
cd
wget -O speedtest_cli.py "https://raw.github.com/sivel/speedtest-cli/master/speedtest_cli.py"
wget -O bench-network.sh "https://raw.github.com/yurisshOS/debian7os/master/bench-network.sh"
wget -O ps_mem.py "https://raw.github.com/pixelb/ps_mem/master/ps_mem.py"
wget -O dropmon "https://raw.github.com/yurisshOS/debian7os/master/dropmon.sh"
wget -O userlogin.sh "https://raw.github.com/yurisshOS/debian7os/master/userlogin.sh"
wget -O userexpired.sh "https://raw.github.com/yurisshOS/debian7os/master/userexpired.sh"
wget -O expire.sh "https://raw.github.com/yurisshOS/debian7os/master/expire.sh"
chmod +x bench-network.sh
chmod +x speedtest_cli.py
chmod +x ps_mem.py
chmod +x userlogin.sh
chmod +x userexpired.sh
echo "*/10 * * * * root /root/userexpired.sh" > /etc/cron.d/userexpired
echo "0 */6 * * * root /sbin/reboot" > /etc/cron.d/reboot
echo "* * * * * service dropbear restart" > /etc/cron.d/dropbear


clear

echo ""
echo "Basic installasi sudah terinstall silahkan install program lain"
echo ""
}

function setup_nginx {
# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.github.com/yurisshOS/debian7os/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>Modified by Yurissh OpenSource</pre>" > /home/vps/public_html/index.html
echo "<?php phpinfo(); ?>" > /home/vps/public_html/info.php
wget -O /etc/nginx/conf.d/vps.conf "https://raw.github.com/yurisshOS/debian7os/master/vps.conf"
sed -i 's/listen = \/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g' /etc/php5/fpm/pool.d/www.conf
chown -R www-data:www-data /home/vps/public_html
service php5-fpm restart
service nginx restart
clear

echo ""
echo "Nginx webserver sudah terinstall http://$MYIP:81/"
echo ""
} # End function 

function setup_vnstat {
# setting vnstat
vnstat -u -i $ether
echo "MAILTO=root" > /etc/cron.d/vnstat
echo "*/5 * * * * root /usr/sbin/vnstat.cron" >> /etc/cron.d/vnstat
sed -i "s/eth0/$ether/" /etc/sysconfig/vnstat
service vnstat restart

# install vnstat gui
cd /home/vps/public_html/
wget http://www.sqweek.com/sqweek/files/vnstat_php_frontend-1.5.1.tar.gz
tar xf vnstat_php_frontend-1.5.1.tar.gz
rm vnstat_php_frontend-1.5.1.tar.gz
mv vnstat_php_frontend-1.5.1 vnstat
cd vnstat
sed -i 's/eth0/venet0/g' config.php
sed -i "s/\$iface_list = array('venet0', 'sixxs');/\$iface_list = array('venet0');/g" config.php
sed -i "s/\$language = 'nl';/\$language = 'en';/g" config.php
sed -i 's/Internal/Internet/g' config.php
sed -i '/SixXS IPv6/d' config.php
cd
clear

echo ""
echo "vnstat sudah terinstall http://$MYIP:81/vnstat"
echo ""
} # End function 

function setup_screenfetch {
# install screenfetch
cd
wget 'https://raw.github.com/yurisshOS/debian7os/master/screeftech-dev'
mv screeftech-dev /usr/bin/screenfetch
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile
clear

echo ""
echo "Screenfetch sudah terinstall"
echo ""
} # End function 

function setup_openvpn {
if [ $USER != 'root' ]; then
	echo "Sorry, you need to run this as root"
	exit
fi


if [ ! -e /dev/net/tun ]; then
    echo "TUN/TAP is not available"
    exit
fi

# Try to get our IP from the system and fallback to the Internet.
# I do this to make the script compatible with NATed servers (lowendspirit.com)
# and to avoid getting an IPv6.
IP=$(ifconfig | grep 'inet addr:' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | cut -d: -f2 | awk '{ print $1}' | head -1)
if [ "$IP" = "" ]; then
        IP=$(wget -qO- ipv4.icanhazip.com)
fi

if [ -e /etc/openvpn/server.conf ]; then
	while :
	do
	clear
		echo "Looks like OpenVPN is already installed"
		echo "What do you want to do?"
		echo ""
		echo "1) Remove OpenVPN"
		echo "2) Exit"
		echo ""
		read -p "Select an option [1-4]:" option
		case $option in
			1) 
			apt-get remove --purge -y openvpn
			rm -rf /etc/openvpn
			rm -rf /usr/share/doc/openvpn
			sed -i '/--dport 53 -j REDIRECT --to-port 1194/d' /etc/rc.local
			sed -i '/iptables -t nat -A POSTROUTING -s 10.8.0.0/d' /etc/rc.local
			echo ""
			echo "OpenVPN removed!"
			exit
			;;
			2) exit;;
		esac
	done
else
	echo 'Selamat Datang di quick OpenVPN "road warrior" installer'
	echo "Modifikasi Oleh Abu naifa untuk opreker"
	echo ""
	# OpenVPN setup and first user creation
	echo "Pertama-tama saya perlu tahu alamat IPv4 yang ingin diinstall OpenVPN"
	echo "listening to."
	read -p "IP address: " -e -i $IP IP
	echo ""
	echo "Port untuk OpenVPN?"
	read -p "Port: " -e -i 1194 PORT
	echo ""
	echo "Apakah Anda ingin OpenVPN akan tersedia pada port 53 juga?"
	echo "Hal ini dapat berguna untuk menghubungkan ke restrictive networks"
	read -p "Listen port 53 [y/n]:" -e -i y ALTPORT
	echo ""
	echo "Sebutkan namamu untuk cert klien"
	echo "Silakan, gunakan satu kata saja, tidak ada karakter khusus"
	read -p "Nama Client: " -e -i client CLIENT
	echo ""
	echo "Oke, itu semua saya butuhkan. Kami siap untuk setup OpenVPN server Anda sekarang"
	read -n1 -r -p "Tekan sembarang tombol untuk melanjutkan ..."
	apt-get update
	apt-get install openvpn iptables openssl -y
	cp -R /usr/share/doc/openvpn/examples/easy-rsa/ /etc/openvpn
	# easy-rsa isn't available by default for Debian Jessie and newer
	if [ ! -d /etc/openvpn/easy-rsa/2.0/ ]; then
		wget --no-check-certificate -O ~/easy-rsa.tar.gz https://github.com/OpenVPN/easy-rsa/archive/2.2.2.tar.gz
		tar xzf ~/easy-rsa.tar.gz -C ~/
		mkdir -p /etc/openvpn/easy-rsa/2.0/
		cp ~/easy-rsa-2.2.2/easy-rsa/2.0/* /etc/openvpn/easy-rsa/2.0/
		rm -rf ~/easy-rsa-2.2.2
	fi
	cd /etc/openvpn/easy-rsa/2.0/
	# Let's fix one thing first...
	cp -u -p openssl-1.0.0.cnf openssl.cnf
	# Bad NSA - 1024 bits was the default for Debian Wheezy and older
	#sed -i 's|export KEY_SIZE=1024|export KEY_SIZE=2048|' /etc/openvpn/easy-rsa/2.0/vars
	# Create the PKI
	. /etc/openvpn/easy-rsa/2.0/vars
	. /etc/openvpn/easy-rsa/2.0/clean-all
	# The following lines are from build-ca. I don't use that script directly
	# because it's interactive and we don't want that. Yes, this could break
	# the installation script if build-ca changes in the future.
	export EASY_RSA="${EASY_RSA:-.}"
	"$EASY_RSA/pkitool" --initca $*
	# Same as the last time, we are going to run build-key-server
	export EASY_RSA="${EASY_RSA:-.}"
	"$EASY_RSA/pkitool" --server server
	# Now the client keys. We need to set KEY_CN or the stupid pkitool will cry
	export KEY_CN="$CLIENT"
	export EASY_RSA="${EASY_RSA:-.}"
	"$EASY_RSA/pkitool" $CLIENT
	# DH params
	. /etc/openvpn/easy-rsa/2.0/build-dh
	# Let's configure the server
cat > /etc/openvpn/server.conf <<-END
port 1194
proto tcp
dev tun
tun-mtu 1500
tun-mtu-extra 32
mssfix 1450
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh1024.pem
plugin /usr/lib/openvpn/openvpn-auth-pam.so /etc/pam.d/login
client-cert-not-required
username-as-common-name
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
push "route-method exe"
push "route-delay 2"
keepalive 5 30
cipher AES-128-CBC
comp-lzo
persist-key
persist-tun
status server-vpn.log
verb 3
END

	cd /etc/openvpn/easy-rsa/2.0/keys
	cp ca.crt ca.key dh1024.pem server.crt server.key /etc/openvpn
	sed -i "s/port 1194/port $PORT/" /etc/openvpn/server.conf
	# Listen at port 53 too if user wants that
	if [ $ALTPORT = 'y' ]; then
		iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port 1194
		sed -i "/# By default this script does nothing./a\iptables -t nat -A PREROUTING -p udp -d $IP --dport 53 -j REDIRECT --to-port 1194" /etc/rc.local
	fi
	# Enable net.ipv4.ip_forward for the system
	sed -i 's|#net.ipv4.ip_forward=1|net.ipv4.ip_forward=1|' /etc/sysctl.conf
	# Avoid an unneeded reboot
	echo 1 > /proc/sys/net/ipv4/ip_forward
	# Set iptables
	if [ $(ifconfig | cut -c 1-8 | sort | uniq -u | grep venet0 | grep -v venet0:) = "venet0" ];then
      		iptables -t nat -A POSTROUTING -o venet0 -j SNAT --to-source $IP
	else
      		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP
      		iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
	fi	
	sed -i "/# By default this script does nothing./a\ip10tables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP" /etc/rc.local
	iptables-save
	# And finally, restart OpenVPN
	/etc/init.d/openvpn restart
	# Let's generate the client config
	mkdir ~/ovpn-$CLIENT
	# Try to detect a NATed connection and ask about it to potential LowEndSpirit
	# users
	EXTERNALIP=$(wget -qO- ipv4.icanhazip.com)
	if [ "$IP" != "$EXTERNALIP" ]; then
		echo ""
		echo "Looks like your server is behind a NAT!"
		echo ""
		echo "If your server is NATed (LowEndSpirit), I need to know the external IP"
		echo "If that's not the case, just ignore this and leave the next field blank"
		read -p "External IP: " -e USEREXTERNALIP
		if [ $USEREXTERNALIP != "" ]; then
			IP=$USEREXTERNALIP
		fi
	fi
	# IP/port set on the default client.conf so we can add further users
	# without asking for them

cat >> ~/ovpn-$CLIENT/$CLIENT.conf <<-END
client
proto tcp
persist-key
persist-tun
dev tun
pull
comp-lzo
ns-cert-type server
verb 3
mute 2
mute-replay-warnings
auth-user-pass
redirect-gateway def1
script-security 2
route-method exe
route-delay 2
remote $IP $PORT
cipher AES-128-CBC
ca [inline]
END

	cp /etc/openvpn/easy-rsa/2.0/keys/ca.crt ~/ovpn-$CLIENT

	cd ~/ovpn-$CLIENT

	cp $CLIENT.conf $CLIENT.ovpn


	echo "<ca>" >> $CLIENT.ovpn
	cat ca.crt >> $CLIENT.ovpn
	echo -e "</ca>\n" >> $CLIENT.ovpn

	tar -czf ../ovpn-$CLIENT.tar.gz $CLIENT.conf ca.crt $CLIENT.ovpn
	cd ~/
	rm -rf ovpn-$CLIENT
	echo ""
	echo "Selesai!"
	echo ""
	echo "Your client config is available at ~/ovpn-$CLIENT.tar.gz"
fi
	clear

echo ""
echo "OpenVPN sudah terinstall http://$MYIP:81/client.tar atau /root/client.tar"
echo ""
} # End function 

function setup_badvpn {
# install badvpn
wget -O /usr/bin/badvpn-udpgw "https://raw.github.com/yurisshOS/debian7os/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.github.com/yurisshOS/debian7os/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300
clear

echo ""
echo "Badvpn sudah terinstall"
echo ""
} # End function 

function setup_mrtg {
# install mrtg
wget -O /etc/snmp/snmpd.conf "http://aemrhabibin.tk:81/Script/snmpd.conf"
wget -O /root/mrtg-mem.sh "http://aemrhabibin.tk:81/Script/mrtg-mem.sh"
chmod +x /root/mrtg-mem.sh
cd /etc/snmp/
sed -i 's/TRAPDRUN=no/TRAPDRUN=yes/g' /etc/default/snmpd
service snmpd restart
snmpwalk -v 1 -c public localhost 1.3.6.1.4.1.2021.10.1.3.1
mkdir -p /home/vps/public_html/mrtg
cfgmaker --zero-speed 100000000 --global 'WorkDir: /home/vps/public_html/mrtg' --output /etc/mrtg.cfg public@localhost
curl "http://aemrhabibin.tk:81/Script/mrtg.conf" >> /etc/mrtg.cfg
sed -i 's/WorkDir: \/var\/www\/mrtg/# WorkDir: \/var\/www\/mrtg/g' /etc/mrtg.cfg
sed -i 's/# Options\[_\]: growright, bits/Options\[_\]: growright/g' /etc/mrtg.cfg
indexmaker --output=/home/vps/public_html/mrtg/index.html /etc/mrtg.cfg
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
if [ -x /usr/bin/mrtg ] && [ -r /etc/mrtg.cfg ]; then mkdir -p /var/log/mrtg ; env LANG=C /usr/bin/mrtg /etc/mrtg.cfg 2>&1 | tee -a /var/log/mrtg/mrtg.log ; fi
cd
clear

echo ""
echo "Mrtg sudah terinstall http://$MYIP:81/mrtg"
echo ""
} # End function 

function setup_openssh {
# setting port ssh
sed -i '/Port 22/a Port  143' /etc/ssh/sshd_config
sed -i '/Port 22/a Port  80' /etc/ssh/sshd_config
sed -i 's/Port 22/Port  22/g' /etc/ssh/sshd_config
service ssh restart
clear

echo ""
echo "Openssh sudah terinstall dengan port 22,80,143"
echo "" 
} # End function 

function setup_dropbear {
# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=443/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS=""/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart
clear

echo ""
echo "dropbear sudah terinstall dengan port 443"
echo ""
} # End function 

function setup_fail2ban {
# install fail2ban
apt-get -y install fail2ban;service fail2ban restart
clear

echo ""
echo "fail2ban sudah terinstall"
echo ""

} # End function 

function setup_squid {
# install squid3
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.github.com/yurisshOS/debian7os/master/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart
clear

echo ""
echo "Squid sudah terinstall dengan port 8080"
echo ""
} # End function 

function setup_webmin {
# install webmin
cd
wget http://prdownloads.sourceforge.net/webadmin/webmin_1.690_all.deb
dpkg -i --force-all webmin_1.690_all.deb;
apt-get -y -f install;
rm /root/webmin_1.690_all.deb
service webmin restart
service vnstat restart
clear

echo ""
echo "webmin sudah terinstall http://$MYIP:10000/"
echo ""
} # End function 

function setup_pptp {

#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
export PATH
 
clear
CUR_DIR=$(pwd)
 
if [ $(id -u) != "0" ]; then
    printf "Error: You must be root to run this script!"
    exit 1
fi
 
apt-get -y update
apt-get -y autoremove pptpd
apt-get -y install pptpd iptables
 
sed -i '/exit 0/d' /etc/rc.local
 
mknod /dev/ppp c 108 0
echo "mknod /dev/ppp c 108 0" >> /etc/rc.local
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sysctl -p
echo echo 1 \> \/proc\/sys\/net\/ipv4\/ip_forward >> /etc/rc.local
 
echo exit 0 >> /etc/rc.local
 
cat >>/etc/pptpd.conf<<EOF
localip 172.16.36.1
remoteip 172.16.36.2-254
EOF
 
cp /etc/ppp/pptpd-options /etc/ppp/pptpd-options.old
cat >/etc/ppp/pptpd-options<<EOF
name pptpd
refuse-pap
refuse-chap
refuse-mschap
require-mschap-v2
require-mppe-128
ms-dns 8.8.8.8
ms-dns 8.8.4.4
proxyarp
#debug
#dump
lock
nobsdcomp
novj
novjccomp
logfile /var/log/pptpd.log
EOF
 
echo vpn pptpd 123 \* >> /etc/ppp/chap-secrets
 
iptables-save > /etc/iptables.down.rules
 
n=`ifconfig  | grep 'venet0:0' | awk 'NR==1 { print $1}'`
if test "$n" == venet0:0; then
# For OpenVZ
iptables -t nat -D POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127\.0\.0\.' | grep -v '10\.' | grep -v '172\.' | grep -v '192\.' | cut -d: -f2 | awk 'NR==1 { print $1}'`
iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127\.0\.0\.' | grep -v '10\.' | grep -v '172\.' | grep -v '192\.' | cut -d: -f2 | awk 'NR==1 { print $1}'`
else
# For Xen and KVM
iptables -t nat -D POSTROUTING -s 172.16.36.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.16.36.0/24 -o eth0 -j MASQUERADE
fi
 
iptables -D FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
iptables -A FORWARD -p tcp --syn -s 172.16.36.0/24 -j TCPMSS --set-mss 1356
 
iptables-save > /etc/iptables.up.rules
 
cat >>/etc/network/if-pre-up.d/iptables<<EOF
#!/bin/bash
/sbin/iptables-restore < /etc/iptables.up.rules
EOF
 
chmod +x /etc/network/if-pre-up.d/iptables
 
/etc/init.d/pptpd restart
} # End function 

#### Main program begins ####

# Show Menu
if [ ! -n "$1" ]; then
    echo ""
    echo -e  "\033[35;1mPilih dari opsi di bawah untuk menggunakan script ini: \033[0m"

    echo -n "$0"
    echo -ne "\033[36m basic\033[0m"
    echo     " - Install basic (jalankan ini untuk pertama kali)"

    echo -n "$0"
    echo -ne "\033[36m nginx\033[0m"
    echo     " - Install nginx webserver http://$MYIP:81"

    echo -n  "$0"
    echo -ne "\033[36m vnstat\033[0m"
    echo     " - Install vnstat need nginx"

    echo -n "$0"
    echo -ne "\033[36m screenfetch\033[0m"
    echo     " - Install screenfetch"

    echo -n "$0"
    echo -ne "\033[36m openvpn\033[0m"
    echo     " - Install openvpn tcp port 1194"

    echo -n "$0"
    echo -ne "\033[36m badvpn\033[0m"
    echo     " - Install badvpn"

    echo -n "$0"
    echo -ne "\033[36m mrtg\033[0m"
    echo     " - Install mrtg need nginx"

    echo -n "$0"
    echo -ne "\033[36m openssh\033[0m"
    echo     " - Install openssh port 22, 80, 143"

    echo -n "$0"
    echo -ne "\033[36m dropbear\033[0m"
    echo     " - Install dropbear port 109, 110, 443"

    echo -n "$0"
    echo -ne "\033[36m fail2ban\033[0m"
    echo     " - Install fail2ban"

    echo -n "$0"
    echo -ne "\033[36m webmin\033[0m"
    echo     " - Install webmin"

    echo -n "$0"
    echo -ne "\033[36m squid\033[0m"
    echo     " - Install squid 3 limit ip"

    echo -n "$0"
    echo -ne "\033[36m pptp\033[0m"
    echo     " - Install pptpd vpn"

    echo ""
    exit
fi
# End Show Menu

case $1 in
basic)
    setup_basic
    ;;
nginx)
    setup_nginx
    ;;
vnstat)
    setup_vnstat
    ;;
screenfetch)
    setup_screenfetch
    ;;
openvpn)
    setup_openvpn
    ;;
badvpn)
    setup_badvpn
    ;;
mrtg)
	setup_mrtg
    ;;
openssh)
    setup_openssh
    ;;
dropbear)
    setup_dropbear
    ;;
fail2ban)
    setup_fail2band
    ;;
squid)
    setup_squid
    ;;
webmin)
    setup_webmin
    ;;
pptp)
    setup_pptp
    ;;
esac
