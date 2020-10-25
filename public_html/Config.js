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

    var ConfigSystem = location.hostname;
    var ConfigAddr   = "ws:" + ConfigSystem + ":2021";

    var ConfigSocket;
    var ConfigData;

    var WindowWidth;
    var WindowHeight;

    var Config;
    var OrigConfig;
    var WifiList;

    var NameInput;

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
                 alert("Erorr: " + ConfigData["Error"]);
                return;
                }

            console.log("Msg: "+Event.data);

            if( ConfigData["Type"] == "GetNetworks" ) {
                console.log(ConfigData);
                WifiList = ConfigData.State.wlan0;
                GotoPage("SSIDPage");
                return;
                }

            if( ConfigData["Type"] == "GetConfig" ) {
//                console.log(ConfigData);
                Config          = ConfigData.State;
                OrigConfig      = JSON.parse(Event.data).State;     // Deep clone
                NameInput.value = OrigConfig.SysNamePage.Name;
                SysNameElements = document.getElementsByClassName("SysName");
                for (i = 0; i < SysNameElements.length; i++) {
                    SysNameElements[i].innerHTML = OrigConfig.SysNamePage.Name;
                    };
                GotoPage("TOCPage");
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
            NameInput = document.getElementById("SysName");
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
        if( PageName == "ScanningPage" ) { ConfigCommand("GetNetworks"); }
        if( PageName == "SSIDPage"     ) { PopulateSSIDPage(); }
        if( PageName == "SysNamePage"  ) { PopulateSysNamePage(); }
        if( PageName == "WLanPage"     ) { PopulateWLanPage(); }
        if( PageName == "ELanPage"     ) { PopulateELanPage(); }
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
        if( /[a-zA-Z0-9][a-zA-Z0-9-_]{1,61}$/.test(NameInput.value) ) {
            Config.SysNamePage.Name = NameInput.value;
            }
        else {
            alert(NameInput.value + " is not a valid system name.");
            }
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSSIDPage - Populate the SSID page with newly received SSID list
    //
    function PopulateSSIDPage() {

        var CurrentSSID = document.getElementById("CurrentSSID");
        CurrentSSID.innerHTML = OrigConfig.SSIDPage.SSID;
        
        var NoPassword  = document.getElementById("SSIDNO");
        if( OrigConfig.SSIDPage.SSID ) {
            NoPassword.style.display = "none";
            }
        else {
            NoPassword.style.display = "inline";
            }

//        console.log(WifiList);

        var WifiNames = document.getElementById("WifiNames");

        WifiNames.innerHTML = "<tr>"               +
                              "<td>Network  </td>" +
                              "<td>&nbsp;&nbsp;Signal&nbsp;&nbsp;</td>" + 
                              "<td>Password</td>" +
                              "</tr>";

        WifiList.forEach(function (Wifi) { 
            if( Wifi.SSID == "--none--" )
                return;

            WifiNames.innerHTML += WifiTableLine(Wifi.SSID,Wifi.Quality,Wifi.Encryption == "on");
            });
        }

    //
    // WifiTableLine
    //
    function WifiTableLine(SSID,Quality,PWNeeded) {
        var Checked = "";
        if( SSID === Config.SSIDPage.SSID ) Checked = "checked";

        console.log(SSID + "|" + Config.SSIDPage.SSID + "|" + Checked);

        var TableLine = '<tr>' + 
                        '<td><input type="radio" id="' + SSID + '" name="SSID" value="' + SSID + '" ' + Checked + '>' +
                            '<label for="' + SSID + '">' + SSID + '</label>' +
                        '<td><center>' + Quality + '</center></td>' +
                        '<td><center>' + (PWNeeded ? 'yes' : '') + '</center></td>' +
                        '</tr>';


        return TableLine;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // ChooseSSID - Select and choose SSID to use
    //
    function ChooseSSID() {

        var ChosenSSID = undefined;

        //
        // Grab the SSID name from the radio button list
        //
        var SSIDs = document.getElementsByTagName('SSID');
        for( var i = 0; i < SSIDs.length; i++ ) {
            if( SSIDs[i].type === 'radio' && SSIDs[i].checked ) {
                ChosenSSID = SSIDs[i].value;       
                }
            }

        //
        // Special case - no SSID originally selected, and user doesn't choose one
        //
        if( ChosenSSID == undefined ) {
            GotoPage("TOCPage");
            return;
            }

        //
        // Find the matching entry in the Wifi listing
        //
        Wifi = undefined;
        WifiList.forEach(function (This) { 
            if( This.SSID == ChosenSSID )
                Wifi = This;
            });
        if( Wifi == undefined ) {
            alert("SSID " + ChosenSSID + " not in list.");
            GotoPage("TOCPage");
            return;
            }

        if( Wifi.Encryption == "on" ) {
            document.getElementById("EnterWifi").innerHTML = ChosenSSID;
            GotoPage("PasswordPage");
            return;
            }

        GotoPage("TOCPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // EnterPassword - Populate the password page with selected wifi name & take password
    //
    function EnterPassword() {
        Config.SSIDPage.SSID     = document.getElementById("EnterWifi").innerHTML = ChosenSSID;
        Config.SSIDPage.Password = document.getElementById("Password").value;

        console.log(Config.SSIDPage.SSID);
        console.log(Config.SSIDPage.Password);

        GotoPage("TOCPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSysNamePage - Populate the directory page as needed
    //
    function PopulateSysNamePage() {
        NameInput.value = Config.SysNamePage.Name;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateWLanPage - Populate the directory page as needed
    //
    function PopulateWLanPage() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateELanPage - Populate the directory page as needed
    //
    function PopulateELanPage() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSharingPage - Populate the directory page as needed
    //
    function PopulateSharingPage() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateAboutPage - Populate the directory page as needed
    //
    function PopulateAboutPage() {
        var InfoLines = document.getElementById("InfoLines");

        Config.AboutPage.forEach(function (InfoLine) { 
            var FmtLine = InfoLine.replace(": ",":<b> ") + "</b>";
           
            InfoLines.innerHTML += "<tr><td></td><td><pre class=\"AboutLines\" >" + FmtLine + "</pre></td></tr>";
            });
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateReviewPage - Populate the directory page as needed
    //
    function PopulateReviewPage() {}

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateEpilogPage - Populate the directory page as needed
    //
    function PopulateEpilogPage() {}
