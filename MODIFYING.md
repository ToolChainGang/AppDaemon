## Overview

The AppDaemon is meant to be integrated into your application. Once you get the AppDaemon running, 
modify it to look like a part of your project.

## Changing the config page looks

The page "public_html/index.html" contains all the configuration pages. Feel free to add your
company logo, and make the page branding closer to your own such as the colors, font face
and so on.

The accompanying Config.js and Config.css file are also relevant.

## Adding default config files

The AppDaemon tries to update the existing configuration files with information entered by the user,
but it is not intelligent.

If your product needs default configurations, either supply
- No configuration block, or
- A fully defined configuration block

In particular, do not supply a partial configuration block as part of your default system given to
customers. The AppDaemon will not properly deal with these.

For example, the following configuration block in /etc/dhcpcd.conf is acceptable:

````
interface wlan0
    static ip_address=192.168.1.31/24
    static routers=192.168.1.1
    static domain_name_servers=1.1.1.1 1.0.0.1
````

This is a fully fleshed block, and will be parsed correctly. If the user makes changes, those changes
will be edited inline and saved.

Having *no* configuration block is acceptable - AppDaemon detects this and will add a complete block if
needed.

The following configuration block in /etc/dhcpcd.conf is not acceptable:

````
interface wlan0
    static ip_address=192.168.1.31/24
````

Since only a partial block is supplied, AppDaemon will not properly process it during the "save and reboot"
process.

The same caveat applies to /etc/wpa_cupplicant/wpa_supplicant.conf: supply either no file, or a file with
complete connection credentials.

## Disabling network interfaces

Lines in the file AppDaemon/etc/netenable can selectively enable/disable network interfaces as needed.

For example, if your product uses an external WiFi dongle and you want to disable the built-in WiFi,
place the following in AppDaemon/etc/netenable:

```
wlan0:  disable
```

On system boot, the AppDaemon will execute "ifconfig $IF down" for all disabled interfaces listed in
that file.

---
## Adding lines to the "About" page

Lines in the file AppDaemon/etc/about will be automatically added to the end of the "About" page.

Place descriptive text about your application in that file, and the end user will see it on the
"About" page during configuration.

To reformat the About page, edit the function "PopulateAboutPage()" in Config.js as needed.

---
## Removing panels

To remove unneeded panels from the system, it is sufficient to comment out the TOC button.
The "About" page will notice the missing button and omit the information from the removed page.

### For example, to remove "File Sharing" entirely, change this:

```
<table id="TOCTable">
    <tr><td><img id="WB" class="NavButton" src="images/Wifi.png"    title="Wifi"        onclick=GotoPage("ScanningPage") /></td><td><h2>Wifi        </h2></td></tr>
    <tr><td><img id="SN" class="NavButton" src="images/SysName.png" title="System name" onclick=GotoPage("SysNamePage")  /></td><td><h2>System Name </h2></td></tr>
    <tr><td><img id="NB" class="NavButton" src="images/Network.png" title="Network"     onclick=GotoPage("NetworkPage")  /></td><td><h2>Networking  </h2></td></tr>
    <tr><td><img id="SB" class="NavButton" src="images/Sharing.png" title="Sharing"     onclick=GotoPage("SharingPage")  /></td><td><h2>Sharing     </h2></td></tr>
    <tr><td><img id="AB" class="NavButton" src="images/About.png"   title="About"       onclick=GotoPage("AboutPage")    /></td><td><h2>About       </h2></td></tr>
    <tr><td><h2>&nbsp;</h2></td></tr>
    <tr><td><img class="NavButton" src="images/Review.png"  title="Review and save" onclick=GotoPage("ReviewPage")   /></td><td><h2>Review and save </h2></td></tr>
    </table>
```

###to this:

```
<table id="TOCTable">
    <tr><td><img id="WB" class="NavButton" src="images/Wifi.png"    title="Wifi"        onclick=GotoPage("ScanningPage") /></td><td><h2>Wifi        </h2></td></tr>
    <tr><td><img id="SN" class="NavButton" src="images/SysName.png" title="System name" onclick=GotoPage("SysNamePage")  /></td><td><h2>System Name </h2></td></tr>
    <tr><td><img id="NB" class="NavButton" src="images/Network.png" title="Network"     onclick=GotoPage("NetworkPage")  /></td><td><h2>Networking  </h2></td></tr>
<!--    <tr><td><img id="SB" class="NavButton" src="images/Sharing.png" title="Sharing"     onclick=GotoPage("SharingPage")  /></td><td><h2>Sharing     </h2></td></tr>-->
    <tr><td><img id="AB" class="NavButton" src="images/About.png"   title="About"       onclick=GotoPage("AboutPage")    /></td><td><h2>About       </h2></td></tr>
    <tr><td><h2>&nbsp;</h2></td></tr>
    <tr><td><img class="NavButton" src="images/Review.png"  title="Review and save" onclick=GotoPage("ReviewPage")   /></td><td><h2>Review and save </h2></td></tr>
    </table>
```

