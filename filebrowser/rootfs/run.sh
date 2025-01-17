#!/usr/bin/env bashio

##########
# BANNER #
##########

if bashio::supervisor.ping; then
    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue " Add-on: $(bashio::addon.name)"
    bashio::log.blue " $(bashio::addon.description)"
    bashio::log.blue \
        '-----------------------------------------------------------'

    bashio::log.blue " Add-on version: $(bashio::addon.version)"
    if bashio::var.true "$(bashio::addon.update_available)"; then
        bashio::log.magenta ' There is an update available for this add-on!'
        bashio::log.magenta \
            " Latest add-on version: $(bashio::addon.version_latest)"
        bashio::log.magenta ' Please consider upgrading as soon as possible.'
    else
        bashio::log.green ' You are running the latest version of this add-on.'
    fi

    bashio::log.blue " System: $(bashio::info.operating_system)" \
        " ($(bashio::info.arch) / $(bashio::info.machine))"
    bashio::log.blue " Home Assistant Core: $(bashio::info.homeassistant)"
    bashio::log.blue " Home Assistant Supervisor: $(bashio::info.supervisor)"

    bashio::log.blue \
        '-----------------------------------------------------------'
    bashio::log.blue \
        ' Please, share the above information when looking for help'
    bashio::log.blue \
        ' or support in, e.g., GitHub, forums or the Discord chat.'
    bashio::log.green \
        ' https://github.com/alexbelgium/hassio-addons'
    bashio::log.blue \
        '-----------------------------------------------------------'
fi

######################
# MOUNT LOCAL SHARES #
######################

# Mount local Share if configured and if Protection Mode is active
if bashio::config.has_value 'localdisks'; then
    bashio::log.info 'Mounting local hdd...'
    bashio::require.unprotected
    MOREDISKS=$(bashio::config 'localdisks')
    bashio::log.info "Local Disks mounting.. ${MOREDISKS}" && \
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
        bashio::log.info "Mount ${disk}"
        mkdir -p /share/$disk && \
            if [ ! -d /share/$disk ]; then
              echo "Creating /share/$disk"
              mkdir -p /share/$disk
              chown -R abc:abc /share/$disk
            fi
            mount /dev/$disk /share/$disk && \
            bashio::log.info "Success!"   
    done || \
    bashio::log.warning "Protection mode is ON. Unable to mount local drives!"
fi || true

