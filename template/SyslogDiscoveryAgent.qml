import QtQuick 2.5

import ArcGIS.AppFramework 1.0

Item {
    property alias model: model
    property int defaultMaxAge: 10

    //--------------------------------------------------------------------------

    function start() {
        listener.start();
    }

    //--------------------------------------------------------------------------

    function stop() {
        listener.stop();
    }

    //--------------------------------------------------------------------------

    ListModel {
        id: model
        
        dynamicRoles: true
        
        function add(syslog) {
            var index = -1;
            for (var i = 0; i < count; i++) {
                if (get(i).address === syslog.address) {
                    index = i;
                    break;
                }
            }
            
            syslog.timestamp = new Date();

            if (index >= 0) {
                set(i, syslog);
            } else {
                append(syslog);
            }
        }

        function checkExpired() {
            var now = new Date();

            for (var i = count - 1; i >= 0; i--) {
                var syslog = get(i);

                if (!syslog.timestamp) {
                    continue;
                }

                var age = (now - syslog.timestamp) / 1000;
                if (age > syslog.maxAge) {
                    remove(i);
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------

    SSDPListener {
        id: listener

        onMessageReceived: {
            if (message.type !== "NOTIFY") {
                return;
            }

            if (!message.NT) {
                return;
            }

            var tokens = message.NT.match(/urn:([a-zA-Z0-9-\.]+):service:([a-zA-Z\.]+):([a-zA-Z0-9]*)/);
            if (!tokens) {
                return;
            }

            if (tokens[2] !== "syslog" ) {
                return;
            }

            message.address = address;
            message.port = message["SYSLOG-PORT.APPSTUDIO.ARCGIS.COM"];
            if (!message.port) {
                message.port = 514;
            }
            message.hostname = message["SYSLOG-HOSTNAME.APPSTUDIO.ARCGIS.COM"];
            if (!(message.hostname > "")) {
                message.hostname = message.address;
            }

            message.product = "Syslog Console";
            message.productVersion = ""

            if (message.SERVER > "") {
                var parts = message.SERVER.split(",");
                if (parts.length >= 3) {
                    var productParts = parts[2].split('/');
                    message.product = productParts[0];
                    if (productParts.length > 1) {
                        message.productVersion = productParts[1];
                    }
                }
            }

            message.productName = message.productVersion > ""
                    ? "%1 (%2)".arg(message.product).arg(message.productVersion)
                    : message.productName;

            message.outputLocation = "syslog://%1:%2".arg(message.address).arg(message.port);
            message.displayName = "%1 (%2:%3)".arg(message.hostname).arg(message.address).arg(message.port);


            var cacheControl = message["CACHE-CONTROL"];
            if (cacheControl) {
                tokens = cacheControl.match(/max-age=(\d+)\D*/);
                if (tokens) {
                    message.maxAge = Number(tokens[1]);
                }
            }

            if (!message.maxAge) {
                message.maxAge = defaultMaxAge;
            }

            model.add(message);
        }
    }

    //--------------------------------------------------------------------------

    Timer {
        interval: 5000
        repeat: true
        running: listener.active

        onTriggered: {
            model.checkExpired();
        }
    }

    //--------------------------------------------------------------------------
}
