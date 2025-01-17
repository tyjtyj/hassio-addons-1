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

#################
# NGINX SETTING #
#################

declare port
declare certfile
declare ingress_interface
declare ingress_port
declare keyfile
# Set path
UIPATH=$(bashio::config 'ui_path')

port=$(bashio::addon.port 80)
ingress_port=$(bashio::addon.ingress_port)
ingress_interface=$(bashio::addon.ip_address)
sed -i "s/%%port%%/${ingress_port}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%interface%%/${ingress_interface}/g" /etc/nginx/servers/ingress.conf
sed -i "s/%%path%%/${UIPATH}/g" /etc/nginx/servers/ingress.conf
mkdir -p /var/log/nginx && touch /var/log/nginx/error.log

################
# JOAL SETTING #
################

declare TOKEN
TOKEN=$(bashio::config 'secret_token')
VERBOSE=$(bashio::config 'verbose') || true

# check password change 

if [ "$TOKEN" = "lrMY24Byhx" ]; then
bashio::log.warning "The token is still the default one, please change from addon options" 
fi

# download latest version

if [ $VERBOSE = true ]; then
  curl -J -L -o /tmp/joal.tar.gz $(curl -s https://api.github.com/repos/anthonyraymond/joal/releases/latest | grep -o "http.*joal.tar.gz")
  #wget -O /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/$UPSTREAM/joal.tar.gz"
else
  curl -s -S -J -L -o /tmp/joal.tar.gz $(curl -s https://api.github.com/repos/anthonyraymond/joal/releases/latest | grep -o "http.*joal.tar.gz") >/dev/null
  #wget -q -O /tmp/joal.tar.gz "https://github.com/anthonyraymond/joal/releases/download/$UPSTREAM/joal.tar.gz"
fi
mkdir -p /data/joal
tar zxvf /tmp/joal.tar.gz -C /data/joal >/dev/null
chown -R $(id -u):$(id -g) /data/joal
rm /data/joal/jack-of*
bashio::log.info "Joal updated"

##################
# SYMLINK CONFIG #
##################

# If config doesn't exist, create it
if [ ! -f /config/joal/config.json ]; then
  bashio::log.info "Symlinking config files" 
  mkdir -p /config/joal
  cp /data/joal/config.json /config/joal/config.json
fi

# Refresh symlink
ln -sf /config/joal/config.json /data/joal/config.json

#####################
# AUTOMATIC INGRESS #
#####################

if bashio::config.has_value 'ingress_url'; then
  INGRESSURL=$(bashio::config 'ingress_url')
  sed -i "s|/ui/|/ui?ui_credentials=%7B%22host%22%3A%22${INGRESSURL}%22%2C%22port%22%3A%228123%22%2C%22pathPrefix%22%3A%22${UIPATH}%22%2C%22secretToken%22%3A%22${TOKEN}%22%7D|g" /etc/nginx/servers/ingress.conf
  bashio::log.info "Ingress url set. Auto connection activated."
else
  bashio::log.info "Ingress url not set. Connection must be done manually."
fi

###############
# LAUNCH APPS #
###############

if [ $VERBOSE = true ]; then 
  nohup java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix=${UIPATH} --joal.ui.secret-token=$TOKEN
else
  nohup java -jar /joal/joal.jar --joal-conf=/data/joal --spring.main.web-environment=true --server.port="8081" --joal.ui.path.prefix=${UIPATH} --joal.ui.secret-token=$TOKEN >/dev/null
fi \
& bashio::log.info "Joal started with path ip/${UIPATH}/ui secret token $TOKEN"
# Wait for transmission to become available
bashio::net.wait_for 8081 localhost 900 || true
bashio::log.info "Nginx started for Ingress" 
exec nginx & \

###########
# TIMEOUT #
###########

if bashio::config.has_value 'run_duration'; then
  RUNTIME=$(bashio::config 'run_duration')
  bashio::log.info "Addon will stop after $RUNTIME"
  sleep $RUNTIME && \
  bashio::log.info "Timeout achieved, addon will stop !" && \
  exit 0
else
  bashio::log.info "Run_duration option not defined, addon will run continuously"
fi