---
## Adding panels for your application

To add a new panel:
- Add an entry (button/link) to the TOC
- Add the new page with class="PageDiv"
- Add an entry to the "GotoPage()" function in Config.js
- Add code to populate your page
- Add code to get data from the server

### Example: Adding a new panel for an app named "GPIOServer":

In index.html, add a line to the TOC:

<pre><code>
&lt;table id="TOCTable"&gt;
    &lt;tr&gt;&lt;td&gt;&lt;img id="WB" class="NavButton" src="images/Wifi.png"    title="Wifi"        onclick=GotoPage("ScanningPage") /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;Wifi        &lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
    &lt;tr&gt;&lt;td&gt;&lt;img id="SN" class="NavButton" src="images/SysName.png" title="System name" onclick=GotoPage("SysNamePage")  /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;System Name &lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
    &lt;tr&gt;&lt;td&gt;&lt;img id="NB" class="NavButton" src="images/Network.png" title="Network"     onclick=GotoPage("NetworkPage")  /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;Networking  &lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
<b>    &lt;tr&gt;&lt;td&gt;&lt;img id="AB" class="NavButton" src="images/GPIO.png"    title="GPIO"        onclick=GotoPage("GPIOPage")     /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;GPIOs&lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;</b>
    &lt;tr&gt;&lt;td&gt;&lt;img id="AB" class="NavButton" src="images/About.png"   title="About"       onclick=GotoPage("AboutPage")    /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;About       &lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
    &lt;tr&gt;&lt;td&gt;&lt;h2&gt;&nbsp;&lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
    &lt;tr&gt;&lt;td&gt;&lt;img class="NavButton" src="images/Review.png"  title="Review and save" onclick=GotoPage("ReviewPage")   /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;Review and save &lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
    &lt;/table&gt;
</code></pre>


In index.html, add the actual page:

<pre><code>
&lt;div id="GPIOPage" class="PageDiv"&gt;
    &lt;table id="GPIOLines" summary="GPIO Configuration"&gt;
        &lt;tr&gt;&lt;td style="width: 10%"&gt;&lt;h1&gt;GPIO for:&nbsp;&lt;/h1&gt;&lt;/td&gt;&lt;td&gt;&lt;h1&gt;&lt;span class="SysName"&gt;&lt;/span&gt;&lt;/h1&gt;&lt;/td&gt;&lt;/tr&gt;
        &lt;/table&gt;

    &lt;table class="NavTable"&gt;
        &lt;tr&gt;&lt;td&gt;&nbsp;&lt;/td&gt;&lt;/tr&gt;
        &lt;tr&gt;&lt;td&gt;&lt;img class="NavButton" src="images/Back.png" title="Back" onclick=GotoPage("TOCPage")    /&gt;&lt;/td&gt;&lt;td&gt;&lt;h2&gt;Back&lt;/h2&gt;&lt;/td&gt;&lt;/tr&gt;
        &lt;/table&gt;

    &lt;/div&gt;
</code></pre>

In Config.js, add the page navigation:

<pre><code>
        if( PageName == "TOCPage"      ) { PopulateTOCPage(); }
        if( PageName == "ScanningPage" ) { ConfigCommand("GetWifiList"); }
        if( PageName == "SSIDPage"     ) { PopulateSSIDPage(); }
        if( PageName == "SysNamePage"  ) { PopulateSysNamePage(); }
        if( PageName == "NetworkPage"  ) { PopulateNetworkPage(); }
        if( PageName == "SharingPage"  ) { PopulateSharingPage(); }
        if( PageName == "AboutPage"    ) { PopulateAboutPage(); }
        if( PageName == "ReviewPage"   ) { PopulateReviewPage(); }
        if( PageName == "EpilogPage"   ) { PopulateEpilogPage(); }
<b>        if( PageName == "GPIOPage"     ) { ConfigCommand("GetGPIO"); }</b>
</code></pre>

In ConfigServer, add code to retrieve the information when it arrives:

<pre><code>
    #
    # GetGPIOList - Return list of GPIO stuff
    #
    elsif( $Request->{Type} eq "GetGPIOList" ) {
        Message("ConfigServer: GetGPIOList()")
            if $Verbose;
        $Request->{Error} = "No error.";
        $Request->{State} = GetGPIOList();  <b>#&lt;-- You supply this function</b>
        }
</code></pre>

In Config.js, add code to populate the page:

<pre><code>
    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateGPIOPage - Populate the GPIO page as needed
    //
    function PopulateGPIOPage() {
        <b>... Your code goes here ...</b>
        }
</code></pre>

In Config.js, add code to receive the new data:

<pre><code>
    if( ConfigData["Type"] == "GetGPIO" ) {
//                console.log(ConfigData);
        var GPIOList = ConfigData.State;

        PopulateGPIOPage(GPIOList);
        return;
        }
</code></pre>
