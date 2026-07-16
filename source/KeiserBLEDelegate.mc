using Toybox.System as Sys;
using Toybox.BluetoothLowEnergy as Ble;
using Toybox.Lang as Lang;

class KeiserBLEDelegate extends Ble.BleDelegate {
    const KEISER_MANUFACTURER_ID = 0x0102;
    const BIKE_ID_OFFSET = 3;
    const DATA_TYPE_OFFSET = 2;
    const MINIMUM_PACKET_LENGTH = 17;

    var cadence = 0;
    var heartRate = 0;
    var power = 0;
    var calorie = 0;
    var duration = 0;
    var distance = 0;
    var gear = 0;

    var bikeID = 0;

    function initialize() {
        BleDelegate.initialize();
        // System.println("init ble delegate");
    }

    function setBikeID(bid) {
        bikeID = bid;
    }

    function onScanResults(scanResults) {
        while (true) {
            var res = scanResults.next() as Ble.ScanResult;
            if (res != null) {
                if (res.getDeviceName() == null || 
                    !res.getDeviceName().equals("M3")) {
                    continue;
                }

                logM3Advertisement(res);

                var msd = res.getManufacturerSpecificData(KEISER_MANUFACTURER_ID);
                if (msd == null) {
                    continue;
                }

                if (msd.size() <= BIKE_ID_OFFSET) {
                    continue;
                }

                if (msd[BIKE_ID_OFFSET].equals(bikeID)) {
                    if (msd.size() < MINIMUM_PACKET_LENGTH) {
                        continue;
                    }

                    // System.println("Parsing data");
                    parseKeiserMSD(msd);
                }
            }
            else {
                break;
            }
        }
    }

    function bytesToFloat(a, b) {
        return (a | (b << 8)).toFloat() / 10.0;
    }

    function bytesToInt(a, b) {
        return a | (b << 8);
    }

    function parseKeiserMSD(msd as Toybox.Lang.ByteArray) {
        var data_type = msd[2];
        if (data_type == 0 || 
            (data_type >= 128 && data_type <= 227)) {
            cadence = msd[4];
            heartRate = bytesToFloat(msd[6], msd[7]);
            power = bytesToInt(msd[8], msd[9]);
            calorie = bytesToInt(msd[10], msd[11]);
            duration = msd[12] + msd[13] * 60; // TODO: prevent wrap around at 99:99
            distance = bytesToFloat(msd[14], msd[15]);
            gear = msd[16];
        }
    }

    (:debug)
    function logM3Advertisement(res as Ble.ScanResult) as Void {
        var rssi = res.getRssi();
        var entries = res.getManufacturerSpecificDataIterator();
        var foundManufacturerData = false;

        while (true) {
            var nextEntry = entries.next();
            if (nextEntry == null) {
                break;
            }

            var entry = nextEntry as Lang.Dictionary;
            foundManufacturerData = true;

            var manufacturerId = entry[:companyId] as Lang.Number;
            var payload = entry[:data] as Lang.ByteArray;
            var bikeId = "NA";
            var status = "parseable";

            if (payload.size() <= BIKE_ID_OFFSET) {
                status = "bike_id_unavailable";
            } else {
                bikeId = payload[BIKE_ID_OFFSET].format("%d");

                if (payload.size() < MINIMUM_PACKET_LENGTH) {
                    status = "payload_too_short";
                } else {
                    var dataType = payload[DATA_TYPE_OFFSET];
                    if (dataType != 0 &&
                        (dataType < 128 || dataType > 227)) {
                        status = "unsupported_data_type";
                    }
                }
            }

            Sys.println(
                "M3_ADV manufacturer=0x" + manufacturerId.format("%04X") +
                " rssi=" + rssi +
                " bikeId=" + bikeId +
                " length=" + payload.size() +
                " status=" + status +
                " payload=" + payloadToHex(payload)
            );
        }

        if (!foundManufacturerData) {
            Sys.println(
                "M3_ADV manufacturer=NA" +
                " rssi=" + rssi +
                " bikeId=NA length=0" +
                " status=manufacturer_data_missing payload="
            );
        }
    }

    (:release)
    function logM3Advertisement(res as Ble.ScanResult) as Void {
    }

    (:debug)
    function payloadToHex(payload as Lang.ByteArray) as Lang.String {
        var result = "";

        for (var i = 0; i < payload.size(); i += 1) {
            result += payload[i].format("%02X");
        }

        return result;
    }
}