####################
# MOUNT SMB SHARES #
####################
if bashio::config.has_value 'networkdisks'; then
    # Mount CIFS Share if configured and if Protection Mode is active
    bashio::log.info 'Mounting smb share(s)...'

    # Define variables 
    MOREDISKS=$(bashio::config 'networkdisks')
    CIFS_USERNAME=$(bashio::config 'cifsusername')
    CIFS_PASSWORD=$(bashio::config 'cifspassword')
    MOUNTED=false
    SMBVERS=""
    SECVERS=""

    if bashio::config.has_value 'cifsdomain'; then 
      DOMAIN=",domain=$(bashio::config 'cifsdomain')" 
    else
      DOMAIN=""
    fi
 
    # Mounting disks
    for disk in ${MOREDISKS//,/ }  # Separate comma separated values
    do
      # Clean name of network share
      disk=$(echo $disk | sed "s,/$,,") # Remove / at end of name
      diskname=${disk//\\//} #replace \ with /
      diskname=${diskname##*/} # Get only last part of the name
      # Prepare mount point
      mkdir -p /mnt/$diskname
      chown -R root:root /mnt/$diskname
      
      #Tries to mount with default options
      mount -t cifs -o rw,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$DOMAIN $disk /mnt/$diskname 2>ERRORCODE && MOUNTED=true || MOUNTED=false
      
      # if Fail test different smb and sec versions
      if [ $MOUNTED = false ]; then
        for SMBVERS in ",vers=3" ",vers=1.0" ",vers=2.1" ",vers=3.0" ",nodfs" ",uid=0,gid=0,forceuid,forcegid" ",noforceuid,noforcegid" ",${DOMAIN}"
        do
           mount -t cifs -o rw,iocharset=utf8,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS $disk /mnt/$diskname 2>/dev/null && MOUNTED=true && break  || MOUNTED=false
           for SECVERS in ",sec=ntlmi" ",sec=ntlmv2" ",sec=ntlmv2i" ",sec=ntlmssp" ",sec=ntlmsspi" ",sec=ntlm" ",sec=krb5i" ",sec=krb5"
           do
                mount -t cifs -o rw,iocharset=utf8,file_mode=0777,dir_mode=0777,username=$CIFS_USERNAME,password=${CIFS_PASSWORD}$SMBVERS$SECVERS $disk /mnt/$disk name 2>/dev/null && MOUNTED=true && break 2 && break || MOUNTED=false
           done
        done
      fi

      # Messages
      if [ $MOUNTED = true ]; then
        #Test write permissions
        touch /mnt/$diskname/testaze && rm /mnt/$diskname/testaze && bashio::log.info "... $disk successfully mounted to /mnt/$diskname with options $SMBVERS$SECVERS" || bashio::log.fatal "Disk is mounted, however unable to write in the shared disk. Please check UID/GID for permissions, and if the share is rw" 
      else
        # message if still fail
        bashio::log.fatal "Unable to mount $disk to /mnt/$diskname with username $CIFS_USERNAME, $CIFS_PASSWORD. Please check your remote share path, username, password, domain, try putting 0 in UID and GID" # Mount share
        bashio::log.fatal "Error read : $(<ERRORCODE)" # Mount share
        rm ERRORCODE
      fi

    done
fi || true

#################
# NGINX SETTING #
#################

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile

#port=$(bashio::addon.port 80)
#ingress_port=$(bashio::addon.ingress_port)
#ingress_interface=$(bashio::addon.ip_address)
#sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
#sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
#sed -i "s/%%baseurl%%/filebrowser/g" /etc/nginx/servers/ingress.conf
#mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

###################
# SSL CONFIG v1.0 #
###################

bashio::config.require.ssl
if bashio::config.true 'ssl'; then
  bashio::log.info "ssl enabled. If webui don't work, disable ssl or check your certificate paths"
  #set variables
  CERTFILE="-t /ssl/$(bashio::config 'certfile')"
  KEYFILE="-k /ssl/$(bashio::config 'keyfile')"
else
  CERTFILE=""
  KEYFILE=""
fi

####################
# SET UID GID v1.0 #
####################
bashio::log.info 'PUID GUID set to root'
PUID=0
PGID=0

######################
# LAUNCH FILEBROWSER #
######################

NOAUTH=""

if bashio::config.true 'NoAuth'; then
  if ! bashio::fs.file_exists "/data/noauth"; then
    rm /data/auth &> /dev/null || true
    rm /config/filebrowser/filebrowser.dB &> /dev/null || true
    touch /data/noauth
    NOAUTH="--noauth"
    bashio::log.warning "Auth method change, database reset"
  fi
  bashio::log.info "NoAuth option selected"
else
  if ! bashio::fs.file_exists "/data/auth"; then
    rm /data/noauth &> /dev/null || true
    rm /config/filebrowser/filebrowser.dB &> /dev/null || true
    touch /data/auth
    bashio::log.warning "Auth method change, database reset"
  fi
  bashio::log.info "Default username/password : admin/admin"
fi

bashio::log.info "Please wait 1 or 2 minutes to allow the server to load"

/./filebrowser $CERTFILE $KEYFILE --root=/ --address=0.0.0.0 --database=/config/filebrowser/filebrowser.dB $NOAUTH 

#& \
#bashio::net.wait_for 8080 localhost 900 || true
#bashio::log.info "Nginx started for Ingress" 
#exec nginx
