# This file is part of OpenMediaVault.
#
# @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
# @author    Volker Theile <volker.theile@openmediavault.org>
# @copyright Copyright (c) 2009-2024 Volker Theile
#
# OpenMediaVault is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# OpenMediaVault is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with OpenMediaVault. If not, see <http://www.gnu.org/licenses/>.

# Documentation/Howto:
# https://github.com/janeczku/calibre-web
# https://docs.linuxserver.io/images/docker-calibre-web/
# https://caddyserver.com/docs/caddyfile

# Testing:
# podman exec -it calibreweb-app /bin/bash
# cat /config/log/nginx/error.log
# podman logs -f calibreweb-app
# podman logs -f calibreweb-proxy

{% set config = salt['omv_conf.get']('conf.service.calibreweb') %}
{% set app_image = salt['pillar.get']('default:OMV_CALIBREWEB_APP_CONTAINER_IMAGE', 'docker.io/linuxserver/calibre-web:latest') %}
{% set proxy_image = salt['pillar.get']('default:OMV_CALIBREWEB_PROXY_CONTAINER_IMAGE', 'docker.io/library/caddy:latest') %}
{% set ssl_enabled = config.sslcertificateref | length > 0 %}

{% if config.enable | to_bool %}

{% set appdata_sf_path = salt['omv_conf.get_sharedfolder_path'](config.appdata_sharedfolderref) %}

create_calibreweb_appdata_storage_dir:
  file.directory:
    - name: "{{ appdata_sf_path }}/books/"

create_calibreweb_appdata_config_dir:
  file.directory:
    - name: "{{ appdata_sf_path }}/config/"

create_calibreweb_app_container_systemd_unit_file:
  file.managed:
    - name: "/etc/systemd/system/container-calibreweb-app.service"
    - source:
      - salt://{{ tpldir }}/files/container-calibreweb-app.service.j2
    - template: jinja
    - context:
        config: {{ config | json }}
    - user: root
    - group: root
    - mode: 644

create_calibreweb_pod_systemd_unit_file:
  file.managed:
    - name: "/etc/systemd/system/pod-calibreweb.service"
    - source:
      - salt://{{ tpldir }}/files/pod-calibreweb.service.j2
    - template: jinja
    - context:
        config: {{ config | json }}
    - user: root
    - group: root
    - mode: 644

calibreweb_pull_app_image:
  cmd.run:
    - name: podman pull {{ app_image }}
    - unless: podman image exists {{ app_image }}
    - failhard: True

calibreweb_app_image_exists:
  cmd.run:
    - name: podman image exists {{ app_image }}
    - failhard: True

{% if ssl_enabled %}

create_calibreweb_proxy_container_systemd_unit_file:
  file.managed:
    - name: "/etc/systemd/system/container-calibreweb-proxy.service"
    - source:
      - salt://{{ tpldir }}/files/container-calibreweb-proxy.service.j2
    - template: jinja
    - context:
        config: {{ config | json }}
    - user: root
    - group: root
    - mode: 644

create_calibreweb_proxy_container_caddyfile:
  file.managed:
    - name: "/var/lib/calibreweb/Caddyfile"
    - source:
      - salt://{{ tpldir }}/files/Caddyfile.j2
    - template: jinja
    - context:
        config: {{ config | json }}
    - user: root
    - group: root
    - mode: 644

calibreweb_pull_proxy_image:
  cmd.run:
    - name: podman pull {{ proxy_image }}
    - unless: podman image exists {{ proxy_image }}
    - failhard: True

calibreweb_proxy_image_exists:
  cmd.run:
    - name: podman image exists {{ proxy_image }}
    - failhard: True

{% else %}

stop_calibreweb_proxy_service:
  service.dead:
    - name: container-calibreweb-proxy
    - enable: False

purge_calibreweb_proxy_container_caddyfile:
  file.absent:
    - name: "/var/lib/calibreweb/Caddyfile"

purge_calibreweb_proxy_container_systemd_unit_file:
  file.absent:
    - name: "/etc/systemd/system/container-calibreweb-proxy.service"

{% endif %}

calibreweb_systemctl_daemon_reload:
  module.run:
    - service.systemctl_reload:

start_calibreweb_service:
  service.running:
    - name: pod-calibreweb
    - enable: True
    - watch:
      - file: create_calibreweb_pod_systemd_unit_file
      - file: create_calibreweb_app_container_systemd_unit_file

{% else %}

stop_calibreweb_service:
  service.dead:
    - name: pod-calibreweb
    - enable: False

remove_calibreweb_proxy_container_caddyfile:
  file.absent:
    - name: "/var/lib/calibreweb/Caddyfile"

remove_calibreweb_app_container_systemd_unit_file:
  file.absent:
    - name: "/etc/systemd/system/container-calibreweb-app.service"

remove_calibreweb_proxy_container_systemd_unit_file:
  file.absent:
    - name: "/etc/systemd/system/container-calibreweb-proxy.service"

remove_calibreweb_pod_systemd_unit_file:
  file.absent:
    - name: "/etc/systemd/system/pod-calibreweb.service"

calibreweb_systemctl_daemon_reload:
  module.run:
    - service.systemctl_reload:

{% endif %}
