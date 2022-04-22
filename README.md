# koha-plugin-ill-avail-browzine

This plugin provides ILL availability searching for the LibKey BrowZine API.

## Getting Started

**This plugin requires the [koha-plugin-api-browzine](https://github.com/PTFS-Europe/koha-plugin-api-browzine) plugin, please install that before installing this plugin**

Download this plugin by downloading the latest release .kpz file from the [releases page](https://github.com/PTFS-Europe/koha-plugin-api-crossref/releases).

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your `koha-conf.xml` file
Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server.
Restart your webserver.
Once set up is complete you will need to alter your `UseKohaPlugins` system preference.
Finally, on the "Koha Administration" page you will see the "Manage Plugins" option, select this to access the Plugins page.

### Installing

Once your Koha has plugins turned on, as detailed above, installing the plugin is then a case of selecting the "Upload plugin"
button on the Plugins page and navigating to the .kpz file you downloaded

### Configuration

When the plugin is installed, the configuration screen requires you to specify an API key to be passed with all API requests. This key can be supplied by LibKey and is mandatory. The configuration screen also prompts for a Library ID. This also can be supplied by LibKey and is also mandatory.

## How to use the plugin

When creating an ILL request using the FreeForm plugin, once the item metadata is entered and the form is submitted, if the request contains metadata that can be searched by BrowZine (DOI & PMID are the only supported metadata properties), the user will be taken to an "Availability" page.

The BrowZine API will be searched and results displayed.
The user can then click on the result titles to view them. If they find the item they were requesting then the request should be abandoned by the user. If not, the user can continue with the request as normal.