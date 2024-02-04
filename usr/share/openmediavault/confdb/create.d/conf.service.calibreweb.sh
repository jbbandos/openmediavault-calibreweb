#!/usr/bin/env dash
#
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

set -e

. /usr/share/openmediavault/scripts/helper-functions

########################################################################
# Update the configuration.
# <config>
#   <services>
#     <calibreweb>
#       <enable>0|1</enable>
#       <port>2583</port>
#       <sslcertificateref></sslcertificateref>
#       <library_sharedfolderref></library_sharedfolderref>
#       <appdata_sharedfolderref></appdata_sharedfolderref>
#     </calibreweb>
#   </services>
# </config>
########################################################################
if ! omv_config_exists "/config/services/calibreweb"; then
	omv_config_add_node "/config/services" "calibreweb"
	omv_config_add_key "/config/services/calibreweb" "enable" "0"
	omv_config_add_key "/config/services/calibreweb" "port" "2583"
	omv_config_add_key "/config/services/calibreweb" "sslcertificateref" ""
	omv_config_add_key "/config/services/calibreweb" "library_sharedfolderref" ""
	omv_config_add_key "/config/services/calibreweb" "appdata_sharedfolderref" ""
fi

exit 0
