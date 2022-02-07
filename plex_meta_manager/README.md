# Home assistant add-on: Plex-meta-manager

[![Donate][donation-badge]](https://www.buymeacoffee.com/alexbelgium)

[donation-badge]: https://img.shields.io/badge/Buy%20me%20a%20coffee-%23d32f2f?logo=buy-me-a-coffee&style=flat&logoColor=white

![Supports
 Architecture][aarch64-shield] ![Supports amd64 Architecture][amd64-shield] ![Supports armv7 Architecture][armv7-shield]
![Supports smb mounts][smb-shield]

_Thanks to everyone having starred my repo! To star it click on the image below, then it will be on top right. Thanks!_

[![Stargazers repo roster for @alexbelgium/hassio-addons](https://reporoster.com/stars/alexbelgium/hassio-addons)](https://github.com/alexbelgium/hassio-addons/stargazers)

## About

---

[Plex-meta-manager](https://plex-meta-manager.video/) is a Python 3 script that can be continuously run using YAML configuration files to update on a schedule the metadata of the movies, shows, and collections in your libraries as well as automatically build collections based on various methods all detailed in the wiki.

This addon is based on the docker image https://github.com/linuxserver/docker-plex-meta-manager

## Installation

---

The installation of this add-on is pretty straightforward and not different in comparison to installing any other add-on.

1. Add my add-ons repository to your home assistant instance (in supervisor addons store at top right, or click button below if you have configured my HA)
   [![Open your Home Assistant instance and show the add add-on repository dialog with a specific repository URL pre-filled.](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Falexbelgium%2Fhassio-addons)
1. Install this add-on.
1. Click the `Save` button to store your configuration.
1. Set the add-on options to your preferences
1. Start the add-on.
1. Check the logs of the add-on to see if everything went well.
1. Open the webUI and adapt the software options

## Configuration

There is a [walkthrough](https://github.com/meisnate12/Plex-Meta-Manager/wiki/Docker-Walkthrough#setting-up-the-initial-config-file) available to help get you up and running.
For more information see the [official wiki](https://github.com/meisnate12/Plex-Meta-Manager/wiki).

Options can be configured through two ways :

- Addon options

```yaml
PUID: 1000 #for UserID - see below for explanation
PGID: 1000 #for GroupID - see below for explanation
TZ: Europe/London #Specify a timezone to use EG Europe/London.
PMM_CONFIG: /config/addons_config/plex-data-manager/config/config.yml #Specify a custom config file to use.
PMM_TIME: 03:00 #Comma-separated list of times to update each day. Format: HH:MM.
PMM_RUN: False #Set to True to run without the scheduler.
PMM_TEST: False #Set to True to run in debug mode with only collections that have test: true.
PMM_NO_MISSING: False #Set to True to run without any of the missing movie/show functions.
```

- Config.yaml

Additional variables can be set as ENV variables by adding them in the config.yaml in the location defined in your addon options

The complete list of ENV variables can be seen here : https://github.com/meisnate12/Plex-Meta-Manager/wiki/Run-Commands-&-Environmental-Variables

## Support

Create an issue on github

## Illustration

---

![illustration](https://dausruddin.com/wp-content/uploads/2020/05/plex-meta-manager-v3-1024x515.png)

[repository]: https://github.com/alexbelgium/hassio-addons
[smb-shield]: https://img.shields.io/badge/smb-yes-green.svg
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[armv7-shield]: https://img.shields.io/badge/armv7-yes-green.svg