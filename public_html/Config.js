//
// Config.js - Javascript for Config pages
//
////////////////////////////////////////////////////////////////////////////////

    var ConfigSystem = location.hostname;
    var ConfigAddr   = "ws:" + ConfigSystem + ":2021";

    var ConfigSocket;
    var ConfigData;

    var WindowWidth;
    var WindowHeight;

    var Config;
    var WifiList;

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
#                console.log(ConfigData);
                Config = ConfigData.State;
                var SysName = Config.SysNamePage.Name;
                console.log("Name: " + SysName);
                SysNameElements = document.getElementsByClassName("SysName");
                for (i = 0; i < SysNameElements.length; i++) {
                    SysNameElements[i].innerHTML = SysName;
                    };
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
            SysNameElements[i].style.display = "none";
            };

        if( PageName == "TOCPage"      ) { PopulateTOCPage(); }
        if( PageName == "ScanningPage" ) { ConfigCommand("GetNetworks"); }
        if( PageName == "WiFiPage"     ) { PopulateWiFiPage(); }
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
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateWifiPage - Populate the wifi selections
    //
    function PopulateWifiPage() {

//        console.log(WifiList);

        var WifiNames = document.getElementById("WifiNames");

        WifiNames.innerHTML = "<tr>"                     +
                              "<td>&nbsp;         </td>" +
                              "<td>Network        </td>" +
                              "<td>Signal quality </td>" + 
                              "<td>password?</td>" +
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
        var TableLine = "<tr>" + 
                        "<td><button class='SSIDButton' onclick=ChooseSSID('" + SSID + "') >Use</button></td>" +
                        "<td>" + SSID    + "</td>" +
                        "<td><center>" + Quality + "</center></td>" +
                        "<td><center>" + (PWNeeded ? "yes" : "no") + "</center></td>" +
                        "</tr>";

        return TableLine;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSysNamePage - Populate the directory page as needed
    //
    function PopulateSysNamePage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateWLanPage - Populate the directory page as needed
    //
    function PopulateWLanPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateELanPage - Populate the directory page as needed
    //
    function PopulateELanPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSharingPage - Populate the directory page as needed
    //
    function PopulateSharingPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateAboutPage - Populate the directory page as needed
    //
    function PopulateAboutPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateReviewPage - Populate the directory page as needed
    //
    function PopulateReviewPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateEpilogPage - Populate the directory page as needed
    //
    function PopulateEpilogPage() {
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateSSIDPage - Populate the SSID page with newly received SSID list
    //
    function PopulateSSIDPage(WifiList) {

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // ChooseSSID - Select and choose SSID to use
    //
    function ChooseSSID(ChosenSSID) {
        SSID = ChosenSSID;

        Wifi = undefined;
        WifiList.forEach(function (This) { 
            if( This.SSID == ChosenSSID )
                Wifi = This;
            });
        if( Wifi == undefined ) {
            alert("SSID " + ChosenSSID + " not in list.");
            GotoPage("ScanningPage");
            return;
            }

        if( Wifi.Encryption == "on" ) {
            GotoPage("PasswordPage");
            return;
            }

        GotoPage("ReviewPage");
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulatePasswordPage - Populate the password page with selected wifi name & take password
    //
    function PopulatePasswordPage() {

        document.getElementById("EnterWifi").innerHTML = SSID;
        }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //
    // PopulateReviewPage - Populate the review page with chosen settings
    //
    function PopulateReviewPage() {

        Password = document.getElementById("Password").value;

        document.getElementById("WifiSSID").innerHTML = SSID;

        if( Wifi.Encryption == "on" ) {
            document.getElementById("UsingNoPassword").style.display = "none";
            document.getElementById("UsingPassword"  ).style.display = "block";
            document.getElementById("WifiPassword"   ).style.display = "block";
            document.getElementById("WifiPassword"   ).innerHTML = Password;
            }
        else {
            document.getElementById("UsingNoPassword").style.display = "block";
            document.getElementById("UsingPassword"  ).style.display = "none";
            document.getElementById("WifiPassword"   ).style.display = "none";
            }
        }
    }
