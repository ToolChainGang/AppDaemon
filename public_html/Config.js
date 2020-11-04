////////////////////////////////////////////////////////////////////////////////
//
// Config.js - Javascript for Config pages
//
// Copyright (C) 2020 Peter Walsh, Milford, NH 03055
// All Rights Reserved under the MIT license as outlined below.
//
////////////////////////////////////////////////////////////////////////////////
//
//  MIT LICENSE
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//    of the Software, and to permit persons to whom the Software is furnished to do
//    so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//    INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
//    PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//    HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
//    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
////////////////////////////////////////////////////////////////////////////////
//
//      Config->
//          {SysName}->'raspberrypi',
//          {NetDevs}->[ 'eth0', 'wlan0', ... ],
//          {  About}->[ <list of about lines>... ],
//          {WPAInfo}->
//              {   Valid}->1,          // TRUE if wpa_supplicant.conf exists
//              {    SSID>->'Okima',
//              { KeyMGMT}->'WPA-PSK',
//              {Password}->'(something)',
//              { Country}->'US'
//              { Changed}-> 1          // Set by config page if user changes something
//          {DHCPInfo}->
//              {$IF}->                 // ex: $Config.DHCPInfo.wlan0->
//                  {Enabled}->0,
//                  {   DHCP}->1,
//                  { IPAddr}->'192.168.1.31/24',
//                  { Router}->'192.168.1.1',
//                  {   DNS1}->'1.0.0.1',
//                  {   DNS2}->'1.1.1.1',
//
////////////////////////////////////////////////////////////////////////////////

    var ConfigSystem = location.hostname;
    var ConfigAddr   = "ws:" + ConfigSystem + ":2021";

    var ConfigSocket;
    var ConfigData;

    var WindowWidth;
    var WindowHeight;

    var Config;
    var OrigConfig;
    var WifiList;
    var Wifi;           // Chosen Wifi, from list

    var NameInput;

    //
    // One line of the "devices" table listing
    //
    var IFTemplate = '\
        <tr><td style="width: 20%">&nbsp;</td><td style="width: 20%"><h2>$IF</h2></td><td></td></tr>                \
        <tr><td style="width: 20%">&nbsp;</td><td colspan="2">                                                      \
            <input type="checkbox" id=$IF-Enabled" name="$IF-Enabled" $EN onchange="ToggleEnable(this)" >Enabled    \
            </td></tr>';

    //
    // If device is enabled, add this to the bottom
    //
    var StaticTemplate = '\
        <tr><td style="width: 20%">&nbsp;</td><td colspan="2">                                                      \
            <input type="checkbox" id="$IF-DHCP" name="$IF-DHCP" $DHCP onchange="ToggleDHCP(this)" >                \
            Automatic (using DHCP)                                                                                  \
            </td></tr>                                                                                              \
        <tr><td style="width: 20%">&nbsp;</td><td colspan="3">                                                      \
            <table id="$IF-Static" summary="$IF-Static">                                                            \
                <tr><td style="width: 5%">&nbsp;</td><td style="width: 30%">&nbsp;</td><td>&nbsp;</td></tr>         \
                <tr><td>&nbsp;</td><td>IP/mask:</td><td><input $DDIS class="IP" id="$IF-IPAddr" value="$IPAddr" \></td></tr> \
                <tr><td>&nbsp;</td><td>Router :</td><td><input $DDIS class="IP" id="$IF-Router" value="$Router" \></td></tr> \
                <tr><td>&nbsp;</td><td>DNS1   :</td><td><input $DDIS class="IP" id="$IF-DNS1"   value="$DNS1"   \></td></tr> \
                <tr><td>&nbsp;</td><td>DNS2   :</td><td><input $DDIS class="IP" id="$IF-DNS2"   value="$DNS2"   \></td></tr> \
                </table>                                                                                            \
            </td></tr>';


    //
    // On first load, calculate reliable page dimensions and do page-specific initialization
    //
    window.onload = function() {
        //
        // (This crazy nonsense gets the width in all browsers)
        //
        WindowWidth  = window.innerWidth  || document.documentElement.clientWidth  || document.body.clientWidth;
        WindowHeight = window.innerHeight || document.documentElement.clientHeight || document.body.clientHeight;

        PageInit();     // Page specific initialization

        ConfigConnect();
        NameInput = document.getElementById("SysName");
        }

    //
    // Send a command to the web page
    //
    function ConfigCommand(Command,Arg1,Arg2,Arg3) {
        ConfigSocket.send(JSON.stringify({
            "Type"  : Command,
            "Arg1"  : Arg1,
            "Arg2"  : Arg2,
            "Arg3"  : Arg3,
             }));
        }

    function ConfigConnect() {
        ConfigSocket = new WebSocket(ConfigAddr);
        ConfigSocket.onmessage = function(Event) {
            ConfigData = JSON.parse(Event.data);

            if( ConfigData["Error"] != "No error." ) {
                console.log("Error: "+ConfigData["Error"]);
                console.log("Msg:   "+Event.data);
                 alert("Error: " + ConfigData["Error"]);
                return;
                }

//            console.log("Msg: "+Event.data);

            if( ConfigData["Type"] == "GetWifiList" ) {
//                console.log(ConfigData);
                WifiList = ConfigData.State.wlan0;
                //
                // Fix ideopathic problem: Sometimes the IWList function returns nothing, with no error.
                //
                if( typeof WifiList == 'undefined' ) {
                    ConfigCommand("GetWifiList"); 
                    return;
                    }
                GotoPage("SSIDPage");
                return;
                }

            if( ConfigData["Type"] == "GetConfig" ) {
//                console.log(ConfigData);
                Config          = ConfigData.State;
                OrigConfig      = JSON.parse(Event.data).State;     // Deep clone
                NameInput.value = OrigConfig.SysName;
                SysNameElements = document.getElementsByClassName("SysName");
                for (i = 0; i < SysNameElements.length; i++) {
                    SysNameElements[i].innerHTML = OrigConfig.SysName;
                    };

                //
                // Disable file sharing page if samba not installed
                //
                if( !OrigConfig.FSInfo.Valid ) {
                    SBLine = document.getElementById("SB");
                    SBLine.style.display = "none";
                    }

                GotoPage("TOCPage");
                return;
                }

            if( ConfigData["Type"] == "SetConfig" ) {
//                console.log(ConfigData);
                return;
                }

            //
            // Unexpected messages
            //
            console.log(ConfigData);
            alert(ConfigData["Type"] + " received");
            };

        ConfigSocket.onopen = function(Event) {
            ConfigCommand("GetConfig");
            }
        };


    //
    // Cycle through the various pages
    //
    function GotoPage(PageName) {

        Pages = document.getElementsByClassName("PageDiv");

        for (i = 0; i < Pages.length; i++) {
            Pages[i].style.display = "none";
            };

        if( PageName == "TOCPage"      ) { PopulateTOCPage(); }
        if( PageName == "ScanningPage" ) { ConfigCommand("GetWifiList"); }
        if( PageName == "SSIDPage"     ) { PopulateSSIDPage(); }
        if( PageName == "SysNamePage"  ) { PopulateSysNamePage(); }
        if( PageName == "NetworkPage"  ) { PopulateNetworkPage(); }
        if( PageName == "SharingPage"  ) { PopulateSharingPage(); }
        if( PageName == "AboutPage"    ) { PopulateAboutPage(); }
        if( PageName == "ReviewPage"   ) { PopulateReviewPage(); }
        if( PageName == "EpilogPage"   ) { PopulateEpilogPage(); }

        document.getElementById(PageName).style.display = "block";
        };

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateTOCPage - Populate the directory page as needed
    //
    function PopulateTOCPage() {
        WifiList = undefined;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSSIDPage - Populate the SSID page with newly received SSID list
    //
    function PopulateSSIDPage() {
        var CurrentSSID = document.getElementById("CurrentSSID");

        var UsingPassword = " (with no password)";
        if( OrigConfig.WPAInfo.Password.length ) {
            UsingPassword = " (with password)";
            }

        CurrentSSID.innerHTML = OrigConfig.WPAInfo.SSID + UsingPassword;

        var WifiNames = document.getElementById("WifiNames");

        WifiNames.innerHTML = "<tr>"               +
                              "<td>&nbsp;   </td>" +
                              "<td>Network  </td>" +
                              "<td>&nbsp;&nbsp;Signal&nbsp;&nbsp;</td>" +
                              "<td>Password</td>"  +
                              "</tr>";

        WifiList.forEach(function (Wifi) { 
            if( Wifi.SSID == "--none--" )
                return;

            WifiNames.innerHTML += WifiTableLine(Wifi.SSID,Wifi.Quality,Wifi.Encryption == "on");
            });

        Wifi = undefined;
        }

    //
    // WifiTableLine
    //
    function WifiTableLine(SSID,Quality,PWNeeded) {
        var TableLine = "<tr>" + 
                        "<td><button class='SSIDButton' onclick=ChooseSSID('" + SSID + "') >Use</button></td>" +
                        "<td class=\"WifiText\">" + SSID    + "</td>" +
                        "<td><center>" + Quality + "</center></td>" +
                        "<td><center>" + (PWNeeded ? "yes" : "") + "</center></td>" +
                        "</tr>";

        return TableLine;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // ChooseSSID - Select and choose SSID to use
    //
    function ChooseSSID(SSID) {
        WifiList.forEach(function (This) { 
            if( This.SSID == SSID )
                Wifi = This;
            });

        if( Wifi == undefined ) {
            alert("SSID " + SSID + " not in list.");
            GotoPage("ScanningPage");
            return;
            }

        document.getElementById("EnterWifi").innerHTML = SSID;

        if( Wifi.Encryption != "on" ) {
            ChangeSSID();
            return;
            }

        document.getElementById("PasswordField").style.display = "block";
        }

    //
    // EnterPassword - Process entered password chars
    //
    function EnterPassword(Event) {
        var characterCode;

        if( Event && Event.which ) {
            characterCode = Event.which;
            }
        else{
            characterCode = Event.keyCode;
            }

        if( characterCode == 13 ) {     // Enter
            ChangeSSID();
            }
        }

    //
    // ChangeSysName - Processed entered system names
    //
    function ChangeSSID() {
        if( Wifi != undefined ) {       // If user selected an SSID
            Config.WPAInfo.SSID     = document.getElementById("EnterWifi").innerHTML;
            Config.WPAInfo.Password = document.getElementById("Password").value;
            }
        GotoPage("TOCPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSysNamePage - Populate the directory page as needed
    //
    function PopulateSysNamePage() {
        NameInput.value = Config.SysName;
        }

    //
    // EnterSysName - Process "enter" in sysname field
    //
    function EnterSysName(Event) {
        var characterCode;

        if( Event && Event.which ) {
            characterCode = Event.which;
            }
        else{
            characterCode = Event.keyCode;
            }

        if( characterCode == 13 ) {     // Enter
            ChangeSysName();
            }
        }

    //
    // ChangeSysName - Processed entered system names
    //
    function ChangeSysName() {
        var NewName = document.getElementById("SysName").value;

        if( ! /^[a-zA-Z0-9_][a-zA-Z0-9-_][a-zA-Z0-9_]{1,61}$/.test(NewName) ) {
            alert(NameInput.value + " is not a valid system name.");
            return;
            }

        Config.SysName = NewName;
        GotoPage("TOCPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateNetworkPage - Populate the network page as needed
    //
    function PopulateNetworkPage() {
        var IFTable = document.getElementById("IFTable");
        IFTable.innerHTML = "";

        Config.NetDevs.forEach(function (IF) { 
            var IFEntry    = IFTemplate.replaceAll("$IF",IF)
                                       .replaceAll("$EN",Config.DHCPInfo[IF].Enabled ? "checked" : "");
            IFTable.innerHTML += IFEntry;

            if( Config.DHCPInfo[IF].Enabled ) {
                var StaticTable = StaticTemplate.replaceAll("$IF"    ,IF)
                                                .replaceAll("$DHCP"  ,Config.DHCPInfo[IF].DHCP ? "checked"  : "")
                                                .replaceAll("$DDIS"  ,Config.DHCPInfo[IF].DHCP ? "disabled" : "")
                                                .replaceAll("$IPAddr",Config.DHCPInfo[IF].IPAddr)
                                                .replaceAll("$Router",Config.DHCPInfo[IF].Router)
                                                .replaceAll("$DNS1"  ,Config.DHCPInfo[IF].DNS1)
                                                .replaceAll("$DNS2"  ,Config.DHCPInfo[IF].DNS2);
                IFTable.innerHTML += StaticTable; 
                }
            });
        }

    function ToggleEnable(EnableCheckbox) {
        var IF = EnableCheckbox.name.replace("-Enabled","");
        Config.DHCPInfo[IF].Enabled = 1 - Config.DHCPInfo[IF].Enabled;
        PopulateNetworkPage();
        }

    function ToggleDHCP(DHCPCheckbox) {
        var IF = DHCPCheckbox.name.replace("-DHCP","");
        Config.DHCPInfo[IF].DHCP = 1 - Config.DHCPInfo[IF].DHCP;
        PopulateNetworkPage();
        }

    //
    // UpdateIF - Process entered IF data
    //
    function UpdateIF(Event) {
        var TOC = true;
        Config.NetDevs.forEach(function (IF) { 

            if( !Config.DHCPInfo[IF].Enabled ) {        // Elements below don't exist
                return;
                }

            if( Config.DHCPInfo[IF].DHCP     ) {        // Elements below don't matter
                return;
                }

            var IPAddr = document.getElementById(IF+"-IPAddr").value;
            var Router = document.getElementById(IF+"-Router").value;
            var DNS1   = document.getElementById(IF+"-DNS1"  ).value;
            var DNS2   = document.getElementById(IF+"-DNS2"  ).value;

            if( ! /^\d*\.\d*\.\d*\.\d*\/\d*$/.test(IPAddr) ) {
                alert('IP address "' + IPAddr + '" is not a valid IP address/mask combination.');
                TOC = false;
                return;
                }

            if( ! /^\d*\.\d*\.\d*\.\d*$/.test(Router) ) {
                alert('Router "' + Router + '" is not a valid IP address.');
                TOC = false;
                return;
                }

            if( ! /^\d*\.\d*\.\d*\.\d*$/.test(DNS1) ) {
                alert('DNS1 "' + DNS1 + '" is not a valid IP address.');
                TOC = false;
                return;
                }

            if( ! /^\d*\.\d*\.\d*\.\d*$/.test(DNS2) && ! (DNS2 == "") ) {
                alert('DNS2 "' + DNS2 + '" is not a valid IP address.');
                TOC = false;
                return;
                }

            Config.DHCPInfo[IF].IPAddr = IPAddr;
            Config.DHCPInfo[IF].Router = Router;
            Config.DHCPInfo[IF].DNS1   = DNS1;
            Config.DHCPInfo[IF].DNS2   = DNS2;
            });

        if( TOC ) {
            GotoPage("TOCPage");
            }
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSharingPage - Populate the directory page as needed
    //
    function PopulateSharingPage() {
        WorkgroupElement = document.getElementById("CurrentWorkgroup");
        WorkgroupElement.innerHTML = OrigConfig.FSInfo.Workgroup;
        }

    //
    // EnterWGName - Process "enter" in sysname field
    //
    function EnterWGName(Event) {
        var characterCode;

        if( Event && Event.which ) {
            characterCode = Event.which;
            }
        else{
            characterCode = Event.keyCode;
            }

        if( characterCode == 13 ) {     // Enter
            ChangeWGName();
            }
        }

    //
    // ChangeWgName - Processed entered workgroup names
    //
    function ChangeWGName() {
        var NewName = document.getElementById("WGName").value;

        Config.FSInfo.Workgroup = NewName;
        GotoPage("TOCPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateAboutPage - Populate the directory page as needed
    //
    function PopulateAboutPage() {
        var InfoLines = document.getElementById("InfoLines");
        InfoLines.innerHTML = '<tr><td style="width: 10%"><h1>About:&nbsp;</h1></td><td><h1><span class="' + OrigConfig.SysName + '"></span></h1></td></tr>';

        Config.About.forEach(function (InfoLine) { 
            var FmtLine = InfoLine.replace(": ",":<b> ") + "</b>";
           
            InfoLines.innerHTML += '<tr><td></td><td><pre class="AboutLines" >' + FmtLine + '</pre></td></tr>';
            });
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateReviewPage - Populate the directory page as needed
    //
    function PopulateReviewPage() {
        var ReviewLines = document.getElementById("ReviewLines");
        ReviewLines.innerHTML = "";
        var TableText;

        //
        // SysName
        //
        if( document.getElementById("SN") != undefined ) {
            if( Config.SysName == OrigConfig.SysName ) { AddReviewLine("System Name: "    ,"(no change)" ); }
            else                                       { AddReviewLine("New system Name: ",Config.SysName); }
            }

        //
        // Wifi SSID and password
        //
        if( document.getElementById("WB") != undefined ) {
            if( Config.WPAInfo.SSID     != OrigConfig.WPAInfo.SSID ||
                Config.WPAInfo.Password != OrigConfig.WPAInfo.Password ) {
                TableText = Config.WPAInfo.SSID;
                if( Wifi.Encryption == "on" ) {
                    TableText += " with password";
                    }
                else {
                    TableText += " with no password";
                    }
                }
            else {
                TableText = "(no change)";
                }
            AddReviewLine("Wifi: ",TableText);
            }

        //
        // Sharing
        //
        if( document.getElementById("SB") != undefined &&
            document.getElementById("SB").style.display != "none" ) {
            if( Config.FSInfo.Workgroup != OrigConfig.FSInfo.Workgroup ) {
                TableText = Config.FSInfo.Workgroup;
                }
            else {
                TableText = "(no change)";
                }
            AddReviewLine("Workgroup: ",TableText);
            }

        //
        // Networking
        //
        if( document.getElementById("NB") != undefined ) {
            Config.NetDevs.forEach(function (IF) { 
                if( !Config.DHCPInfo[IF].Enabled ) {
                    TableText = "disabled";
                    }
                else {
                    TableText = "enabled";
                    if( Config.DHCPInfo[IF].DHCP ) {
                        TableText += ", using  DHCP";
                        }
                    else {
                        TableText += ", static IP";
                        }
                    }
                AddReviewLine(IF + ": ",TableText);

                if( Config.DHCPInfo[IF].Enabled && !Config.DHCPInfo[IF].DHCP ) {
                    AddReviewLine("","IPAddr: " + Config.DHCPInfo[IF].IPAddr);
                    AddReviewLine("","Router: " + Config.DHCPInfo[IF].Router);
                    AddReviewLine("","DNS1:   " + Config.DHCPInfo[IF].DNS2);
                    AddReviewLine("","DNS2:   " + Config.DHCPInfo[IF].DNS1);
                    }
                });
            }

        //
        // Nav buttons at the end
        //
        var ReviewNav = document.getElementById("ReviewNav").innerHTML;
        ReviewLines.innerHTML += ReviewNav;
        }

    function AddReviewLine(Label,Text) {

        ReviewLines.innerHTML += '<tr><td style="width: 20%">&nbsp;</td>' +
                                 '<td><pre class="AboutLines" >'    + Label +     '</pre></td>' +
                                 '<td><pre class="AboutLines Brown" ><b>' + Text  + '</b></pre></td>' +
                                 '</tr>';
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateEpilogPage - Populate the directory page as needed
    //
    function PopulateEpilogPage() {
        ConfigCommand("SetConfig",Config);
        }
