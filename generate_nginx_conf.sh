# Script made by GraFX Software Solutions - www.grafxsoftware.com
# use at your own risk.
# this script will read from PLESK database all your domains and 
# subdomains and will generate the conf files in 
# /var/www/vhosts/*/conf/nginx.conf
# You must have the 2 template near this script. 
# template_dom.conf and template_subdom.conf

# /usr/local/psa/admin/sbin/websrvmng --set-http-port --port=8080
# /usr/local/psa/admin/sbin/websrvmng --reconfigure-all
# /usr/local/psa/admin/sbin/webmailmng --disable --name=horde
# /usr/local/psa/admin/sbin/webmailmng --enable --name=horde
# /usr/local/psa/admin/sbin/webmailmng --disable --name=atmail
# /usr/local/psa/admin/sbin/webmailmng --enable --name=atmail
# /usr/local/psa/admin/sbin/webmailmng --disable --name=atmailcom
# /usr/local/psa/admin/sbin/webmailmng --enable --name=atmailcom
#To get a custom Apache web server http port, issue the following command:
# /usr/local/psa/admin/sbin/websrvmng --get-http-port
# /opt/sitebuilder/utils/configure --httpd_port 8080

# Change the application_url  parameter in Sitebuilder configuration file:
# host# grep application_url /opt/sitebuilder/config
# application_url = "http://sitebuilder.<hostname>:8080"
# Change link to Sitebuilder in Parallels Plesk Panel database:
# echo "select * from SBConfig where param_name='url';"| mysql -uadmin -p`cat /etc/psa/.psa.shadow` psa
# param_name param_value
# url http://sitebuilder.<hostname>:8080/ServiceFacade/
# echo "update SBConfig SET param_value='http://sitebuilder.<hostname>:8080/ServiceFacade/' where param_name='url';"| mysql -uadmin -p`cat /etc/psa/.psa.shadow` psa

srcdir="./"
IPADD=`ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' | head -n 1`

echo "IP = $IPADD"
process() {
	cat "$1" | sed -e "s/{DOMAIN}/$R_DOMAIN/g" -e "s/{SUBDOMAIN}/$R_SUBDOMAIN/g" -e "s/{DOMAINALIAS}/$R_DOMAINALIAS/g" -e "s/{IPADD}/$R_IPADD/g" >> $2

}
	
R_DOMAIN=""
R_SUBDOMAIN=""
R_DOMAINALIAS=""
R_IPADD=$IPADD


echo 'select name from domains;' | mysql -BN -u admin -p`cat /etc/psa/.psa.shadow` psa | 
while read domain
do
	export aliases=""

	tmpalias=$(echo "SELECT domainaliases.name FROM domainaliases,domains WHERE domainaliases.dom_id=domains.id AND domains.name='$domain';" | mysql -BN -u admin -p`cat /etc/psa/.psa.shadow` psa)
	for dalias in $tmpalias
	do
		aliases="$aliases $dalias www.$dalias "
	done
	outdir="/var/www/vhosts/$domain/conf"
	outfile="$outdir/nginx.conf"
	echo $outfile
	echo > "$outfile"
	R_DOMAIN=$domain
	R_DOMAINALIAS=$aliases
	process "$srcdir/template_dom.conf" "$outfile"
	process "$srcdir/template_webmail.conf" "$outfile"
	process "$srcdir/template_sitebuilder.conf" "$outfile"
	process "$srcdir/template_lists.conf" "$outfile"
done

R_DOMAINALIAS=""

echo 'select concat(subdomains.name,"#",domains.name) from subdomains,domains where subdomains.dom_id=domains.id;' | mysql -BN -u admin -p`cat /etc/psa/.psa.shadow` psa  | 
while read line
do
	subdomain=`echo $line | cut -f 1 -d "#"`
	domain=`echo $line | cut -f 2 -d "#"`
	
	outdir="/var/www/vhosts/$domain/conf"
	outfile="$outdir/nginx.conf"
	echo $outfile  "($subdomain)"
	
	R_DOMAIN=$domain
	R_SUBDOMAIN=$subdomain

	process "$srcdir/template_subdom.conf" "$outfile"
done


# Script made by GraFX Software Solutions - www.grafxsoftware.com
