<?php
/* updates.php - this file is part of SOGo
 *
 *  Copyright (C) 2006-2014 Inverse inc.
 *  
 *
 * This file is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This file is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

/* This script handles the automatic propagation of extensions pertaining to a
   SOGo site. It requires PHP 4.1.0 or later. */
$UPD_SITE="default";

#Update Site
if (isset($_GET["site"]))
	$UPD_SITE=$_GET["site"];

include $UPD_SITE . "/updater_config.php";

$pluginname = $_GET["plugin"];
$plugin =& $plugins[$pluginname];
$application =& $applications[$plugin["application"]];

$tb_version=$UPD_SITE;

if ( $plugin ) {
  $platform = $_GET["platform"];
  if ( $platform
       && file_exists( $tb_version . "/" . $platform . "/" . $plugin["filename"] ) ) {
    $plugin["filename"] = $tb_version . "/" . $platform . "/" . $plugin["filename"];
  }
  elseif ( file_exists( $tb_version . "/" . $plugin["filename"] ) ) {
    $plugin["filename"] = $tb_version . "/" . $plugin["filename"];
  } else {
    $plugin = false; 	 
  }
}

if ( $plugin ) {
  header("Content-type: text/xml; charset=utf-8");
  echo ('<?xml version="1.0"?>' . "\n");
?>
<!DOCTYPE RDF>
<RDF xmlns="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:em="http://www.mozilla.org/2004/em-rdf#">
  <Description about="urn:mozilla:extension:<?php echo $pluginname ?>">
    <em:updates>
      <Seq>
        <li>
          <Description>
            <em:version><?php echo $plugin["version"] ?></em:version>
            <em:targetApplication>
              <Description><?php echo $applications[$plugin["application"]] ?>
		<em:updateLink><?php echo dirname(getenv('SCRIPT_URI')) . '/' . $plugin["filename"] ?></em:updateLink>
	      </Description>
            </em:targetApplication>
          </Description>
        </li>
      </Seq>
    </em:updates>
  </Description>
</RDF>
<?php
} else {
  header("Content-type: text/plain; charset=utf-8", true, 404);
  echo( 'Plugin not found' );
}
?>
