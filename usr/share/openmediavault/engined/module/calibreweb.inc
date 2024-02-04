<?php
/**
 * This file is part of OpenMediaVault.
 *
 * @license   http://www.gnu.org/licenses/gpl.html GPL Version 3
 * @author    Volker Theile <volker.theile@openmediavault.org>
 * @copyright Copyright (c) 2009-2024 Volker Theile
 *
 * OpenMediaVault is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * OpenMediaVault is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with OpenMediaVault. If not, see <http://www.gnu.org/licenses/>.
 */
namespace Engined\Module;

class CalibreWeb extends \OMV\Engine\Module\ServiceAbstract
		implements \OMV\Engine\Notify\IListener, \OMV\Engine\Module\IServiceStatus {
	public function getName() {
		return "calibreweb";
	}

	public function deployAfter(): array {
		return ["certificates"];
	}

	public function getStatus() {
		$db = \OMV\Config\Database::getInstance();
		$object = $db->get("conf.service.calibreweb");
		$systemCtl = new \OMV\System\SystemCtl("pod-calibreweb");
		return [
			"name" => $this->getName(),
			"title" => gettext("CalibreWeb"),
			"enabled" => $object->get("enable"),
			"running" => $systemCtl->isActive()
		];
	}

	final public function onModifySharedFolder($type, $path, $object) {
		$db = \OMV\Config\Database::getInstance();
		if (TRUE === $db->exists("conf.service.calibreweb", [
			"operator" => "or",
			"arg0" => [
				"operator" => "stringEquals",
				"arg0" => "library_sharedfolderref",
				"arg1" => $object['uuid']
			],
			"arg1" => [
				"operator" => "or",
				"arg0" => [
					"operator" => "stringEquals",
					"arg0" => "appdata_sharedfolderref",
					"arg1" => $object['uuid']
				]
			]
		])) {
			$this->setDirty();
		}
	}

	function bindListeners(\OMV\Engine\Notify\Dispatcher $dispatcher) {
		$dispatcher->addListener(
			OMV_NOTIFY_MODIFY,
			"org.openmediavault.conf.service.calibreweb",
			[$this, "setDirty"]);
		$dispatcher->addListener(
			OMV_NOTIFY_MODIFY,
			"org.openmediavault.conf.system.sharedfolder",
			[$this, "onModifySharedFolder"]);
		$moduleMngr = \OMV\Engine\Module\Manager::getInstance();
		$dispatcher->addListener(
			OMV_NOTIFY_MODIFY,
			"org.openmediavault.conf.service.calibreweb",
			[$moduleMngr->getModule("zeroconf"), "setDirty"]);
	}
}
